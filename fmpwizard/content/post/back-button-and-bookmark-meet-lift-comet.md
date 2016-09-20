+++
date = "2011-06-15T21:49:57-07:00"
title = "Back button and bookmark meet Lift comet"
aliases = [
	"/blog/back-button-and-bookmark-meet-lift-comet"
]
+++

[title=]: /
[category: Lift]: /
[date: 2011/06/15]: /
[tags: {ajax, backbutton, bbq, bookmark, comet, jquery, lift, liftweb, scala}]: /

# Back button and bookmark meet Lift comet

One of the first, if not the first question, that I asked on the mailing list was if Lift had support for browser history when doing ajax requests.

I was coming from using GWT, and they had a nice mechanism for doing this. It uses the url fragment identifier to achieve this.

I had a few answers to my question, but I was too new to Scala and Lift to really implement anything.
I kept thinking about how to do this in the back of my mind. I wanted to write an application that would use ajax or comet to update parts of the UI, so no full page refresh would be done. And I also wanted to be able to share links with other users, and once they click on it, it had to take them to the same page, with the same content I had on my browser.

After much thinking, and reading this _answer_ (I can't find the thread any more) from dpp, I finally got it working!

To see this in action, please clone and start the [sample application](https://github.com/fmpwizard/lift-comet-history)

# What does it do?

![Diagram](/images/27764656-back-button-lift-comet.png)

Before you click on any of the [1](http://127.0.0.1:8080/2/liftactorform#bbq1=1) [2](http://127.0.0.1:8080/2/liftactorform#bbq1=2) [3](http://127.0.0.1:8080/2/liftactorform#bbq1=3) links, look at the url, it looks like http://127.0.0.1:8080/2/liftactorform.

When you click on the 1 link, jQuery sends a PUT request to a REST interface running on the same server.

```
            var cometName=  $('#cometName').val();
            //alert(cometName);
            jQuery.ajax({
                      type: 'PUT',
                      contentType: "application/json",
                      //url: "http://" + window.location.hostname +
                      //  ":"+window.document.location.port+"/v1/rest/cities",
                      url: "http://dmedina.scala-tools.org/2/v1/rest/cities",
                      dataType: "json",
                      data: "{\"comet_name\":\""+ cometName +"\",\"id\":\"" + url +"\"}",
                      success: function() {
                          //alert('Put Success');
                      },
                      error: function(a,b,c) {
                          console.log("XMLHttpRequest: " + a);
                          console.log("textStatus: " + b);
                          console.log("errorThrown: " + c);
                          alert("XMLHttpRequest : " + a + " textStatus : " + b + " errorThrown : " + c);
                      }
            });
```

This PUT request has two pieces of information, it has the value 1, which just represents the link name, and it also has the name of the comet actor that is present on this page.

Once the REST API receives this request, it parses the json data and it looks up a city-> state pair based on the id we sent (for sake of simplicity, I did not include a mapper class).

After locating the city and state that match our id, it sends a message to the comet actor we have on our page and tells it to update the UI with the city and state.

```
case CityStateUpdate(cometName, city, state) => {
  info("Comet Actor %s will do a partial update".format(this))

  /**
   * You can have many partialUpdate() calls here.
   */
  partialUpdate(
    SetHtml("city", Text(city))
  )
  partialUpdate(
    SetHtml("state", Text(state))
  )
}
```

##What about the back button?

Now, look at the url, if you clicked on the 1 link, the url will now have a fragment, it has **#bbq1=1**. You can now go ahead and click on the other links. You will notice that the url fragment changes, the city and state change, but there is no full page refresh.

You can click on the back button on your browser and the city and state values will update accordingly. You can even have multiple tabs open simultaneous and each of them will have its own city and state. I’m able to achieve this by using different comet actors on each tab.

##Final thoughts.

In my case, this sample application opens up a lot of possibilities, I know there may be other ways of implementing the back button / bookmark feature, like the one outline [here](https://groups.google.com/forum/#!topic/liftweb/_A-Zg7oFBhQ), but I’m pretty happy with using a REST API and jQuery. Oh, and I’m using the BBQ jQuery plugin to do the hashtag magic.

##Where is the code?

As always, you can find the complete code on [github](https://github.com/fmpwizard/lift-comet-history) and thanks to David and Derek for providing the server that is hosting the demo application.

Enjoy

  Diego
