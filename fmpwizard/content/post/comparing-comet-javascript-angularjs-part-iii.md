+++
date = "2013-03-26T21:49:57-07:00"
title = "Different ways to use Comet Actors in Lift (Part III)"
aliases = [
	"/blog/comparing-comet-javascript-angularjs-part-iii"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2013/3/26]: /
[tags: {lift, Scala, comet actors, comet, actors, angularjs, javascript}]: /

# Different ways to use Comet Actors in Lift (Part III).
####AngularJS' turn

On my [previous post](https://fmpwizard.telegr.am/blog/comparing-comet-javascript-knockoutjs-part-ii), I showed how you could write a simple chat application using different techniques. The last technique was using knockoutjs, but recently there have been several posts on the Lift mailing list about AngularJS, and as I wanted to try it out, I thought it would be interesting to see what a chat application using angularJS would look like.

##AngularJS

The server side code for the AngularJS comet is pretty much the same as in the other cases, I did make some changes, for example, instead of passing a `Vector[String]`, I know pass a case class that has one value member, the vector. This eliminates a compiler warning I was getting before. (I fixed it on all comet implementations that are on this sample application).

To keep things separate, from the angularJS comet I send this `JsCmd`:

```
case class NewMessageNg(message: String) extends JsCmd {
  implicit val formats = DefaultFormats.lossless
  val json: JValue = ("message" -> message)
  override val toJsCmd = JE.JsRaw(""" $(document).trigger('new-ng-chat', %s)""".format( compact( render( json ) ) ) ).toJsCmd
}

```

What you need to notice is the name of the event we are triggering: `new-ng-cha`.

AngularJS looks very powerful, but I got the impression that accessing state from outside its normal workflow isn't as natural. What I mean is that to update the `Model` that angular uses, I had to use:

```
  function getScope() {
    var e = document.getElementById( 'messages' );
    return angular.element( e ).scope();
  }
  function addNGMessages( message ) {
    var scope = getScope();
    scope.$apply(function(){
      scope.todos.push( message )
    });
  }
```

Angular has this thing called `scope`, so in order to update the model from Lift's comet and have angular know about it, so that it would update the DOM, I had to get a hold of the current scope of the list of messages, and through its `$apply` function, update the model. But, on the other hand, the model is just very simple:

```
function TodoCtrl( $scope ) {
  $scope.todos = [];
}
```

###Updating the model from comet.

I have some javascript that listens for a particular angular event, and once it it triggered, this gets called:

```
if ( areMessagesLoaded() == false ) {
  $.each(messages, function(index, value){
    addNGMessages( value )
  });
}
```
I check if our model already has items in it (meaning that we opened a new tab, and we are getting duplicate messages), if we don;t have any rows in our model, we append them one at the time to our model, and Angular will update the DOM automatically.

You can see the complete [angular javascript](https://github.com/fmpwizard/lift_starter_2.4/blob/compare-chat-apps-comet-lift/src/main/webapp/static/js/chat-angularjs.js) on github.



# Live demo.

This time I went ahead and uploaded this sample application to [openshift](https://chat-fmpwizardlift.rhcloud.com/chat-angularjs), so go ahead and try it out.


##Code sample.

You will find a complete chat application on [github](https://github.com/fmpwizard/lift_starter_2.4/tree/compare-chat-apps-comet-lift) (note the branch name if you pull it locally).

after you start the app, you will see the three implementations, each on its own page, so you can compare them.


##Final note.

I have only used Angular over the weekend, but I look forward to using it more on side projects. So far, I like it a lot, and I was happy to watch one of their videos, where they said they are working with browser vendors to get something similar to how angular updates the DOM, but built in into browsers. While this may be a few years away, it's great to see that they want to make the web a better place.

As always, feel free to leave a comment here or send an email to the Lift mailing list.

Thanks

  Diego
