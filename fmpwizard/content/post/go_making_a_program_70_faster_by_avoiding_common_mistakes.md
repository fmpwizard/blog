+++
date = "2016-02-29T21:49:57-07:00"
title = "Go - Making a program 70% faster, by avoiding common mistakes"
aliases = [
	"/blog/go_making_a_program_70_faster_by_avoiding_common_mistakes"
]
tags = ["go", "golang", "mongodb", "benchmark", "performance"]
+++


# Go - Making a program 70% faster, by avoiding common mistakes.

I often read articles where a developer would say they made this or that change to their code and a benchmark shows their function going from taking ~300ns to ~170ns and they were really happy about it. I think it's great that there are devs out there really squeezing every CPU cycle they can. But this isn't one of those articles.

At [work](https://www.ascendantcompliancemanager.com/) we wrote a tool that takes a large number of trading data, does all kinds of calculations, comparisons, tagging and then saves the results in MongoDB. We originally wrote the tool in Scala, but it was using too much memory and wasn't fast enough for us, so about two years ago we migrated the code to Go.

**Blotterizer** (because it calculates data for Trade Blotters :) ), has gone through several major improvements. Some of them were related to performance, like going from **8 hours** to run the complete process down to about **20 minutes**. Others were operational, for example, I used to have to manually run the tool locally, then upload a gzip file to the server and then load that data to the database, now all it takes is one click on the main App and then sit back and wait for a notification telling you the data is ready.

##The problem.
Today I'm writing about a mistake I made a while ago, which only showed how bad it was for some of our largest customers. Customer `X` provided us with several years worth of data, and `Blotterizer` took about 131 minutes to process all that data, most customer's data are is ready in less than 10 minutes, so this was way too long.

###The wrong way to fix it
First, I did what every dev out there knows not to do (including myself), I just started making changes to the code thinking I knew better. I knew we were getting a huge amount of docs from MongoDB, so the code went from:

```
itrades := []trading.AggregationSetsTradeDates{}
iter := collection.Pipe([]bson.M{{
...
}}).AllowDiskUse().Iter()

err := iter.All(&itrades)
```


to

calling `.Next()` on the iterator. The thought was,  *I'm sure fetching all those docs at once is too slow.*

That turned out not to make much of a difference, it was actually worse, because I had to make several calculations with each document 4 times, based on different parameters.

When I fetched them all at once, I could run 4 goroutines to spread the load, now that I was getting one doc at the time, sending each of them to a goroutine ended up causing more overhead. So this was a dead end.

I tried a few other embarrassing ideas which should remain untold for the time being, and then I decided it was time to do this right.

### The right way to fix it.

One of the great things about **Go** is that it comes with very useful tools around the language, Writing benchmarks was the key here. So I went ahead, reverted my changes and wrote a benchmark to see how long processing only 3 transactions took.

### The horror

The initial results looked terrible:
```
go test -bench=BenchmarkProcessTrades -run=none -benchmem
PASS
BenchmarkProcessTrades-4	    1000	   1734904 ns/op	   50353 B/op	    1613 allocs/op
ok  	github.com/ascendantcompliance/blotterizer	1.949s
```

That is, it took `1.7 milliseconds` to process 3 transactions and made `1613 allocations`

No wonder this thing was slow! but then again, I knew this was slow, now came the hard part, what do I do to make it faster?

I added a few timers in between the process (the benchmark wasn't of the least unit I could write, it involved several steps), but this showed that the biggest issue was when saving the data to the database.

I looked on the `mgo` mailing list to see if anyone else had run into performance issues, but nothing showed a problem with `mgo`. At this point I was about to give up, and was going to email the mailing list to see if they had any clues and that's when I saw the huge issue I had:

```
err := collection.UpdateId(processingThisOne.ID, bson.M{
			"$set": bson.M{
				"std_" + strconv.Itoa(daySpread):              std,
				"mean_" + strconv.Itoa(daySpread):             mea,
				"impact_" + strconv.Itoa(daySpread):           impact(processingThisOne.ID, mea, collection),
				"impact_" + strconv.Itoa(daySpread) + "_abs":  math.Abs(impact(processingThisOne.ID, mea, collection)),
				"impact_ratio_" + strconv.Itoa(daySpread):     impactRatio(impact(processingThisOne.ID, mea, collection), processingThisOne.GrossUSD),
				"zscore_" + strconv.Itoa(daySpread):           zScore,
				"zscore_" + strconv.Itoa(daySpread) + "_zone": zone,
			},
		})
...

func impact(tradeID bson.ObjectId, mean float64, collection *mgo.Collection) float64 {
	var trade trading.Trade
	err := collection.FindId(tradeID).One(&trade)
	if err != nil {
		log.Fatalf("Error getting document to calculate the Impact value, got: %s", err.Error())
	}
	ret := trade.GrossUSD - mean*trade.Quantity

	if strings.ToLower(trade.TransactionType) == "buy" || strings.ToLower(trade.TransactionType) == "cover" {
		return ret * -1
	}
	return ret
}
```

First, smaller issues, I was calling `strconv.Itoa(daySpread)` about 7 times, so I quickly moved that to a single variable

I then run the benchmark again and saw:

```
go test -bench=BenchmarkProcessTrades -run=diego -benchmem
PASS
BenchmarkProcessTrades-4	    1000	   1731701 ns/op	   50227 B/op	    1595 allocs/op
ok  	github.com/ascendantcompliance/blotterizer	1.926s
```

Still slow, but the number of allocations went down, so I thought I was on the right track.

Next I saw that I called `impact(processingThisOne.ID, mea, collection)` 3 times, so I applied the same solution, assign it once and reuse  the variable twice more.

Things we getting better:

```
go test -bench=BenchmarkProcessTrades -run=diego -benchmem
PASS
BenchmarkProcessTrades-4	    2000	    924453 ns/op	   28258 B/op	     774 allocs/op
ok  	github.com/ascendantcompliance/blotterizer	1.967s

```

Down to `774 allocations` and timing was about half!

###There was more!
I was still looking to make this even better, and that's when I saw

```
err := collection.FindId(tradeID).One(&trade)
```

I was calling MongoDB for each document, to get the quantity that was traded, the gross usd value and the transaction type, I sat there for a moment trying to see how I could avoid this, and then I remembered that the code that runs the aggregation `Pipe` had the quantity and gross usd, so I just needed to add the transaction type to the return value from the aggregation. And that was it, this let me changed the impact function to:

```

func impact(trade trading.TradeDatePrice, mean float64) float64 {
	ret := trade.GrossUSD - mean*trade.Quantity
	if strings.ToLower(trade.TransactionType) == "buy" || strings.ToLower(trade.TransactionType) == "cover" {
		return ret * -1
	}
	return ret
}
```

No more calling mongo for each document!

```
go test -bench=BenchmarkProcessTrades -run=diego -benchmem
PASS
BenchmarkProcessTrades-4	    3000	    528994 ns/op	   17186 B/op	     363 allocs/op
ok  	github.com/ascendantcompliance/blotterizer	1.662s
```

So now we are down to `0.5 milliseconds` and only `363 allocations`

This was a pretty big improvement, so I went and deployed this to our testing env. and rerun the process. What used to take `131 minutes` now takes `76 minutes` Which is a lot better.

Here I stopped, cleaned up the code and sent a pull request to have the changes reviewed. It was also time to take a well deserved break and spend some family time.

In the next couple of days I'll be looking at other parts of the tool to see what other mistakes are waiting to be corrected :)

##Note to self.

 - Go benchmarks are your friend
 - Try not to query your database if possible.

>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
