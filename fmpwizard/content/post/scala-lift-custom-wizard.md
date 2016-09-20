+++
date = "2012-01-27T21:49:57-07:00"
title = "Scala / Lift - Custom Wizard"
aliases = [
	"/blog/scala-lift-custom-wizard"
]
+++


[title=]: /
[category: Lift]: /
[date: 2012/01/27]: /
[tags: {lift, scala, wizard, statefulsnippet, snippet, ajaxinvoke, ajax, javascript}]: /



#Scala / Lift - Custom Wizard

**Lift** has an amazing component to write applications like surveys, it is called wizard. And you can find more information on the [Simply Lift book][1].

One limitation it has, is that you cannot place the fields on any part of the page. They all appear one under the other. There is some work being done by **Peter Brant** which I really hope makes it into 2.5.

But for those who are a bit impatient or want full control about everything, I think this post will help you.

The sample application that I wrote shows you how you can use RequestVar's and values to pass information from one page to the next one. The core of this technique, is to assign the value from an input field to a val, and use S.redirectTo() to assign the val to a RequestVar. This step allows you to have the values from the previous page on the current page.

```
  def firstScreen ={
    "#name"       #> JsCmds.FocusOnLoad(SHtml.text(firstName, firstName = _)) &
    "type=submit" #> SHtml.submit(
      "Next",() => {
        S.redirectTo("/second",() => {
          NameVar.set(firstName)
          Whence.set(whence)
        })
      }
    )
  }
```

On the second page, you need to assign the value of the RequestVar to a val, so that it will be available on the S.redirectTo() call to the third page.

```
def secondScreen ={
    firstName= NameVar.is
    whence= S.uriAndQueryString openOr ("/")

    "#name" #> NameVar.is &
    "#name" #> NameVar.is &
    "#lastname *" #> JsCmds.FocusOnLoad(SHtml.text(lastName, lastName = _)) &
    "@back" #> SHtml.button("Back",() => S.redirectTo(Whence.is)) &
    "@next" #> SHtml.submit("Next", () => {
          S.redirectTo("/third",() => {
            NameVar.set(firstName)
            LastNameVar.set(lastName)
            Whence.set(whence)
          }
        )
      }
    )
  }
```

You then pretty much duplicate the same idea across all pages.

This example project includes a back button on each form and it also support the browser back button.

##Call Scala code from JavaScript.

This is a question that has been coming up on the mailing list more and more often. The usual answer is to use `jsonCall` or `ajaxCall` (and soon we will have ljsonCall, but there will be a full post just for that :) (update, the current jsonCall in  LIft >=2.5 is the improved version, we decided not to change the name.) )

There is one other method to use that may fit your needs. It is `ajaxInvoke()`. I had kind of a hard time trying to see how to use it best, but just the other day **Torsten Uhlmann** posted a great example on the Lift mailing list that made a huge difference for me.

You can see here how I use it to log a phrase on the server, and then I open a JavaScript alert box and after that I hide the **“Finish”** button. All by clicking on the Finish button.

```
def finalScreen ={
    "#name *"           #> NameVar.is &
    "#lastname *"       #> LastNameVar.is &
    "#age *"            #> AgeVar.is &
    "@finish [onclick]" #> SHtml.ajaxInvoke (() => {
      info("Data confirmed!")
      JsCmds.Alert("We saved your \nName: %s\nLast name: %s\nAge: %s".format(NameVar.is, LastNameVar.is,  AgeVar.is)) &
      JsCmds.JsHideId("finish")
    })
  }
```

##Drawbacks.

One thing I don't like about this technique is that if you have 10 form fields, you will need 10 RequestsVar’s and 10 val's. I'm planning on trying different ways to solve this.

One way I'm thinking is by using actors (I know, it sounds kind of odd, but I like coming up with odd solutions sometimes). The other option is to use the snapshot/ restore capabilities of RequestVars.

But in the meantime, you have something to work with.

##Code.

You can find the full source code on github.

##Feedback.

I'm happy to hear any feedback you may have, so feel free to email me on the Lift mailing list.

Enjoy

  --Diego




  [1]: http://simply.liftweb.net/index-4.7.html
