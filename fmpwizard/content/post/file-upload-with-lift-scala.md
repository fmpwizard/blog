+++
date = "2011-03-21T21:49:57-07:00"
title = "File Upload with Lift - Scala"
aliases = [
	"/blog/file-upload-with-lift-scala"
]
+++
[title=]: /
[category: Lift]: /
[date: 2011/03/21]: /
[tags: {fileupload, lift, liftweb, scala}]: /


# File Upload with Lift - Scala

As I continue to use Lift, I decided to add a file upload to one of my side projects. I had seen the SHtml.fileUpload method before, so I thought it was going to be one of those 5 minutes things.

A few days later and several email exchanges with Jeppe on the mailing list, I finally got it to work. Not that it was hard, but there was a tiny detail that was staring at me the whole time, but I just could not see it.

The culprit.

*My template*

I had

```
<form class="lift:Upload?form=post” multipart=”true">
```

and Jeppe was kind enough to point out that I should instead use:


```
<form class="lift:Upload?form=post;multipart=true">
```

You can think of `multipart=true` is one more parameter that is sent to `lift:Upload`

I hope that this would save you some time, and if not, at least it reinforces the importance of asking on the [mailing list](https://groups.google.com/forum/#!forum/liftweb) and providing a [sample application](https://www.assembla.com/wiki/show/liftweb/Posting_example_code) to reproduce your problem.

##Sample application.

I put together a sample application that uses the CSS Selector Transformation (also known as designer friendly template) and it is hosted on [github.com](https://github.com/fmpwizard/lift_fileupload)  

Note that the images are stored on the webapp folder, this should be changed before you go in production :)

Enjoy

  Diego
