+++
date = "2020-05-18T08:49:57-07:00"
title = "About Me In Early 2020"
tags = ["work", "resume"]
draft = false
+++

Today I thought it would be good to write down some information about me and my career:

![You have to love cats](/images/wilson-1.jpg)


## Technical Side

I enjoy being proactive, for example, a few weeks ago we had to run data for a large client. It was a process that normally runs for a single day worth of data, but this time we had about 4 years of data. And it took about 7 hours to run.
I could have left it like that, but I knew that it was better to try and improve the performance before we start getting more requests with multi year datasets.
At the time all our developers were busy with other tickets so I figured this was an interesting challenge for me to address.

After some benchmarking, and looking at the code, I saw that we had added some complex logic on top of the original design, and this complexity was causing the degradation.
A couple of hours later, I had code that passed all our tests and processing time went from about 7 hours to just 40 minutes for this particular client's data.

I love it when simplifying code results in better performance.

Stories like this one is why I love Go, having benchmarks written with the standard library, fast compilation, using the built in metrics (expvars), etc. (It's ok that you don't like Go, we can both use the tools we prefer.)

I'm very proud of our current data pipeline, it works well for our current needs and it is designed in a way that it is easy to scale.

## Non Technical Side

I'm grateful that translating clients' requirements to devs is something that comes natural to me, and the other way around, when we have tech limitation, trade off and we need to communicate them back to clients.
I like interacting with clients just enough to understand their expectations and in the end, deliver something they will find useful.

I also really enjoy sharing all the knowledge I have. I take every single chance I have to teach what I know. Some engineers see this from fear, and think that a junior developer will then replace them, while that may be the case, it also
means that you can continue to grow and move up, either within your current organization, or by leaving and taking on a new role somewhere else.

And it is not just sharing the "good" parts, I also share the strugles, the silly bugs I still make, even after being in the industry for over 18 years.

## Code Review Time

Something I'm very strict about is code review, I find it very important for many reasons, besides catching bugs, I try to keep the codebase consistent and identify patterns across our applications.

These are some key points I keep in mind while doing code review:

* Be respectful, the developer put a lot of time and effort, acknowledge it and then give feedback.
* Make sure to explain why you ask for a particular change, especially if it seems subjective. 
* Keep code easy to read "6 months from today", add comments if needed. [^1]
* Imagine how it will be to have to debug this new code at 3 am, while production is down. [^2]
* Security. [^3]
* Be consistent so that new developers who join the team see the current patterns and can learn them quickly.
* Think ahead, to avoid some near term performance hits, but don't go too far.

The list goes on, but these are at the top of my list.

## What's Next?

I started at my current job almost 7 years ago, originally a part time contractor and later on I became the VP of Engineering. It has been a very rewarding experience, but it is coming to an end.

What's next? Something very exciting I hope. I'm now looking to lead a new group of developers to solve interesting challenges, and give them freedom to explore as we see fit.
And of course, I'd like a chance to do actual coding from time to time, so I stay up to date in the field.

So far I have worked in e-commerce, supply chain, database monitoring and hedge fund/post trading, but I'm open to other markets as well. As for languages, I really like [Go](https://blog.fmpwizard.com/tags/go/), so somehow that has to be there.

If I sound like a good fit for your organization, let's get in touch, diego@fmpwizard.com 

[^1]: A big theme for me is, keep code simple, as much as possible, if there is anything cryptic and we cannot make it more clear, add lots of code comments. We should not rely on the fact that we just had a 2 hour discussion about the design, we should be able to read this code 6 months from today and it should make sense.

[^2]: While we haven't had to be in this position in years, it is very similar to the previous point, a "sleepy" person should be able to understand what the code does.

[^3]: Do we have enough protection so that nobody can access the resource unless they are authorized? This could be, check if their company id and user id match the record, do they have the correct role? Framework wise, we already make sure things like csrf, xss are blocked, so I don't check if each field is being cleaned up. And then I check if the name of a function is descriptive enough, so that devs don't assume something is safe when it is not.


>Thank you for reading, and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
