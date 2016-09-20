+++
date = "2012-09-05T21:49:57-07:00"
title = "H2 Web Consoler and Lift"
aliases = [
	"/blog/lift-and-h2"
]
+++

[title=]: /
[category: Lift]: /
[date: 2012/09/5]: /
[tags: {lift, H2, scala}]: /

#H2 web console and Lift

At work we use H2 as the default database while we develop our apps. This helps because t's just easy to setup and if anything goes wrong, we just delete the file and restart our application.

All this is nice, but one thing that wasn't so smooth was accessing H2 from outside Lift, and be able to run any queries against it.

Before I joined Elemica, they were using SQuirrelSQL, which I thought was horrible, it may be a great tool, but all I wanted was connect, and run queries.

On my personal projects, I was using a bash script that started up the web server that comes with H2. So I was about to add that script to our project when Tim Nelson showed me how you can add a few lines to Boot and the web.xml file in webapp to achieve the same.

##Code


All you have to do is add these lines to web.xml:



    <servlet>
      <servlet-name>H2Console</servlet-name>
      <servlet-class>org.h2.server.web.WebServlet</servlet-class>
      <load-on-startup>0</load-on-startup>
    </servlet>
    <servlet-mapping>
      <servlet-name>H2Console</servlet-name>
      <url-pattern>/console/*</url-pattern>
    </servlet-mapping>


And add these lines to Boot:

    if (Props.devMode || Props.testMode) {
      LiftRules.liftRequest.append({case r if (r.path.partPath match {
        case "console" :: _ => true
        case _ => false}
      ) => false})
    }


This is tested with H2 version `1.3.149`

#Final notes

After you restart jetty, you can go to [http://127.0.0.1:8080/console](http://127.0.0.1:8080/console/) and you will see a login screen, don't enter anything for the username and password, simply click `Connect`and you'll be in.

![H2 console](/images/h2-web-console.jpg)

You can then run any queries against your database.


Thanks

  Diego
