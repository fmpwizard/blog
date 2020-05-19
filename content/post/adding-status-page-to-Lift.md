+++
date = "2013-01-12T21:49:57-07:00"
title = "Status page in Lift"
aliases = [
	"/blog/adding-status-page-to-lift",
	"/adding-status-page-to-lift"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2013/1/12]: /
[tags: {lift, scala, stateless, monitoring}]: /

# Status page for your Lift server.

For the past week I have been building a little Lift application to run on a [Raspberry Pi](http://www.raspberrypi.org/) computer. This application is supposed to control the GPIO pins that come on the Raspberry Pi.

But, as this little computer is pretty slow to boot (well, a few seconds), I thought that I should add some kind of status page that I can keep hitting from my laptop, and once I get an OK response, well, Lift is up and I can start controlling the pins.

## Lift beauty

I wanted this new page to be:

* Stateless
* Should not require any html template
* Not to be included in the Sitemap

And it was super easy to add. All I had to do was add this entry to the Sitemap definition:

````
Menu.i("Status") / "ping" >> Hidden >> CalcStateless(() => true ) >> EarlyResponse(() => Full(OkResponse()))
````

This entry creates a /ping endpoint, `>> Hidden` makes is so that it will not appear on the menus, `>> CalcStateless(() => true )` makes it stateless, meaning that `Jetty` will not create sessions when I keep hitting this url. And finally, `>> EarlyResponse(() => Full(OkResponse()))` tells **Lift** to give the client an Ok 200 response, without any text body, as soon as you hit this url. So it does not require an html page in the server.

Last week we added something similar at work, so our monitoring application would not create sessions on our servers.

>Thank you for reading and don't hesitate to leave a comment/question.
>
>[@fmpwizard](https://twitter.com/fmpwizard)
>
>Diego
