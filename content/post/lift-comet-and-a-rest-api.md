+++
date = "2011-02-18T21:49:57-07:00"
title = "Scala + Lift + Comet + REST Support"
slug = "lift-comet-and-a-rest-api"
aliases = [
	"/blog/lift-comet-and-a-rest-api"
]
+++

[title=]: /
[category: Lift]: /
[date: 2011/02/18]: /
[tags: {actor, comet, jvm, lift, liftweb, rest, restfull, scala}]: /


# Scala + Lift + Comet + REST Support

![Comet](/images/21750593-comet_west.gif)

As part of my [day job](http://www.mysql.com/products/enterprise/monitor.html), I have been writing a dashboard to display test results from our different integration tests.
I chose to write it using Scala and [Lift](http://www.liftweb.nt) and it has been a great choice.

One of the many goals I have for this dashboard is to make the UI as responsive as possible. I also wanted to avoid things like full page reloads just to get new info.

## Enter the awesome comet support that comes with lift.

![Dashboard](/images/21763908-MEM_QA_Dashboard.png)

While you are looking at the results on a page, there is no need for hitting refresh, there is a comet actor that renders a table displaying test results. This Comet Actor will only update the cell that has new information coming from a REST API included on this dashboard.

## The details.

The first implementation was using a comet actor per page, you acomplish this by using a random name on each comet actor. I needed to use named actors to be able to have two or more browser tabs open at the same time, displaying information about different product versions we had tested.

This worked great until I had to somehow send a message from the REST API to the Comet Actor(s). There are a few ways to send a message to a Comet Actor, one is using the [sendCometActorMessage](http://scala-tools.org/mvnsites/liftweb-2.2/framework/scaladocs/net/liftweb/http/LiftSession.html)("MyActor", Full(id), QueryParams(params)) method. But this requires you to be on the same session. An the REST API was not going to be using the same session as the CometActor. I found out about this method thanks to [David Pollak](https://groups.google.com/forum/#!topic/liftweb/A9ql6e1Dx-A).

Another way to send a message to a comet actor is using a [ListenerManager](http://scala-tools.org/mvnsites/liftweb-2.2/framework/scaladocs/index.html), basically all your comet actors register themselves with a ListenerManager (an object), and the REST API can send the update message to the ListenerManager, and then the message gets propagated to all the comet actors that are registered with this ListenerManager.
This option was pretty promising, it worked as described, I was able to have multiple tabs open, all showing different information, I was able to update each page only if the REST API got new information. But what I wasn’t very happy about was that **all my comet actors** were getting every single message the REST API was sending. And then each actor had to decide if it needed to update the UI or just ignore the message.
I went back to the mailing list asking for help, and as always, I got a great answer. The basic idea is to create one Listener Manager per URL parameter, and have the comet actors only register with the Manager that was getting updates for their URL parameters.
It took me some time to really understand the whole idea, I felt I was almost there, but I just could not get it to work. I kept thinking that I needed to use the listenerManager trait, but that was not working because at the time the comet actor was created, which is when you register them, it did not have any information about which version it was going to display information about.

I then went ahead and bought [Actors in Scala](http://www.artima.com/shop/actors_in_scala) hoping that it would help, and even though the book is not finished, it helped a lot. It had an example that was just the missing piece, well, I had to adjust it, but it helped me understand actors a lot better.

## The final implementation works like this:

![Architecture](/images/21750424-qa-dashboard.png)

On page load, when you visit a page like **http://127.0.0.1:8080/browser-details/2.4.0.1089** , a comet actor named **browser2.4.0.1089** gets created and on the page there is a snippet that sends this comet actor a message with the version number to display (**2.4.0.1089** in this case)

```
object PutCometOnPage {
  def render(xhtml: NodeSeq): NodeSeq = {
    val id= "browser" + versionString
    debug("Using CometActor with name: %s".format(id))
    for (sess <- S.session) sess.sendCometActorMessage(
      "BrowserDetails", Full(id), versionString
    )
    <lift:comet type="BrowserDetails" name={id}>{xhtml}</lift:comet>
  }
}
```

As soon as the comet actor gets this message, it calls the method listenerFor(version: String) on the MyListeners object.

This object has a map of String -> LiftActor, where the string is the version we are displaying on the UI, and the LiftActor is our **DispatcherActor** that only notifies comet actors that are showing results for a specific version .

The listenerFor method either creates a new dispatcher or it simply returns the LiftActor that corresponds to the version string.

```
object MyListeners extends Logger{
  private var listeners: Map[String, LiftActor] = Map()

  def listenerFor(str: String): LiftActor = synchronized {
    listeners.get(str) match {
      case Some(a) => info("Our map is %s".format(listeners)); a
      case None => {
        val ret = new DispatcherActor(str)
        listeners += str -> ret
        info("Our map is %s".format(listeners))
        ret
      }
    }
  }
}
```


Once the Comet Actor gets his dispatcher, it sends a registerCometActor message, and the dispatcher adds this comet actor to a List() of actors.

## Now the REST API side.

![REST Architecture](/images/21763731-dash.png)

When the REST API gets new json data for a particular test, it also calls the MyListeners.listenerFor(string) method to get a reference to the dispatcher that is expecting messages for this version number.

Once it gets the dispatcher, it goes and sends a CellToUpdate message, which in turn is propagated to all the comet actors that need this message.

```
/**
 * listenerFor(srvmgrVersion) returns a DispatcherActor that in turn
 * will send the CellToUpdate clas class to the comet actors that are
 * displaying info about the version we got json data for
 */
listenerFor(srvmgrVersion) match {
  case a: LiftActor => a ! CellToUpdate(
    testName, browser, srvmgrVersion, testResult, cellNotes
  )
  case _ => info("No actor to send an update")
}
debug("We will update column: %s, row: %s".format(testName, browser))
```

Finally, each comet actor that gets the CellToUpdate message, use the partialUpdate method to update the specific cell in our test results table on the browser.

```
  override def lowPriority: PartialFunction[Any,Unit] = {
    case CellToUpdate(index, rowName, version, cssClass, cellNotes) => {
      info("Comet Actor %s will do a partial update".format(this))
      info("[API]: Updating BrowserTestResults for version: %s".format(version))
      showingVersion = version

      /**
       * each td in the html grid has an id that is
       * [0-9] + browser name
       * I use this to uniquely identify which cell to update
       *
       */
      partialUpdate(
        Replace((index + rowName),
            <td id={(index + rowName)} class={cssClass}>{cellNotes}</td>
         )
      )
    }

...
  }
```

## Conclusion.

At this point I’m pretty happy with how it all works together. I’m sure there are things to improve, but I feel this is good enough for now. There is one detail that I may try to fix, which is that if there is no dispatcher for version Y, and the REST API calls MyListeners.listenerFor(“Y”), it will create a new dispatcher, which I do not want, I only want to create a dispatcher if there is a comet actor.

This has been a great exercise for me, I learned a lot about Lift comet support, and actors in general. I hope this helps others using Lift and if you have any comments, feel free to leave them here.

## Example Code?

I have put together a small application to show how this all works together, you can find it here:

[Github repo](https://github.com/fmpwizard/comet_rest_example)

Thanks and enjoy

 Diego
