+++
date = "2013-03-01T21:49:57-07:00"
title = "Different ways to use Comet Actors in Lift (Part I)"
aliases = [
	"/blog/comparing-comet-javascript-knockoutjs"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2013/3/1]: /
[tags: {lift, Scala, comet actors, comet, actors, knockoutjs, javascript}]: /

# Different ways to use Comet Actors in Lift (Part I).
####With some bits of knockout.js

Lift has many great fundamental features, focusing on security at its core is one of them, and another one is the ability to take a feature like its comet support and integrate it with JavaScript (and any JavaScript framework you wish to use).


##Background.

When I started using **Lift**, most of the code I wrote was in scala, but then I needed to add some dynamic magic to them, so I started adding JavaScript in different places. Sadly, I got into the habit of inlining a lot of JAvaScript in my scala code.

Up until about a year ago, I as really (ab)using `JE.JsRaw`, I mean, I just could not get enough of it, it was in my snippets, comet actors, everywhere! There were several points where I really wanted to use something different, it just didn't feel right, but for one reason or another I kept on going with that pattern.

Then, I started moving some of that JAvaScript to my html templates, that was better, because in scala code I would only call a javascript function and pass some info, and let the js on the html pages take care of it.

While better than before, now my html pages were a huge mess of html markup and javascript.

##Getting better.

Lucky for me, I got a chance to pick [Tim Nelson](https://twitter.com/eltimn)'s brain for a few months and I learned a lot about better JavaScript practices. The biggest thing was to really move all JavaScript into a proper `.js` file. And to help me start off with JavaScript on the right path, he recommended [JavaScript: The Good Parts](http://books.google.com/books?id=PXa2bby0oQ0C&source=gbs_slider_cls_metadata_1_mylibrary), while an old book, it was a great read. Oh, and he also introduced me to knockout.js, even though I showed a lot of resistance to it, I felt dirty letting JavaScript handle logic that in the past would have been encoded in my Lift code.

As if that wash't enough, during the past few months, I have also been learning a lot from [Antonio](https://twitter.com/lightfiend) and [Matt](https://twitter.com/farmdawgnation). Antonio is also a very open supporter of knockout, to the point that I could not resist any more and I agreed to try it out. And I'm very happy I did, now I see that it is actually great to pass some of the logic responsibility to a framework like ko.

But it wash't all roses to get into it, he has answered countless questions from very basic to some head scratching ones and every time I think I finally got it, I end up facing a new error or unexpected result, but even after all that, the results are pretty nice.

## Where am I now?

Now, I'm really enjoying the mix of Lift, specially comet actors, and knockout. Basically I use comet to trigger a JavaScript event on the browser and I pass some json data with the event.

On the browser I have ko listening for certain events, and then ko takes care of updating the UI as needed. This also accelerates development, because as I try different ways to render the information, or different ways to handle the json data, all I do is change a javascript file, reload the browser page, and I'm done, while in the past I had to do a quick scala recompile of the class I modified.

##Drawbacks.

There are still some issues that I hope to solve in the near future. Mainly, I don't like that I need to keep case classes that hold my data (which I then decomposed into json using Lift-json), in sync with the json structure that knockout expects.

What do I mean?

let's say I have a case class like this one:

```
case class ChatMessage(username: String, message: String, logo: String)

```

after calling using lift-json to decompose that case class into json I end up with

```
{" username" : "fmpwizard", "message": "Hi", "logo": "http://..."}
```

and on the JavaScript side, I bind the values of `username, message, logo` to the html template.

It has happened in the past that I would decide to remove a field, let's say the `logo`, or rename a field, and then I have to make sure I update the knockout code as well. So far I'm following the discipline path and haven't run into many issues, but it is something I hope to somehow solve.

## Where are the examples?

This post ended up getting too long, so this is just history/background info, for an example see [Part II](https://fmpwizard.telegr.am/blog/comparing-comet-javascript-knockoutjs-part-ii)
