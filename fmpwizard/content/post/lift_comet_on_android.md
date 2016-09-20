+++
date = "2015-07-19T21:49:57-07:00"
title = "Lift Comet for native Android apps"
aliases = [
	"/blog/lift_comet_on_android"
]
+++
[title=]: /
[category: android]: /
[date: 2015/07/19]: /
[tags: {lift, android, sdk, google cloud messaging}]: /

#Lift Comet for native Android apps

A very powerful feature in Lift is its comet support, with very little code you can have an app that gives feedback to your users in real time. If you are new to the concept, these [videos](http://blog.fmpwizard.com/blog/comet-actors-presentation) may help you.

But things get complicated when it's time to write a mobile app and you want to have the same real time feedback on a native app.

This question has been asked on the mailing list several times, and the answer always boils down to:


>"You have to roll your own using rest async and use an http client on your mobile app."

I never liked that answer, even though I didn't have any better alternative .... until a few months ago when it was my turn to write an Android app for one of my clients.

##The problem

One of the feature on this Lift site I have been working on, is to be able to chat with colleagues on specific items, think of it as real time comments on a blog post. Once we had that in place we added notifications, where users could type the normal `@your name` and you get a notification, and you also get notifications from the system when other actions take place (files uploaded, long running tasks finish, etc).

This works really well when you are on your desktop/laptop, but if you visit the site on your mobile browser, you don't get notification (firefox has them, but you have to have the site running, and I think chrome enabled them not too long ago, but same story, the page has to be running).

So I decided we needed an Android app to solve this issue.

I really didn't want to have to maintain a long poll http connection at all times, that felt really wasteful and I imagined would run down the battery pretty fast.

##Enter GCM

Google offers [Google Cloud Messaging](https://developers.google.com/cloud-messaging/), which in short means that I don't have to keep an http connection alive, the OS will do that for me, all I have to do is, from the Lfit server, send an HTTP request to the google servers, including a key that is specific to the device I want to send the notification to, and then the Google servers send that message to the android device.


*Sample request from our Lift server:*
```
val httpResp = Http("https://android.googleapis.com/gcm/send")
            .header("Authorization", s"key=${AppSettings.googleCloudMessagingKey}")
            .header("Content-Type", "application/json")
            .postData(compactRender(payload(device.key.get, author, url)))
            .asString

```

And then the android app listens for those messages and knows to display them as a notification on the cell. You'll find a good example app to get you started [here](https://developers.google.com/cloud-messaging/android/start).

This means that I don't even have to have my app running on the device to get notifications, as long as the phone is on, it will get the notifications, and notifications received while being off are queued on the Google servers, for up to 4 weeks iirc.

In our case, the app I wrote mostly uses webview, so we access our regular site which is rendered in a mobile friendly format. The main advantage of using the app comes from being able to receive notifications from our Lift website in real time. Once the user clicks on the notification, our app picks it up and takes the user to the right page.

For our use case, we only need communication one way, from the Lift server to the mobile devices, but GCM allows you to also send messages from the device to the server.

##Code.

While I can't post the code for the Android app I wrote, the example apps on the Google site are a very good starting point, and on the Lift side, just hook the http call where you normally send the Comet message. We are using [scalaj-http](https://github.com/scalaj/scalaj-http) to make the http requests.

##Finale note.

Adopting Google Cloud Messaging reduced the amount of code I would have to write, saves battery life for our users and provides a very integrated way to communicate with native apps, in real time.

In the near future I'll be writing an iOS app, and most likely will also use GCM there too.

>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
