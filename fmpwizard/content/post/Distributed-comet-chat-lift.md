+++
date = "2012-07-14T21:49:57-07:00"
title = "A distributed Lift Comet Chat Application"
aliases = [
	"/blog/distributed-comet-chat-lift"
]
+++
[title=]: /
[category: Lift]: /
[date: 2012/07/14]: /
[tags: {lift, finagle, comet, cluster, distributed}]: /

# A distributed Lift Comet Chat Application
Lift has very powerful comet support, and 2.5 is bringing even better support. But one of the things I always wondered about was, how to have comet work across several containers.

A few months ago I had an idea of how to do this, and was planning on talking about it at OSCON, but my talk wasn't accepted. Then I decided I could just blog about it and here we are.

## The problem.
On a typical chat application, you store your messages in an object, and singleton. And as messages come in, you send them to all the clients.

Now imagine you have one server in the US, and another server in Europe. And you have people connect to the US server and people connect to the European server. They would not see each others messages, because we are storing the messages in the individual servers.

## The solution.
![Distributed Chat](https://dl.dropbox.com/s/eplqjhmwkxdi4a4/distributed-comet-chat.png)
While this is not the best solution, it works and may be useful to others to base their solutions on. What I did was to add one more element to the mix, a CouchDB server, to act as a global store for messages.

The idea is simple, client A connects to server US, when client A sends a message, this message is store in the server US's singleton, but it is also sent to the CouchDB server.

Both, server US and server Europe query the CouchDB instance once a second to see if new messages arrived, if any are found, the messages are downloaded to the server and broadcasted to all the connected clients.

###Pros of this solution.
One of the things I like about this solution is that I can add/remove any number of servers, and it does not need any reconfiguration on the other servers and/or the CouchDB central server. This was a design goal I had, I didn't want to have to keep a list of current servers, so if I have 10 servers serving messages, all 10 servers just call the one CouchDB server for new messages.

I also went with CouchDB as the central server because it already comes with a REST endpoint to receive messages, and it has this one feed called "_changes", you basically call this _changes url and you get a notification of the changes that happened on a specific database.

You could, of course, just write a Lift REST application that does the same thing, or you could use some message queue system to achieve the same.

### Cons of this solution.
We have a central point of failure, if CouchDB is down, nobody gets any messages. In which case we could have a cluster of CouchDB servers and some kind of HA in front of it. And we could also change the Chat application logic so that instead of only retrieving messages from Couch, we could also display the messages generated on the same JVM, and filter them out when we fetch for new changes.

## Does it really work?
Yes! I have two instances running on Cloudbees, you can access one server [here](http://lift-comet.fmpwizard.cloudbees.net/) and the other server [here](http://lift-comet-2.fmpwizard.cloudbees.net/)

Open them on different browser tabs, enter a name on the Nickname field and type any message, after you press enter or click on `Chat!`, the message will appear on both servers.  *



## Want to try something else?
You could even add your own machine to the cluster, just

    //clone the sample application and create a folder called lift_clustered_comet
    git clone https://github.com/fmpwizard/lift_starter_2.4.git  lift_clustered_comet
    //enter the newly created folder
    cd lift_clustered_comet
    //go into the branch that has the right code
    git checkout lift_clustered_comet
    //start sbt and start jetty
    ./sbt
    >container:start

Then go to `http://127.0.0.1:8080` and enter a name and a message, after you click Chat, the message will log to the CouchDB server and it should also appear on [server 1](http://lift-comet.fmpwizard.cloudbees.net/) and [server 2](http://lift-comet-2.fmpwizard.cloudbees.net/)    

## Code
Al usual, the code is hosted on [github](https://github.com/fmpwizard/lift_starter_2.4/tree/lift_clustered_comet/src/main/scala/com/fmpwizard) (note that I'm using the same repository, but different branches for my new blog posts).

To put all this together, I'm using Twitter Finagle to retrieve the new messages from CouchDB, as well as sending the new data to the CouchDB server. And then it is all Lift, using LiftActors, CometActors and the Schedule feature in Lift.

## Notes
I hope you enjoy it and feel free to leave comments here or on the Lift mailing list.

Thanks


* Because I'm using Cloudbees' free account, the application could be in sleep mode, so the Schedule that retrieves the messages may not be running at that point
