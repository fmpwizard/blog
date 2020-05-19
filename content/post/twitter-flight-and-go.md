+++
date = "2013-12-21T21:49:57-07:00"
title = "Twitter Flight and Go"
aliases = [
	"/blog/twitter-flight-and-go",
	"/twitter-flight-and-go"
]
tags = ["javascript", "flight", "flightjs", "twitter", "go", "golang"]

+++


# Twitter Flight and Go

The last couple of weeks I have been using the [Go language](http://golang.org/) and [twitter flight](http://twitter.github.io/flight/) for a small project. I remember watching an [introductory video](http://www.youtube.com/watch?v=rKnDgT73v8s) on go right around the time I go into Scala. It look like an interesting language, I really liked their concurrent built in approach, among other features, but it was way too new as a language for me to get into.

Now, some 4 years later, they have already released their version 1.2, there are a number of companies using it in production and having good results with it and the tooling around it is pretty good.

I could go on describing all the features of the language and why I'm learning it, but I'll just say that so far my favorite feature is the fast compilation time. Coming from Scala, this is a huge difference. Just to give you an idea, the authors of the language have made such an emphasis on fast compilation that the way you use dependencies (other jars in jvm land), is by fetching the source code from the internet (github/bitbucket/your server/etc), compile those dependencies and then it compiles your app. Imagine doing that in Scala, it would take ages, And it has something like an incremental compile feature built in.

Now, those who know me may wonder what's going to happen with me and [Lift](http://www.liftweb.net), don't worry, I'll continue to be very active on the mailing list and community at large, and I already have some ideas that I may borrow from Go, specially, from this [rest framework written in Go](https://github.com/emicklei/go-restful).

While on the backend I have been playing around with Go, on the front end I have been using Twitter Flight. What I like the most about Flight is that it let's me use as much or as little as I want. Flight has the concept of `components`, which kind of reminds me of `Snippets` in Lift. I can place (attach is what they call it), a component on a page, and it will do it's job, without worrying about the rest of the page or what other components are present.

This brings me to something else I have been thinking for a while. A lot of people are going all the way to having as much logic as possible on the client side, citing that browsers these days are so much faster than in the old days that is just makes sense to do that. While I'm sure there are places to a heavy client side application, I think that a lot of applications should do both, present some data, useful data, that is rendered on the server, and then enhance it with client side code.

Let's take a simple example of a list of messages, hey, let's even visit an example that you can mess with right now, go to [http://fmpwizard.com:7070](http://fmpwizard.com:7070/index). This is an application written in Go, using the [go-restful](https://github.com/emicklei/go-restful) framework and it uses some Flight code to fetch the last 10 messages from the server and to submit new messages.

## The problem.

I'm sure you noticed that the main page loads pretty fast, from home it takes about **60ms**, but you don't see the messages right away, because the app has to download js code that will tell the application what to do (fetch some messages) and then it will make a new request to the server to get that data and render it. This whole thing takes about **1 second**. I don't know about you, but I think this is way too long to wait, as a user, to get my data.

## One solution.

What do I propose is a better way, head over to this page:  [http://fmpwizard.com:7070/messages](http://fmpwizard.com:7070/messages), this is the same html, same Javascript code, but I render the last 10 messages on the server, and send it as part of the initial html, this means that you only wait about **76ms** to start reading the messages you are looking for. And while you read them, the page continues to load the css and Javascript code that will provide you with more functionality. This is a huge difference in latency, and I think most users would benefit from it.

## But what about Ajax stuff?

So, most people tend to have lots of client side code because they want to do ajaxy stuff, and I agree that this improves the user experience, but you can also achieve that with the method I propose here.

When you visit [http://fmpwizard.com:7070/messages](http://fmpwizard.com:7070/messages), you will notice a link near the top of the list that says *Load more messages*, this is a flight component [load more](https://github.com/fmpwizard/go-examples/blob/gochat/app/js/component/ui/load_more.js) that I wrote, which is in charge of fetching the previous 10 items from the in memory array that the server holds. And the submit button has another [component](https://github.com/fmpwizard/go-examples/blob/gochat/app/js/component/ui/send_message.js) attached to it, that takes care of reading the message text and sending an XHR to the server with the new message, and adds this message to the current list.

These are just very small and simple examples, but I hope it demonstrates that you don't have to be all server side, nor client side. You can and should do both and I think that using Flight really helps with this idea.

I'll be exploring this idea further as time permits and I'll make sure to blog more about it, in the meantime, feel free to try out the [demo app](http://fmpwizard.com:7070/messages) and leave comments if you have them.

# Sample code.

There is a branch on this repository on [github](https://github.com/fmpwizard/go-examples/tree/gochat) that
has all the code you need to run this application. All the go code is in this one [chat.go](https://github.com/fmpwizard/go-examples/blob/gochat/chat.go) file, the one thing I don't like is that I ended up with a top level var to hold all the messages, so there are potential race conditions and what not writing/reading to it, but I didn't want to spend more time making this app better. I'll clean that up when I get a chance and probably blog about using go channels or go routines for that. **Update**: *I updated the code to use go channels instead of the top level var*

P.S. Thanks to [Tim Nelson](https://twitter.com/eltimn) for introducing me to Gruntjs, best thing ever to help you with javascript coding


Thanks you.

  Diego
