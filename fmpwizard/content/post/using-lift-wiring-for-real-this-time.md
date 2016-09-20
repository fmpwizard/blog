+++
date = "2011-03-29T21:49:57-07:00"
title = "Using lift wiring - for real this time"
aliases = [
	"/blog/using-lift-wiring-for-real-this-time"
]
+++

[title=Using lift wiring - for real this time]: /
[category: Lift]: /
[date: 2011/03/29]: /
[tags: {wiring, lift, liftweb, scala}]: /


#Using lift wiring - for real this time

On my last [article](/blog/conditional-drop-down-ajax-vs-wiring-lift-sca) I meant to compare two ways of doing conditional drop down menus using Lift. I wanted to compare using simple Ajax and wiring. But I ended up doing both cases using Ajax :( (This is because Lift makes is so easy :P).

But I still wanted to use Wiring, and be able to write about it. A few nights ago, I was able to update the [sample application](https://github.com/fmpwizard/lift-conditional-drop-down-menus) with a third example, this one really uses wiring!

What I'm showing here is how wiring can be used to filter two drop down menus based on the selection made on a third menu.

#What does it do?

![Wiring Sample](/images/23821662-App_Wiring.png)


You select a state from one drop down menu, and the list of cities is filtered only showing the cities that belong to the state you just selected. Another drop down menu is also updated, which shows you a number, this number only belongs to the selected state.

I know this last field could have been a text field, but I wanted to show drop down menus, because there are several wiring examples out there showing how to use text fields already :)

#How does it work?

I define the menu with the list of states to be a value cell, this is our starting point.

```
private object Info {
  val selectedState= ValueCell(state)
  val cities= selectedState.lift(_ + "")
  val ids= selectedState.lift(_ + "")
}
```

Then we define the other two menus to depend on changes to the state menu. You do this by using the lift method. I'm sure there is a better way to express the relationship than using val cities= selectedState.lift(_ + ""), if I find a better way, I'll update this post.

Then, you define the method that will render the drop down menus on the browser. Here you can select some effects that can take place before the lists are updated.

```
def stateDropDown = SHtml.ajaxSelect(
                  CitiesAndStates.states.map(i => (i, i)),
                  Full(1.toString),
                  selected => {
                    //What to do when you select an entry
                    Info.selectedState.set(selected)
                    state= selected
                    Noop
                  }
                  )

  def cityDropDown(in: NodeSeq) =
    WiringUI.toNode(in, Info.cities, JqWiringSupport.fade)((d, ns) => cityChoice(state))

  private def cityChoice(state: String): Elem = {
    val cities = CitiesAndStates.citiesFor(state)
    val first = cities.head
    // make the select "untrusted" because we might put new values
    // in the select
    untrustedSelect(cities.map(s => (s,s)), Full(first), s => city = s)
  }

  def idDropDown(in: NodeSeq) =
    WiringUI.toNode(in, Info.ids, JqWiringSupport.fade)((d, ns) => idChoice(state))

  private def idChoice(state: String): Elem = {
    val ids = CitiesAndStates.idsFor(state)
    val first = ids.headOption
    // make the select "untrusted" because we might put new values
    // in the select
    untrustedSelect(ids.map(s => (s,s)), first, s => id = s)
  }
```

I'm not sure this is the best way to create the dependant menus, because I'm storing the complete html in each val, but it does the job for now.

#Where is the code?

I posted a complete [application on github](https://github.com/fmpwizard/lift-conditional-drop-down-menus), feel free to leave a comment and I hope this post helps people understand wiring better.

Enjoy,

  Diego
