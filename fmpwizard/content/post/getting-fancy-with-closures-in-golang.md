+++
date = "2014-04-26T21:49:57-07:00"
title = "Getting fancy with closures in Go"
aliases = [
	"/blog/getting-fancy-with-closures-in-golang"
]
+++

[title=]: /
[category: go]: /
[date: 2014/04/26]: /
[tags: { go, golang, closures}]: /

#Getting fancy with closures in Go

While at the hackday at [Gophercon](http://www.gophercon.com/) I thought it would be a good idea to do some code refactoring of [Cortex](http://blog.fmpwizard.com/blog/go-cortex-talking-to-flowdock).

Over the past 24 hours I made many changes, but one that I specially liked was that I could pass a function as a parameter to another function. This is possible in Go because functions are first class (values? | elements?) And this made the code a lot cleaner.

##Before.

Initially I only had this one function to fetch the list of flows:

```
//fetchFlows fetches all the flows we have access to
func fetchFlows() {
	url := fmt.Sprintf("https://%s@api.flowdock.com/flows", config.FlowdockAccessToken)
	res, err := http.Get(url)
	if err != nil {
		log.Fatalf("Error getting list of flows: %v", err)
	} else if res.StatusCode != 200 {
		log.Fatalf("got status code %+v", res.StatusCode)
	}

	parseAvailableFlows(res.Body)
	res.Body.Close()
}
```

And this was to parse the json response:

```
func parseAvailableFlows(body io.ReadCloser) {
	flowsAsJon, err := ioutil.ReadAll(body)
	if err != nil {
		log.Fatalf("error reading body, got: %+v", err)
	}

	if ok := json.Unmarshal(flowsAsJon, &availableFlows); ok != nil {
		log.Fatalf("Error parsing flows data %+v", ok)
	}
}
```

But then I wanted to also fetch the list of current users, so I ended up with pretty much the same two functions duplicated, which wasn't that great.

##Refactor step 1:

First I moved the logic to fetch data from a url to a generic function:

```
func performGet(path string) {
	url := fmt.Sprintf("https://%s@api.flowdock.com/%s", config.FlowdockAccessToken, path)
	res, err := http.Get(url)
	if err != nil {
		log.Fatalf("Error getting %+v: %v", path, err)
	} else if res.StatusCode != 200 {
		log.Fatalf("got status code %+v", res.StatusCode)
	}
	dataAsJon, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatalf("error reading body, got: %+v", err)
	}
	//this is where I wanted to start parsing data
	res.Body.Close()
}
```

This was nice, but the question is, how do I run any specific function depending on what I'm parsing?

##Enter closures.

Turned out it was pretty easy.
I defined a new type `type parseCallback func([]byte)` this is the type signature of the parse functions I have

and then I had to change the `parseAvailableFlows` just a little bit:

```
func parseAvailableFlows() parseCallback {
	return func(payload []byte) {
		err := json.Unmarshal(payload, &availableFlows)
		if err != nil {
			log.Fatalf("Error parsing flows data %+v", err)
		}
	}
}
```

The way I like to think about it is that, we make the original function not take a parameter (you can if you need to, but here I didn't need it), then the signature of the function shows what you expect as input and output, here I expect a `[]byte` as input and I don't return anything.

Then enclose the body of your original function into a `return func(in type){ ... }` (anonymous function)

So the end result for the generic `performGet` was:

```
func performGet(path string, f parseCallback) { // <== note how we expect a valud f of type `parseCallback`
	url := fmt.Sprintf("https://%s@api.flowdock.com/%s", config.FlowdockAccessToken, path)
	res, err := http.Get(url)
	if err != nil {
		log.Fatalf("Error getting %+v: %v", path, err)
	} else if res.StatusCode != 200 {
		log.Fatalf("got status code %+v", res.StatusCode)
	}
	dataAsJson, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatalf("error reading body, got: %+v", err)
	}
	f(dataAsJson)// <== Here is where we call the callback function and
	//pass the json we just got
	//this also let's me close the body in this same function,
	//instead of passing it to whoever called this
	//function and make them close the `Body` value
	res.Body.Close()
}
```

##Final API

So now I simply have:

```
//fetchFlows fetches all the flows we have access to
func fetchFlows() {
	performGet("flows", parseAvailableFlows())
}

```
and fetching users is:
```
func fetchUsers() {
	performGet("users", parseUsers())
}
```

which I think looks pretty nice.

##Code.

If you would like to see this code in context, you can check the Cortex code at this [commit](https://github.com/fmpwizard/go-cortex/tree/c28a3f3b8cf8fa4f5ef180d550307d501ae9872d)

##Updated based on @elimisteve 's comments

>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
