+++
date = "2011-07-13T21:49:57-07:00"
title = "Back button and bookmark meet Lift comet - Revisited"
aliases = [
	"/blog/back-button-and-bookmark-meet-lift-comet-revi"
]
+++

[title=]: /
[category: Lift]: /
[date: 2011/07/13]: /
[tags: {actor, ajax, bbq, bookmark, comet, jquery, lift, liftweb, scala}]: /



# Back button and bookmark meet Lift comet - Revisited

On my quest for the ultimate bookmark and back button support for comet and ajax based lift applications, I decided to [ask on the Lift mailing list](https://groups.google.com/forum/#!topic/liftweb/wNQkUEpc7BA) how you could call Scala code from the browser. I really thought that it was going to be pretty hard to understand. But to my surprise, it was very easy.

There are at least three methods, **ajaxCall**, **ajaxInvoke** and **jsonCall** (all in the SHtml object). This time I'm using **jsonCall**.

## Why do I need this?

Because when you visit a link that has been bookmarked or shared by email, etc, I needed a way to execute some Scala code that would update the UI based on the values on the URL after the **# hashtag** (this is the fragment of the URL.)

I initially used **ajaxCall** to achieve this, but I had to send two parameter to Scala, one was the name of my comet actor, and the other was the value after the hashtag.

The signatures of ajaxCall are:

```
 /**
   * Build a JavaScript function that will perform an AJAX call based on a value calculated in JavaScript
   *
   * @param jsCalcValue the JavaScript that will be executed on the client to calculate the value to be sent to the server
   * @param func the function to call when the data is sent
   *
   * @return the function ID and JavaScript that makes the call
   */
  def ajaxCall(jsCalcValue: JsExp, func: String => JsCmd): (String, JsExp) = ajaxCall_*(jsCalcValue, SFuncHolder(func))

  /**
   * Build a JavaScript function that will perform an AJAX call based on a value calculated in JavaScript
   *
   * @param jsCalcValue the JavaScript that will be executed on the client to calculate the value to be sent to the server
   * @param jsContext the context instance that defines JavaScript to be executed on call success or failure
   * @param func the function to call when the data is sent
   *
   * @return the function ID and JavaScript that makes the call
   */
  def ajaxCall(jsCalcValue: JsExp, jsContext: JsContext, func: String => JsCmd): (String, JsExp) =
    ajaxCall_*(jsCalcValue, jsContext, SFuncHolder(func))
```

As you can see, there is only one **JsExp** variable you can pass, so I decided to concatenate the two values using a pipe ( | ), and then used the split() method to parse the input on my Scala code.

Needless to say this didn’t look nice at all. Luckily [David had posted before](https://groups.google.com/forum/#!topic/liftweb/Z-C3NivyWMI) that he prefers to use jsonCall. I had to read the signature of it a few times to see how it was any better than ajaxCall. And all of the sudden it clicked. the JsExp could be raw json data.

```
/**
   * Build a JavaScript function that will perform a JSON call based on a value calculated in JavaScript
   *
   * @param jsCalcValue the JavaScript to calculate the value to be sent to the server
   * @param func the function to call when the data is sent
   *
   * @return the function ID and JavaScript that makes the call
   */
  def jsonCall(jsCalcValue: JsExp, func: Any => JsCmd): (String, JsExp) =
    jsonCall_*(jsCalcValue, SFuncHolder(s => JSONParser.parse(s).map(func) openOr Noop))

  /**
   * Build a JavaScript function that will perform a JSON call based on a value calculated in JavaScript
   *
   * @param jsCalcValue the JavaScript to calculate the value to be sent to the server
   * @param jsContext the context instance that defines JavaScript to be executed on call success or failure
   * @param func the function to call when the data is sent
   *
   * @return the function ID and JavaScript that makes the call
   */
  def jsonCall(jsCalcValue: JsExp, jsContext: JsContext, func: Any => JsCmd): (String, JsExp) =
    jsonCall_*(jsCalcValue, jsContext, SFuncHolder(s => JSONParser.parse(s).map(func) openOr Noop))
```

So off I went and refactored my code to use it. To my surprise, I kept getting a compiler error, which I just had no idea how to fix :(.

The compiler was telling me:

```
[info] Compiling main sources...
[error] /home/wizard/Desktop/fmpwizard/public/lift-comet-history/src/main/scala/code/comet/MyLiftActor2.scala:76: overloaded method value apply with alternatives:
[error]   (command: net.liftweb.http.js.JsExp,params: net.liftweb.http.js.JsExp)net.liftweb.http.js.JsCmds.Run <and>
[error]   (command: String,params: net.liftweb.http.js.JsExp)net.liftweb.http.js.JsCmds.Run
[error]  cannot be applied to (net.liftweb.http.js.JE.JsRaw, (Any) => net.liftweb.http.js.JsCmd)
[error]     ".ajaxLinks [name]"   #> jsonCall(
[error]                              ^
[error] one error found
[info] == compile ==
[error] Error running compile: Compilation failed
```

The solution? Add SHtml. before jsoncall

Using jsonCall works almost perfectly, the Scala method that is called by jsonCall gets a parameter of type Any, but underneath it is a Map[String, Any]. This is my current work around:

```
def updateCity(x: Any) : JsCmd = {
    val (cometName: String, cityId) = Full(x).asA[Map[String, Any]] match {
      case Full(m) => (
        m.get("cometName").getOrElse("No comet Name"),
        m.get("cityId").getOrElse("1")
      )
      case _ => ("No Comet Name", "1")
    }
...
}
```


Not the best thing but it gets the job done, if you have any better idea, please let me know. David did asked me to enter a [ticket](https://github.com/lift/framework/issues/1070) to add a jsonCall version that would return a JValue, which you can then work with using lift-json.

## What happened to the rest api?

If you read my [previous blog post](/blog/back-button-and-bookmark-meet-lift-comet) you would have noticed that I used a REST API because I needed a way to execute Scala code triggered by the browser. jsonCall does this in a much cleaner way, so out with the REST code.

## How does it work?


![Image 1](/images/29085878-download.png)
![Image 2](/images/29086011-download1.png)

On my sample application I have 3 links, each of them is associated with a jsonCall method that passes the name of our comet actor and the value of our href. We use this value to do a look up by key to get the name of a city and state.

```

/**
 * This would normally be a call to your database
 */

object CitiesAndStates {
  val cityStateMap=
    Map(
      1 -> List("Asheville" -> "North Carolina"),
      2 -> List("San Francisco" -> "California"),
      3 -> List("Boston" -> "Massachusetts")
    )

}
```

We then send the result of the look up to our comet actor which will update our browser screen.

When we click on any of the links, we also update our url by adding a value after the hashtag. This is part of adding support for bookmarks and back button.

So the url goes from looking like:

http://127.0.0.1:8080/2/liftactorform2 to

http://127.0.0.1:8080/2/liftactorform2#bbq1=2

## Bookmark and back button magic.

When you load a page that has a value after the hashtag, there is JavaScript that gets executed. This JavaScript extracts our comet name as well as the fragment from the url and executes the jsonCall that correspond to the correct link you would click to get the same city and state. This is kind of to save some effor, but is something that I may change in future versions, because I think it is pretty fragile.

From this point on, it is the same as if you clicked on a link.

## Final thoughts.

On the live demo, there is a lot of JavaScript that was manually added to the default.html template. Take a look at that file if there are things that don’t quite make sense, and of course, leave a comment or email the mailing list if you have any questions.

I have plans to improve on this example, but I think that this is a good proof of concept that you do not have to say goodbye to sharing links or other things we are used to on the web just because you have some ajax calls on your application.

## Code Sample?

Sure, you can find the source code is on [github](https://github.com/fmpwizard/lift-comet-history)

>Thank you for reading and don't hesitate to leave a comment/question.
>
>[@fmpwizard](https://twitter.com/fmpwizard)
>
>Diego
