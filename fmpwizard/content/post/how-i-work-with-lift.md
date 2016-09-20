+++
date = "2012-11-29T21:49:57-07:00"
title = "How I work with Lift"
aliases = [
	"/blog/how-i-work-with-lift"
]
+++

[title=]: /
[category: Lift]: /
[date: 2012/11/29]: /
[tags: {lift, scala, intellij, IDEA, sbt}]: /

# How I work with Lift.

Something I enjoy very much is teaching, specially when Lift is involved. Mainly because I learn a lot by teaching others, and secondly because I have learned a lot thanks to those who spent the time to either teach me directly, or indirectly through blog posts, articles, etc.

Since I joined Elemica about 9 months ago, I have spent a good amount of time sharing what I know about Lift, Scala and web security with my team members. And today I'd like to talk about my work setup. I'll cover some simple tips about SBT and Intellij.

## IDE and Build tool.

My IDE of choice is [IntelliJ IDEA](http://www.jetbrains.com/idea/) with the [Scala plugin](http://confluence.jetbrains.net/display/SCA/Scala+Plugin+for+IntelliJ+IDEA). You will find that people use all kinds of IDEs, I tried a few, and I'm sticking with IDEA.

For building my Lift applications, I use [SBT 0.12](https://github.com/harrah/xsbt) (I just noticed that there is a newer version, 0.13).

And to have SBT and IntelliJ play nicely together, I use the [SBT IDEA](https://github.com/mpeltonen/sbt-idea/tree/sbt-0.12) plugin


## Documentation

I find reading the Lift source code very helpful, so I always keep a clone of the framework repository on my laptop, and I add this project to Intellij, so I can switch from my current project to the framework project, and have full access to navigation/search/etc.

A simple

    git clone git://github.com/lift/framework.git
    cd framework
    ./liftsh
    gen-idea  //assuming you added the IDEA-sbt plugin to your global file in ~/.sbt/plugins/build.sbt

You can now open the framework project in Intellij, and it will let you navigate the source, etc.

## Work flow.

I always have a few terminal tabs open (an average of 8), one tab runs **sbt**, and another is open so I can work with **git**.

On SBT, the 3 most used commands I use are:

```
1. ~compile
2. ;container:stop;container:start
3. ~test-only com.my.company.snippet.MyClassSpecs
```

When I'm starting with a new snippet, I want to make sure it compiles, and I'm not so interested in anything else. This is when I just have sbt running `~compile`. You can say that there is no need for this, as Intellij will mark your invalid code as red, but I started with IntelliJ when you used to get a lot of code marked as red, but it worked just fine under sbt. Now this isn't as common, but I still prefer `~compile`.

Once the basic code is in place and I *think* it does what I want it to, I go and start jetty with `;container:stop;container:start`, now, you may wonder why I have `container:stop` in there, well, most of the time the snippet doesn't do what I expected, so I have to restart jetty, by using `;container:stop;container:start` in the first place, I can simply press the arrow up on my keyboard followed by enter and after a second or two I'm back with the new code on the browser.

Some people like using **jRebel**, to avoid having to restart the server, you can give it a try and hopefully it will work for you.

I remember my first year or so with Lift, I would restart jetty so many times to get simple snippets to work, was frustrating, but over time, you get to a point where you don't need that many iterations to get the desired result, so by now I don't see the need for jRebel in my setup.

###Browser

While I use Google Chrome for all my web browsing, I use Firefox (with the Firebug plugin) for testing my Lift applications.

Why? Because I find it quicker to press `command + tab` (mac) to go from the browser with the Lift application to Chrome with some google search/documentation/etc, to IntelliJ, to the terminal. So I have one, maybe two tabs in Firefox, and then about 5-10 tabs in Chrome.

The second reason is that I find Firebug a lot easier to use than the Chrome developer tools.

###Window size

This only applies to those who use a laptop to work, and no external monitor. The only application that is fully maximized is the terminal, and the tab that is active most of the time is the one running **sbt**, then the browsers/IntelliJ/etc are almost maximized, but the lower area is pulled up just enough so that I can see if sbt gave me a compiler error, or a test failure. This saves me the need to switch screens as I try different things on my snippet code.

## Final notes

There is a lot more that goes on in a normal day with Scala and Lift, but this is enough for this post, I hope you find some of it useful, but at the end of the day, you need to find what works best for you, this is just my opinionated setup.

Thanks

  Diego
