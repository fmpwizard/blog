+++
date = "2015-02-20T21:49:57-07:00"
title = "Web crawler using Mesos and Go"
aliases = [
	"/blog/web-crawler-using-mesos-and-golang"
]
+++

[title=Web crawler using Mesos and Go]: /
[category: Go]: /
[date: 2015/02/20]: /
[tags: {go, golang, mesos, mesos-go, distributed, encoding.gob, encoding}]: /




# Distributed web crawler using Mesos and Go

[OwlCrawler](https://github.com/fmpwizard/owlcrawler) is a simple yet distributed web crawler I'm working onto learn [Mesos](http://mesos.apache.org/). I'm using the [mesos go](https://github.com/mesos/mesos-go) binding to write the logic and use [Iron MQ](http://www.iron.io/mq) to trigger tasks that fetch pages. At this point I'm storing the url and html in [etcd](https://github.com/coreos/etcd) but I have plans to move that to CouchDB in the near future.

## A bit of history.

Writing a web crawler is something I have been thinking about for several years now, when I first started using Scala many years ago, I thought actors would be a great tool to have workers go out and do the crawling. At that time [Akka](http://akka.io/) didn't have remote actors in place and even after they added them, it felt to me that setting up the different members of the cluster wasn't as simple as I wanted it to be, note that in my case, this is just a personal project, so I was looking for something simple and fun to use.

About a year and a half ago I started using [Go ](http://golang.org/) and there goroutines looked like the way to go, but I still had to setup the different members of a cluster, and coordinate how they should all work together.

Finally, last week I was looking at mesos once again (I had been meaning to try it out for a while) and that's when I decided to take their [sample framework and executor](https://github.com/mesos/mesos-go/tree/master/examples) and see what it would look like to write a web crawler on top of it.

## Mesos' rainbow
Getting mesos installed was pretty simple following their [getting started page](http://mesos.apache.org/gettingstarted/). After that, it was time to write the crawler's logic using mesos-go. For this I started with the framework part. I only had to modify the `ResourceOffers` method which is called by mesos when there are resources available on the cluster.

### Framework's logic

The logic I have so far goes like this: I check if the cpu and memory resources mesos is giving me are enough for the task, if they are, I check if ironmq has any messages for this app, if there is a message, it would be the next url I'm supposed to fetch.

Once I read the url, I check if that url was already fetched, if etcd doesn't have it, I encode some data using [go's encoding.gob](http://golang.org/pkg/encoding/gob/) and send the task to the mesos cluster.

You can see the complete framework code [here](https://github.com/fmpwizard/owlcrawler/blob/master/owlcrawler_framework.go). Note that while mesos calls it framework, it really doesn't have to be a lot of code.

I love how I don't need to tell the crawler which worker is going to get the next task, I just send it out there and mesos deals with it.

### Executor's logic

On the executor's side, the main method I modified was `LaunchTask`. Here I decode the data I got from the framework, so far this is the data I pass from the framework to the executor:

```
type OwlCrawlMsg struct {
    URL       string //URL to fetch
    ID        string //IronMQ message id, so I can delete it once I'm done
    QueueName string //IronMQ queue name
    EtcdHost  string //Etcd host to look things up from
}
```

This is another place where the logic is simple, I use Go's http client to fetch data for the url, then I store the html in etcd and also parse the page looking for links. If the url looks like something I want to fetch, I then send it as a message to IronMQ and finally send an status update to the mesos master telling it we are done.

And the loop starts again, the framework gets a resource offer, and then it queries the queue, it will find this new url and it just keeps going until it got all the links from the site.

## Code.

You can find this project's source code on [github](https://github.com/fmpwizard/owlcrawler) I'll be updating it to clean it up and fix any issues I find, it's in early stages, but I didn't want to wait any longer before putting it out there.

## Conclusion.

Mesos does exactly what I wanted, I setup a cluster of servers and then write my app without worrying about which server is going to run which task, or if I have enough resources for all of them. And using a message queue feels like the right choice here to communicate the source of the tasks.

And let's not forget that using Go here made a huge difference, as I was learning mesos, I had to do a lot of trial an error to get things working, and the fast compiler made this project a lot of fun to work on.

## Random notes:

### encoding/gob

Using encoding/gob to pass binary data from one process to another is just dead simple:

```
var msgAndID bytes.Buffer
enc := gob.NewEncoder(&msgAndID)
err = enc.Encode(OwlCrawlMsg{
	URL:       msg.Body,
	ID:        msg.Id,
	QueueName: queueName,
	EtcdHost:  *etcHostAndport,
})
if err != nil {
	log.Fatal("encode error:", err)
}
```

And decoding it on another process:

```
var queueMessage OwlCrawlMsg
dec := gob.NewDecoder(payload)
err = dec.Decode(&queueMessage)
if err != nil {
	fmt.Println("decode error:", err)
}
```
In this case I'm using the same name for the struct `OwlCrawlMsg` but they are actually two different structs defined on two different files, as long as they have the same fields inside, they work.


### IronMQ

Their api is almost too easy to use, from managing credentials by adding a `.iron.json` file in your `$HOME`, to the few method calls you have to do.

>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
