+++
date = "2010-04-26T21:49:57-07:00"
title = "Using Apache httpclient Authentication in Scala"
aliases = [
	"/blog/using-apache-httpclient-authentication-in-sca"
]
+++

[title=Using Apache httpclient Authentication in Scala]: /
[category: Lift]: /
[date: 2010/04/26]: /
[path: /using-apache-httpclient-authentication-in-sca]: /
[tags: {apachehttpclient, crawler, httpclient, robots, scala, spider}]: /


# Using Apache httpclient Authentication in Scala

One of the things I love the most is the web, there is so much information out there, just waiting to be found. Something else I love is writing web crawlers/spiders. So it was just natural that I would look into writing one using Scala.

I found a few examples that show how to use Apache httpclient with Scala, but what I did not find much information about, was how to send credentials along the request. And once I did find that information, I kept getting errors[1] from httpclient. The one that was very puzzling was:

```
Caused by: org.apache.http.auth.MalformedChallengeException: Authentication challenge is empty
```

I just couldn't tell what was missing, I was sending the user/password, the server was getting the request, but I kept getting that same error. After reading all over the web about [httpclient and authentication](http://svn.apache.org/repos/asf/httpcomponents/httpclient/branches/4.0.x/httpclient/src/examples/org/apache/http/examples/client/ClientAuthentication.java), I finally found something about [Preemptive Authentication](http://svn.apache.org/repos/asf/httpcomponents/httpclient/branches/4.0.x/httpclient/src/examples/org/apache/http/examples/client/ClientPreemptiveBasicAuthentication.java). At first I wasn't really sure what it was, but in short, it means that there are at least two ways a web server can handle credentials.

You can send a request to a server, the server sees no credentials on the request, so it sends back a 403 error code, then the client sends the username and password and does the login (if it all goes well).

The other way (which I had no idea it existed), is that the server expects to receive the request with the credentials already there, and if no credentials are sent, it will not send a result back to the client.

In order to send the credentials with the initial request, I had to add a PreemptiveAuth() [class](#PreemptiveAuth class) and add this to my code:

```
httpclient.addRequestInterceptor(new PreemptiveAuth(), 0);
```


That was half the battle for me, I then wanted to see how I could stream the content I got back from the web server. Again I found a few examples online on how to do this, but I wasn't too happy with them. They just didn't feel like Scala code, but more like java.

I was about to give up and forget about streaming until I found this post on the scala mailing list showing how to use foldLeft to process the content of a stream. I almost understood how it worked, and then [Razie](https://groups.google.com/forum/#!msg/scalatest-users/Vf2h1W2Uk5E/J8xujpc7S0QJ) was kind enough to explain how it all works.

And this concluded my small adventure with httpclient for now (well, I have a few small projects where I'll be using this and a few more features which I'll post about). You can find an example project on [github](https://github.com/fmpwizard/Scala-and-apache-httpclient-example).

Thanks and Enjoy!



[1]

```

[java] Working directory ignored when same JVM is used.
[java] org.apache.http.client.ClientProtocolException
[java] at org.apache.tools.ant.taskdefs.ExecuteJava.execute(ExecuteJava.java:194)
[java] at org.apache.tools.ant.taskdefs.Java.run(Java.java:764)
[java] at org.apache.tools.ant.taskdefs.Java.executeJava(Java.java:218)
[java] at org.apache.tools.ant.taskdefs.Java.executeJava(Java.java:132)
[java] at org.apache.tools.ant.taskdefs.Java.execute(Java.java:105)
[java] at org.apache.tools.ant.UnknownElement.execute(UnknownElement.java:288)
[java] at sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.dispatch.DispatchUtils.execute(DispatchUtils.java:106)
[java] at org.apache.tools.ant.Task.perform(Task.java:348)
[java] at org.apache.tools.ant.taskdefs.Sequential.execute(Sequential.java:62)
[java] at org.apache.tools.ant.UnknownElement.execute(UnknownElement.java:288)
[java] at sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.dispatch.DispatchUtils.execute(DispatchUtils.java:106)
[java] at org.apache.tools.ant.Task.perform(Task.java:348)
[java] at org.apache.tools.ant.taskdefs.MacroInstance.execute(MacroInstance.java:394)
[java] at org.apache.tools.ant.UnknownElement.execute(UnknownElement.java:288)
[java] at sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.dispatch.DispatchUtils.execute(DispatchUtils.java:106)
[java] at org.apache.tools.ant.Task.perform(Task.java:348)
[java] at org.apache.tools.ant.Target.execute(Target.java:357)
[java] at org.apache.tools.ant.Target.performTasks(Target.java:385)
[java] at org.apache.tools.ant.Project.executeSortedTargets(Project.java:1337)
[java] at org.apache.tools.ant.Project.executeTarget(Project.java:1306)
[java] at org.apache.tools.ant.helper.DefaultExecutor.executeTargets(DefaultExecutor.java:41)
[java] at org.apache.tools.ant.Project.executeTargets(Project.java:1189)
[java] at org.apache.tools.ant.Main.runBuild(Main.java:758)
[java] at org.apache.tools.ant.Main.startAnt(Main.java:217)
[java] at org.apache.tools.ant.launch.Launcher.run(Launcher.java:257)
[java] at org.apache.tools.ant.launch.Launcher.main(Launcher.java:104)
[java] Caused by: org.apache.http.client.ClientProtocolException
[java] at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:643)
[java] at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:576)
[java] at com.fmpwizard.examples.Main$.javaGet(RestPutSpecTest.scala:83)
[java] at com.fmpwizard.examples.Main$.main(RestPutSpecTest.scala:33)
[java] at com.fmpwizard.examples.Main.main(RestPutSpecTest.scala)
[java] at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
[java] at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.taskdefs.ExecuteJava.run(ExecuteJava.java:217)
[java] at org.apache.tools.ant.taskdefs.ExecuteJava.execute(ExecuteJava.java:152)
[java] ... 34 more
[java] Caused by: org.apache.http.auth.MalformedChallengeException: Authentication challenge is empty
[java] at org.apache.http.impl.auth.RFC2617Scheme.parseChallenge(RFC2617Scheme.java:71)
[java] at org.apache.http.impl.auth.AuthSchemeBase.processChallenge(AuthSchemeBase.java:111)
[java] at org.apache.http.impl.auth.BasicScheme.processChallenge(BasicScheme.java:88)
[java] at org.apache.http.impl.client.DefaultRequestDirector.processChallenges(DefaultRequestDirector.java:1133)
[java] at org.apache.http.impl.client.DefaultRequestDirector.handleResponse(DefaultRequestDirector.java:1028)
[java] at org.apache.http.impl.client.DefaultRequestDirector.execute(DefaultRequestDirector.java:545)
[java] at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:641)
[java] ... 44 more
[java] --- Nested Exception ---
[java] org.apache.http.client.ClientProtocolException
[java] at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:643)
[java] at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:576)
[java] at com.fmpwizard.examples.Main$.javaGet(RestPutSpecTest.scala:83)
[java] at com.fmpwizard.examples.Main$.main(RestPutSpecTest.scala:33)
[java] at com.fmpwizard.examples.Main.main(RestPutSpecTest.scala)
[java] at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
[java] at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.taskdefs.ExecuteJava.run(ExecuteJava.java:217)
[java] at org.apache.tools.ant.taskdefs.ExecuteJava.execute(ExecuteJava.java:152)
[java] at org.apache.tools.ant.taskdefs.Java.run(Java.java:764)
[java] at org.apache.tools.ant.taskdefs.Java.executeJava(Java.java:218)
[java] at org.apache.tools.ant.taskdefs.Java.executeJava(Java.java:132)
[java] at org.apache.tools.ant.taskdefs.Java.execute(Java.java:105)
[java] at org.apache.tools.ant.UnknownElement.execute(UnknownElement.java:288)
[java] at sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.dispatch.DispatchUtils.execute(DispatchUtils.java:106)
[java] at org.apache.tools.ant.Task.perform(Task.java:348)
[java] at org.apache.tools.ant.taskdefs.Sequential.execute(Sequential.java:62)
[java] at org.apache.tools.ant.UnknownElement.execute(UnknownElement.java:288)
[java] at sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.dispatch.DispatchUtils.execute(DispatchUtils.java:106)
[java] at org.apache.tools.ant.Task.perform(Task.java:348)
[java] at org.apache.tools.ant.taskdefs.MacroInstance.execute(MacroInstance.java:394)
[java] at org.apache.tools.ant.UnknownElement.execute(UnknownElement.java:288)
[java] at sun.reflect.GeneratedMethodAccessor1.invoke(Unknown Source)
[java] at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
[java] at java.lang.reflect.Method.invoke(Method.java:616)
[java] at org.apache.tools.ant.dispatch.DispatchUtils.execute(DispatchUtils.java:106)
[java] at org.apache.tools.ant.Task.perform(Task.java:348)
[java] at org.apache.tools.ant.Target.execute(Target.java:357)
[java] at org.apache.tools.ant.Target.performTasks(Target.java:385)
[java] at org.apache.tools.ant.Project.executeSortedTargets(Project.java:1337)
[java] at org.apache.tools.ant.Project.executeTarget(Project.java:1306)
[java] at org.apache.tools.ant.helper.DefaultExecutor.executeTargets(DefaultExecutor.java:41)
[java] at org.apache.tools.ant.Project.executeTargets(Project.java:1189)
[java] at org.apache.tools.ant.Main.runBuild(Main.java:758)
[java] at org.apache.tools.ant.Main.startAnt(Main.java:217)
[java] at org.apache.tools.ant.launch.Launcher.run(Launcher.java:257)
[java] at org.apache.tools.ant.launch.Launcher.main(Launcher.java:104)
[java] Caused by: org.apache.http.auth.MalformedChallengeException: Authentication challenge is empty
[java] at org.apache.http.impl.auth.RFC2617Scheme.parseChallenge(RFC2617Scheme.java:71)
[java] at org.apache.http.impl.auth.AuthSchemeBase.processChallenge(AuthSchemeBase.java:111)
[java] at org.apache.http.impl.auth.BasicScheme.processChallenge(BasicScheme.java:88)
[java] at org.apache.http.impl.client.DefaultRequestDirector.processChallenges(DefaultRequestDirector.java:1133)
[java] at org.apache.http.impl.client.DefaultRequestDirector.handleResponse(DefaultRequestDirector.java:1028)
[java] at org.apache.http.impl.client.DefaultRequestDirector.execute(DefaultRequestDirector.java:545)
[java] at org.apache.http.impl.client.AbstractHttpClient.execute(AbstractHttpClient.java:641)
[java] ... 44 more
[java] Java Result: -1

```


# PreemptiveAuth class
```

import org.apache.http.HttpRequest
import org.apache.http.protocol.HttpContext

class PreemptiveAuth extends org.apache.http.HttpRequestInterceptor {
  def process( request: HttpRequest, context: HttpContext) {

    val authState = context.getAttribute(ClientContext.TARGET_AUTH_STATE).asInstanceOf[AuthState]
    // If no auth scheme avaialble yet, try to initialize it preemptively
    if (authState.getAuthScheme() == null) {
      val authScheme = context.getAttribute("preemptive-auth").asInstanceOf[AuthScheme]
      val credsProvider = context.getAttribute(ClientContext.CREDS_PROVIDER).asInstanceOf[CredentialsProvider]
      val targetHost = context.getAttribute( ExecutionContext.HTTP_TARGET_HOST ).asInstanceOf[HttpHost]
      if (authScheme != null) {
        val creds credsProvider.getCredentials(
          new AuthScope( targetHost.getHostName(), targetHost.getPort())
        ).asInstanceOf[Credentials]
        if (creds == null) {
          throw new HttpException("No credentials for preemptive authentication")
        }
        authState.setAuthScheme(authScheme)
        authState.setCredentials(creds)
      }
    }
  }
}

```
