+++
date = "2011-03-22T21:49:57-07:00"
title = "Conditional Drop Down - Ajax vs Wiring - Lift - Scala"
aliases = [
	"/blog/conditional-drop-down-ajax-vs-wiring-lift-sca"
]
+++

[title=]: /
[category: Lift]: /
[date: 2011/03/22]: /
[tags: {ajax, lift, liftweb, scala, wiring}]: /


#Conditional Drop Down - Ajax vs Wiring - Lift - Scala

##Update:

It turned out that I got a bit sidetracked as I was trying to get this example working, and I did not end up using Wiring. What I refer to as Wiring on this post is actually just Lift’s easy way of doing Ajax (so I compare Ajax with Ajax here :( ). But don’t worry, I still want to use Wiring, so I’ll find time this week to update the sample project and I’ll post again.

Thanks.

##The Post

I have been meaning to try Wiring on any of my Scala projects for some time now, but the right use case was not presenting itself. That was until last week, when I needed to have a few conditional drop down menus.

What I needed was an option to select a value from one menu, this menu had a few sub-menus, and once you made a selection on that second drop down, a group of 10 different drop down menus had to have their values filtered.

I remember seeing an example on the [lift site](http://demo.liftweb.com/ajax-form) that had two drop down menus, so I decided to modify that example and see how it would work for me.

##The moment of light.

As I was renaming some methods, changing some values on the select elements, I realized that wiring should be able to do the same, but in a simpler way. And I started coding around Wiring.

At first, I just took the example about creating an invoice [using Wiring](http://demo.liftweb.com/invoice_wiring) and tried to replace the Tax Rate field by a drop down menu. What I was hoping to achieve was that the example would work as it does on the live demo. And after correcting some mistakes I made along the way, I got it to work. This was pretty exciting, it meant I could use Wiring on this project!

I stopped there and I put together this [example project on github](https://github.com/fmpwizard/lift-conditional-drop-down-menus), which shows both, the [Ajax](https://github.com/fmpwizard/lift-conditional-drop-down-menus/blob/master/src/main/scala/code/snippet/AjaxForm.scala) and the [Wiring](https://github.com/fmpwizard/lift-conditional-drop-down-menus/blob/master/src/main/scala/code/snippet/Wiring.scala) way of doing the same thing. Now you can compare and decide which one you prefer.

##Comparing the code.

The Ajax partion looks like this:

```
  // bind the view to the dynamic HTML
  def show(xhtml: Group): NodeSeq = {
    val (name, js) = ajaxCall(JE.JsRaw("this.value"),
                              s => After(200, replace(s)))
    bind("select", xhtml,
         "state" -> select(AjaxForm.states.map(s => (s,s)),
                           Full(state), s => state = s, "onchange" -> js.toJsCmd) %
         (new PrefixedAttribute("lift", "gc", name, Null)),
         "city" -> cityChoice(state) % ("id" -> "city_select"),
         "submit" -> submit(?("Save"),
                            () =>
                            {S.notice("City: "+city+" State: "+state);
                             redirectTo("/")}))
  }
```

and the Wiring looks like this:

```
  def stateDropDown = SHtml.ajaxSelect(
                  Wiring.states.map(i => (i, i)),
                  Full(1.toString),
                  selected => {
                    //What to do when you select an entry
                    replace(selected)
                  }
                  )
```

It is very possible that I overlooked something on the wiring example, after all, this is the first time I get a chance to work with it, so feel free to tell me if I should do anything different.

Thanks

  Diego
