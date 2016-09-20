+++
date = "2013-12-23T21:49:57-07:00"
title = "Using Grunt and Bower with Lift"
aliases = [
	"/blog/using-grunt-and-bowerwith-lift"
]
+++

[title=]: /
[category: go]: /
[date: 2013/12/23]: /
[tags: { lift, grunt, gruntjs, bower, javascript, css, minification}]: /


# Using Grunt and Bower with Lift
I'm very grateful that I always get a chance to work with very smart people, and I get the chance to learn new tools, languages, techniques, etc. Here I'll talk about [Grunt](http://gruntjs.com/), which [Tim Nelson](https://twitter.com/eltimn) introduced me to. And I'll talk a bit about [Bower](http://bower.io/) and how they can work together to help you in your [Lift](http://liftweb.net/) applications.

##What is Grunt?
For those using Scala, think of grunt as a build tool for javascript and css files (I was going to say, think of it as sbt, but then those who ... *dislike* ... sbt may get some negative ideas about grunt.

From the grunt site, they label it as a task runner, and here I use it to run tasks like js hint, minify both, js and css files and a few other things.

The thing I love the most is that I can have a terminal running `grunt watch` and as I edit my javascript files, it will run `jshint` and tell me the errors that I normally would only see on the browser after refreshing the page and clicking around to **test out** the code I just wrote. This saves a lot of time.

##What about Bower?

I use bower as a dependency manager, I have a `bower.json` file where I include which javascript and css frameworks I need, with their versions, and bower will go and get them for me. This is great because when a new version of, let's say, jQuery comes out, I don't have to go, download the zip file, expand it, include it on my project, etc. Just edit the version number, run `bower install` and you are ready to go.

##But Fobo does something similar to bower.

Yes, it does, and [Fobo](https://github.com/karma4u101/FoBo) has been great for me so far. But I still had the issue that my application ended up having several javascript and css files listed on each page, so the browser had to request each of those files. From the point of view of web applications and well performing applications, it is better to include fewer files, and the recommendation is to concatenate all your js files into one, and the same applies to css files.

##But xyz sbt plugin does that.

I'm sure, but sbt is slow, plugin versions change and it's a lot of work to track down which dependency works with this or that other plugin, and underneath they still run other commands. I feel that sbt does a good job at scala code (and maybe java, never tried that), but we should use a different set of tools for client side code, and client side developers are being very productive with tools like Grunt (there is also [yeoman](http://yeoman.io/) if you really want to get into this).

The community behind grunt is huge, and that means that most likely what you are trying to do, they already did for you.

##So now what?

What I'd like to do is to update the [sample templates](http://liftweb.net/download) we provide on the lift site, and have something like [this one](https://github.com/fmpwizard/lift-examples).

The [README.md](https://github.com/fmpwizard/lift-examples/blob/master/README.md) file on that project has a detailed explanation of how to install and use grunt and bower, and how a normal workflow looks like. But in summary, adopting this template would mean that you end up with an optimized javascript file, as well as an optimized css file from the start. You will no longer have to procrastinate until the day before release to find out how to minify and concatenate your files. And it paves the way to do things the **right way** from the start.

##Drawbacks?

The one issue I have right now, with the implementation that I use on [thie repo](https://github.com/fmpwizard/lift-examples) is that `grunt watch` will not only update the js files you modified,but it will rerun the minification, uglification and concatenation of js files, and this takes time, on my laptop it takes about  a second, or maybe a bit more.

A better solution would be to include the files just like we used to, and only run `jshint` on the file you just changed, and when you are ready to deploy your app, you would run it in `production` mode and then Lift would replace all those `<script src=...</script>` tags for just one. I believe this is what Tim has running right now, but I haven't looked at it yet.

But I didn't want to delay posting this, I believe that releasing early and often is a good thing, and we can all make this idea better, together.

##Final note.

Thanks for reading, please give the [sample app](https://github.com/fmpwizard/lift-examples) a try and let us know what you think.

>Thanks.
  >>Diego
