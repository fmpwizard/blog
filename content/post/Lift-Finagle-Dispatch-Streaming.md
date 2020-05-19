+++
date = "2012-07-01T21:49:57-07:00"
title = "Using Twitter Finagle and the Streaming api"
aliases = [
	"/blog/lift-finagle-dispatch-streaming",
	"/lift-finagle-dispatch-streaming"
]
+++
[tags: {lift, finagle, twitter, stream, comet}]: /

# Using Twitter Finagle, the Streaming api and Lift

Last weekend I had a chance to try Finagle's streaming client. It wasn't that easy to find an example of how to use it, so I thought it would help to post a working example.

## Finagle

The complete object here on [github](https://github.com/fmpwizard/lift_starter_2.4/blob/lift_twitter_dispatch_comet/src/main/scala/com/fmpwizard/lib/StreamReader.scala). I added as many comments as I could, so it should be easy to understand.

Basically you stablish a connection to the Twitter api doing:

    val client = clientFactory.apply()()
    val streamResponse = client(request)

``streamResponse`` is a ``Future[StreamResponse]`` and to operate on it in a non-blocking manner you invoke the `onSuccess` and `onFailure` methods.

Then I have:

    streamResponse.onSuccess {
      streamResponse => {
        streamResponse.messages foreach {
          buffer => {
          //do something with this message
          }
        }
      }
    }.onFailure{
      //Do something if we were not able to stablish a connection.
    }


That's pretty much it, you can see the complete example running on [cloudfoundry](http://lift-twitter-comet.cloudfoundry.com/) and the full source code is on [github](https://github.com/fmpwizard/lift_starter_2.4/tree/lift_twitter_dispatch_comet)


## Dispatch

Because I was only getting about 50 tweets per second, I thought that there could be a problem with how I was using finagle. So I added a dispatch version, you can find it [here](https://github.com/fmpwizard/lift_starter_2.4/blob/lift_twitter_dispatch_comet/src/main/scala/com/fmpwizard/lib/DispatchStreamReader.scala). But I got the same results. So I think that either my twitter account has a rate limit or the streaming api endpoint isn't supposed to give you that many tweets.

I did look into getting access to the firehouse feed, but it is restricted and you need special permission from Twitter.

## Lift
The Lift part of this project is using Comet to send each tweet to the browser. And because I needed to send the tweets to all comet actors on the jvm, but from outside any session, I'm using the new set of traits that Lift 2.5 comes with.

You can see the comet class [here](https://github.com/fmpwizard/lift_starter_2.4/blob/lift_twitter_dispatch_comet/src/main/scala/com/fmpwizard/comet/TweetWritter.scala).

All I did was extend the `NamedCometActorTrait` trait and add this snippet to my page:

    import net.liftweb.http.NamedCometActorSnippet

    object AddTweetComet extends NamedCometActorSnippet {
      def name = "tweet"
      def cometClass = "TweetWritter"
    }


To send messages to this comet actor you do:

    NamedCometListener.getDispatchersFor(Full("tweet")).foreach{
      actorM => actorM map { _ ! Tweet("message")}
    }

That's it, and if you have any questions or comments, feel free to ask on the [Lift mailing list](https://groups.google.com/forum/?fromgroups#!forum/liftweb) or here in the comments.
