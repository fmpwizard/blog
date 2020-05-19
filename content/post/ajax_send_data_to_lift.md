+++
date = "2012-12-07T21:49:57-07:00"
title = "What is T => JsCmd or how you send data from the browser to a Lift server"
aliases = [
	"/blog/ajax_send_data_to_lift",
	"/ajax_send_data_to_lift"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2012/12/7]: /
[tags: {lift, scala, JsCmd, ajax}]: /

# How does T => JsCmd send data to Lift?

I remember my first few interactions with Lift's ajax support, which were also my first few interactions with Scala. It was pretty hard to get my head around some of the method signatures I would find all across Lift's source code.

The one that took me a while to understand was `T => JsCmd` . What was hard to understand was, how that type would mean that I can pass information from the browser to the LIft server, and get back a response in the form of JavaScript.

I knew it worked because I would copy/paste code samples taken from the mailing list and they worked just as advertised.

## Scala bits to clear your mind.

If you are new to Scala, the T there represents **any** type, it could be an `Int`, `String`, `(String, String)`, etc. Let's take, as an example, the type signature of `SHtml.ajaxRadio`

`def ajaxRadio[T](opts: Seq[T], deflt: Box[T], ajaxFunc: T => JsCmd, attrs: ElemAttr*): ChoiceHolder[T] = ...`

Those are a lot of `T` types, just for now, let's assume you are working with **Strings**, you could rewrite it in your head as:

`def ajaxRadio(opts: Seq[String], deflt: Box[String], ajaxFunc: String => JsCmd, attrs: ElemAttr*): ChoiceHolder[String] = ...`

## The moment of the realization.

When the time comes to use ajaxRadio, you could define `ajaxFunc` as

```
def itemSelected(s: String): JsCmds = {
  //Here you see that the println will be executed on the server
  //You could send a message to a comet actor with the selected value, you could
  //assign it to a variable, you could do just about anything.
  println(s)
  //This could be any JavaScript you want,
  //maybe you want to update the UI, close a modal dialog, etc
  JsCmds.Noop
}

```


and then you would write:

```
ajaxRadio(Seq("one", "dos", "tres"), Full("dos"), itemSelected _  )
```

so, once you select an item from the radio options, the function `itemSelected` is called, and you get the selected value as a parameter to `itemSelected`. Because this is an ajax* function, there is no page refresh going on.

Here, I am simply returning a `JsCmd.Noop`, which does nothing on the UI, but you could return any other `JsCmd` in there.


I hope this was helpful, and I'm planning on writing a follow up post with a full example on how to use ajaxRadio, as well as radioElem.

>Thank you for reading and don't hesitate to leave a comment/question.
>
>[@fmpwizard](https://twitter.com/fmpwizard)
>
>Diego
