+++
date = "2015-03-08T21:49:57-07:00"
title = "Iron.io - Tech support done right"
aliases = [
	"/blog/iron.io-how-to-do-tech-support",
	"/iron.io-how-to-do-tech-support"
]
+++

[title=]: /
[category: Iron.io]: /
[date: 2015/03/8]: /
[tags: {go, golang, iron.io, mesos}]: /


# Iron.io - Tech support done right

Last week I woke up to find an email from [Iron.io](http://www.iron.io/) telling me that I was running low on my available IronMQ quota. Somehow I had made around 800,000 API requests in a week by running my [OwlCrawler](https://github.com/fmpwizard/owlcrawler) project.

### How?

The reason was easy to spot, every time we got a resource offer from the Mesos master, the [scheduler](https://github.com/fmpwizard/owlcrawler/blob/2e51dca2cf338f2584d3ffd250510f76bd01adbb/owlcrawler_scheduler.go#L107) was checking two message queues for new tasks. One queue is to see if we needed to fetch html from a new page, and the other queue is to see if we needed to extract links and text from the html already fetched. This resulted in making around 160,000 API requests per day, just to see if there was any work to do.

![160k API requests](/images/iron-160k-api-requests.png)

###### (Initially there was a lower number of daily requests because I was doing testing and didn't leave the cluster running all day)

### Tech support.

I had a few ideas on how to solve this problem, but I wasn't happy with any of them, so I went ahead and emailed Iron.io's support to see if they would increase the limit of API calls my project could make. I could have simply signed up for the next plan, but considering this is an open source project, I thought it would be worth asking.

To my surprise, about 2 hours after I sent them an email (3am EST on a Friday), I got a detailed reply form Peter Y. suggesting a few different ways I could modify my project to make fewer API calls. He went all the way to read the code on my project to make suggestions, which I did not expect at all.

So many times the first line of tech support has no idea of anything, and is just a waste of time, but here not only did Peter know his stuff, but he also knew Go and was willing to read someone else's code to help.

### Reducing API calls.

The solution was pretty simple, I replaced the calls `queue.Get()`  for `queue.GetNWithTimeoutAndWait(1, 120, 40)`

Which triggers the long poll mechanism in the Go bindings and sits there for up to 40 seconds waiting for a new message, the call returns as soon as you get a new message, or after the 40 seconds.

After implementing this change, OwlCrawler makes about 25,000 API calls a day, which keeps it under the 1M daily limit on the free tier plan.

### Closing notes.

I started using Iron.io because their API was dead simple, and now I continue to use them because their tech support is top notch!

>Thank you for reading and don't hesitate to leave a comment/question.
>
>[@fmpwizard](https://twitter.com/fmpwizard)
>
>Diego
