+++
date = "2013-03-08T21:49:57-07:00"
title = "Asynchronous snippets in Lift 2.5"
aliases = [
	"/blog/async-snippets-in-lift"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2013/3/8]: /
[tags: {lift, Scala, comet actors, comet, actors, LAFutures, Futures, async, asynchronous, snippet}]: /

# Asynchronous snippets in Lift 2.5

On my last [post](https://fmpwizard.telegr.am/blog/lift-snippets-and-lafutures) I wrote about using `LAFutures` on your snippets. And one of the things I said was that the syntax I was looking for was this:

```
val future1: LAFuture[String] = new LAFuture()

def render = {
  "#my-slow-loading-element *" #> future1
}
```

Well, over the last couple of nights I got to what I think is a great syntax:

```
class Sample extends Loggable {

  val f1: LAFuture[NodeSeq] = new LAFuture()
  val f2: LAFuture[NodeSeq] = new LAFuture()

  LAScheduler.execute( () => querySlowService1( f1 ) )
  LAScheduler.execute( () => querySlowService2( f2 ) )

  def render = {
    "#future1"                  #> f1 &
    ".diego"                    #> f2 &
    "data-name=another-future"  #> f2 &
    "#render-thread *"          #> Thread.currentThread().getName
  }
}

```

## Some details.

This post is about supporting `LAFuture[NodeSeq]`, which basically says that the end user is responsible for fulfilling the Future with the data they want to see on the browser, and express it as a `NodeSeq`. This could be as simple as saying `f1.satisfy(Text(Hello!))` or you could use more complex structures (like a complete html list)

You are also free to call your methods that will fulfill the `LAFutures` from anywhere you want. In this example, I call them as Lift materializes the snippet class, but you may as well call them after a form submit, or any other event.

One thing to remember is that the future in your css selector will replace the element you selected, so you cannot specify something like `"#future1 *"`, you have to use `"#future1"`. If you provide an element with an ID attribute, that's great and we use that internally to then lookup the item, once the Future has a value. If not, we go ahead and add an ID attribute to your element. This is what you see when we select `".diego"` and `"data-name=another-future"`

But other than that, your application just deals with `LAFutures` and Lift does the rest (well, this code is not part of Lift yet, but I'm hoping we can add it to the 3.0 branch.)



# Sample application and code.

You can find a fully runnable application that includes the code listed here on [github](https://github.com/fmpwizard/lift_starter_2.4/tree/la-futures-2) (on the la-futures-2 branch).

Thanks for reading

  Diego
