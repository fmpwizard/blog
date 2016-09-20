+++
date = "2015-03-08T21:49:57-07:00"
title = "Improving compile time in Go"
aliases = [
	"/blog/improving-golang-compile-time"
]
+++
[title=]: /
[category: Iron.io]: /
[date: 2015/03/8]: /
[tags: {go, golang, development, compiler, speed}]: /


#Improving compile time in Go

The Go compiler is really fast, and I got so used to it that when compiling [OwlCrawler](https://github.com/fmpwizard/owlcrawler) was taking about 8 seconds I started to worry (granted I generate 3 executable files).

###Tracking down the issue.

Some google-fu pointed me to adding the `-x` parameter to `go build` to see more details on what was going on.

I noticed that the compiler was taking most of the time building the apache zookeeper go bindings that mesos-go depends on. But I left it at that, and continued to work on the project. A few days later I decided to look into it again, but this time it was showing that most of the time was spent on one of the subpackages from my project, one that was making http calls to a CouchDB instance. The code in that file wasn't complex at all, so I didn't think it was related to what I wrote.

But I still didn't know how to solve the problem. I thought about combining the 3 executable files into one, which I may still do, but I wanted to find out more about the problem.

### A solution.

While tracking down why GoSublime would not pickup changes made to local [packages](https://github.com/DisposaBoy/GoSublime/issues/526) I wondered if running `go install` would also help me with the compile time issues.

It did!

If I start with a clean `$GOPATH/pkg` folder, just building the scheduler takes about 3.6 seconds. After running `go install` on the `mesos-go` project, it goes down to 1.3 seconds and after running `go install` on the `iron_go` project it goes to just under 1 second.


>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
