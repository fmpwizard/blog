+++
date = "2011-09-10T21:49:57-07:00"
title = "Lift comet actor per tab library"
aliases = [
	"/blog/lift-comet-actor-per-tab-library"
]
+++

[title=]: /
[category: Lift]: /
[date: 2011/09/10]: /
[tags: {actor, comet, jvm, lift, liftweb, scala}]: /


# Lift comet actor per tab library

I [wrote in the past](/blog/lift-comet-and-a-rest-api) about having different comet actors on the same window but on different tabs. This in a use case that I run into pretty often. And as I was getting tired of copying and pasting the same files over and over, I decided to write a little library to do just that, allow you to have different actors per browser tab without having to worry about dispatchers, etc.

## Sample application

Imagine you are running a site like ebay, your users are watching two different auctions on two different tabs. You could simply have one comet actor handling the load and choosing when to update each tab, or you could have one comet per auction. I prefer the second option.

In this example application, the page that displays the auction includes a comet actor whose name is the auction id. You can choose anything you want.

I use the name of the actor in two places. As the key for the Map of actor names -> dispatchers, and once there is an update for any of the auction items, I can lookup the dispatcher that needs to send a message to the comet actor(s) to update the browser tab.

I had explained how all these works in detail on a previous blog, but on that code there was a bug where dead actors, those that have not been on a page for a while, would stay on the map of names -> dispatchers. On this new version, I use the localShutdown method to unregister the comet actor right before it is shutdown by Lift.

## How can I use it?

In most cases you would only directly use three classes/traits. You would extend the trait InsertNamedComet. All you do here is override two lazy vals,

```
lazy val cometClass= "MyCometClass"
lazy val name= net.liftweb.util.Helpers.nextFuncName
```

If you do not override the lazy val name, each time a user loads your page, a new comet actor will be created, here you can set the name to be the value stored on a RequestVar, SessionVar, a S.param(), etc.

Then you include a tag on your html files to call this class, for example, if your class is class PutCometOnPage extends InsertNamedComet, on your html you would add:

```
<div class="lift:PutCometOnPage"></div>
```

The other trait you would extend is NamedCometActor. This trait already extends CometActor and all you have to do is override one of the message handlers (lowPriority, mediumPriority or highPriority) and define the render method.

The NamedCometActor trait implements localSetup and localShutdown to register and un-register the comet actor from the dispatcher.

To send a message to the correct comet actor you use the method CometListerner.listenerFor(Full(name)). This snippet shows you one way of sending a message to our comet actor:

```
CometListerner.listenerFor(Full(item)) match {
  case a: LiftActor => info(bid); a !  Message(item, (bid.toDouble + 1.00))
  case _            => info("No actor to send an update")
}
```

And that’s all. The library will take care of only sending updates to the actors that need the information.

## Code and Demo?

As always, you can access the source code of the library on github and the source of the demo application is also on [github](https://github.com/fmpwizard/lift_auction).

Enjoy

  Diego
