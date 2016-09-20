+++
date = "2013-12-21T21:49:57-07:00"
title = "Things I like about Go"
aliases = [
	"/blog/things-i-like-about-go"
]
+++

[title=]: /
[category: go]: /
[date: 2013/12/21]: /
[tags: { go, golang, scala}]: /


# Things I like about Go

I was going to start this post by pointing out all the bad things about Scala and how great Go is, but I decided against it, Go is such a great language, that you don't need to trash another language to point out Go's strengths. So here, I'm going to list how awesome a language Go is.

## Things I love about Go.

1. Fast compiler (I mean, super fast).
2. Built tool is provided with the language. `go build` and it will build your app
3. Dependencies are managed by looking at the import statements on your go files.
3. [Test](http://golang.org/pkg/testing/) framework provided by the language.
4. Code formatting/style included as part of the compilation process.
4. Great [documentation](http://golang.org/doc/)
5. Online [playground](http://play.golang.org/) to run any go code.
6. Built in concurrency options by giving you go channels, go routines and when you need them, locks.
7. The language itself is pretty small, which makes it easy to learn.
8. The standard library is huge, providing you with everything you need for most application, from json, xml, http client and server (real server, as in, the one that handles the download section from google.com and others). Crypto, compression and a lot [more](http://golang.org/pkg/).
9. Their html templates are context aware, meaning that you can't inject xss where plain text is supposed to be. (This is something very important for me as I'm mostly writing web applications these days).
10. Stable language. That's right, they are currently at Go 1.2 and they made it very clear that they want your go 1.0 code to continue to compile for all 1.x builds of Go.

And many more, but those are the things I deal with almost every day and it is great to have them all included as one package. There is no need to choose one build tool vs the other, or is this json library better than this other one.

>Thanks
  >>Diego
