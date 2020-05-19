+++
date = "2013-03-05T21:49:57-07:00"
title = "Using LAFutures with snippets in Lift 2.x"
aliases = [
	"/blog/lift-snippets-and-lafutures",
	"/lift-snippets-and-lafutures"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2013/3/5]: /
[tags: {lift, Scala, comet actors, comet, actors, LAFutures, Futures, javascript}]: /

# Using LAFutures with snippets in Lift 2.x

### Update

There is a better alternative now on [this post](https://fmpwizard.telegr.am/blog/async-snippets-in-lift)

==================================

For a while I wanted to do something like this on a Lift snippet:

```
val future1: LAFuture[String] = new LAFuture()

def render = {
  "#my-slow-loading-element *" #> future1
}
```

And the idea was that the page will load right away, and once the `LAFuture` had a valid value, it would be added to the page.

One way to do this kind of tasks, is to convert your snippet into a CometActor. But this isn't always what you want.

## The result.

![LAFutures and Lift snippets](/images/lafutures-1.jpg "Using Lift's LAFutures on snippets")


Turns out it wasn't that hard to get it working, while the syntax isn't like the examples above, I think it is still pretty clean.

A full snippet class looks like this:

```
class Sample extends Loggable {

  val f1: LAFuture[String] = new LAFuture()
  val f2: LAFuture[String] = new LAFuture()

  def render = {
    "#future1 *"        #> "Loading Future 1" &
    "#future2 *"        #> "Loading future 2" &
    "#render-thread *"  #> Thread.currentThread().getName &
    "#js"               #> AddFutureCallback

  }

  object AddFutureCallback extends Function1[NodeSeq, NodeSeq] {
    import lib.FutureHelper._
    import lib.MyAppLogic._

    def apply(in: NodeSeq): NodeSeq = {
      laFuture2Lazy(f1,  querySlowService1, giveMeFuture1, "future1" ) ++
      laFuture2Lazy(f2,  querySlowService2, giveMeFuture2, "future2" )
    }
  }
}

```

You can see that we have two `LAFutures` `f1` and `f2` and some initial data as a placeholder for `"#future1 *"` and `"#future2 *"`

## The inner workings.

The object `AddFutureCallback` replaces the element with the id **js** with two ajax calls (they are ajaxInvoke in this case).

Let's look at `laFuture2Lazy`

```
object FutureHelper extends Loggable{

  def laFuture2Lazy(
                     la:          LAFuture[String],
                     initLAF:     LAFuture[String] => Unit,
                     resultFunc:  (LAFuture[String], String) => JsCmd,
                     idSelector:  String
                     )
  : NodeSeq = {

    LAScheduler.execute( () => initLAF( la ) )
    Script(OnLoad( SHtml.ajaxInvoke( () => resultFunc(la, idSelector) ).exp.cmd ))
  }
}

```

`laFuture2Lazy` takes:

1. An LAFuture.
2. A function that triggers the service that will fulfill the LAFuture.
3. A function that takes the LAFuture we are working on, and the ID of an element where we will add the content of the LAFuture (once it has been satisfied), and returns a `JsCmd`.
4. The ID of the element that will display the result.


If we go back to the original example, we are using

`laFuture2Lazy(f1,  querySlowService1, giveMeFuture1, "future1" )`

This means that `f1` is the LAFuture we are working with, `querySlowService1` will be called at render time, and it will go and fetch some data to fulfill the LAFuture (imagine this being a service calling Amazon's S3 or doing some other slow data retrieval). `giveMeFuture1` knows how to convert the result of the Future into javascript that will update the page, and finally, `future1` is the id of a span element I have in `index.html`

## Demo


<p>
<iframe width="853" height="480" src="https://www.youtube.com/embed/dTNu4IODIKM?rel=0" frameborder="0" allowfullscreen></iframe>
</p>


## Your application logic.

Imagine this being a call to a 3rd party service, which is slow, so you want to use Futures:

```
  def querySlowService1(la: LAFuture[String]) {
    logger.info("querySlowService1 was called")
    Thread.sleep(9000L)
    la.satisfy(Thread.currentThread().getName)
  }
```
You then need a way to work with the Future, once it is satisfied (fulfilled)

```
  def giveMeFuture1(la: LAFuture[String], id: String ): JsCmd = {
    FutureIsHere( la, id )
  }

```

`FutureIsHere` is a case class that takes your LAFuture and the Id of the element where the result will go, and gives you the proper JavaScript to do the work.

```
case class FutureIsHere(la: LAFuture[String], idSelector: String ) extends JsCmd with Loggable {

  val updateCssClass = JE.JsRaw("""$("#%s").attr("class", "alert alert-success")""" format idSelector).cmd

  val  replace = if (la.isSatisfied) {
    updateElement()
  } else {
    tryAgain()
  }


  private def updateElement(): JsCmd = {
    val inner = JE.JsRaw("""$("#%1$s").replaceWith('<span id="%1$s">Data: %2$s"</span>')"""
      .format(idSelector, la.get)).cmd
    CmdPair(inner, updateCssClass)
  }

  private def tryAgain(): JsCmd = {
    val funcName: String = S.request.flatMap(_._params.toList.headOption.map(_._1)).openOr("")
    val retry = "setTimeout(function(){liftAjax.lift_ajaxHandler('%s=true', null, null, null)}, 3000)"
    JE.JsRaw(retry.format(funcName)).cmd
  }

  override val toJsCmd = replace.toJsCmd
}

```

Let's break it down a bit:

This line sets the css class of a span element using Bootstrap classes to make it pretty :)

    val updateCssClass = JE.JsRaw("""$("#%s").attr("class", "alert alert-success")""" format idSelector).cmd

Here we check if the future has been fulfilled, if so, we return js that will update the browser

```
  val  replace = if (la.isSatisfied) {
    updateElement()
  } else {
    tryAgain()
  }
```

Note how it is safe to call `.get` on the future, because we checked that it has been satisfied:

```
  private def updateElement(): JsCmd = {
    val inner = JE.JsRaw("""$("#%1$s").replaceWith('<span id="%1$s">Data: %2$s"</span>')"""
      .format(idSelector, la.get)).cmd
    CmdPair(inner, updateCssClass)
  }
```  

This could be considered a hack, or maybe it is the proper way, but basically we retry the ajax call in 3 seconds if this future isn't ready for us just yet:

```
  private def tryAgain(): JsCmd = {
    val funcName: String = S.request.flatMap(_._params.toList.headOption.map(_._1)).openOr("")
    val retry = "setTimeout(function(){liftAjax.lift_ajaxHandler('%s=true', null, null, null)}, 3000)"
    JE.JsRaw(retry.format(funcName)).cmd
  }
```

# Sample application and code.

You can find a fully runnable application that includes the code listed here on [github](https://github.com/fmpwizard/lift_starter_2.4/tree/lafutures) (on the lafutures branch).

Thanks for reading

  Diego
