+++
date = "2010-05-24T21:49:57-07:00"
title = "String.asInstanceOf scala.xml.Elem"
aliases = [
	"/blog/stringasinstanceofscalaxmlelem"
]
+++


[title:  ]: /
[category: Lift]: /
[date: 2010/5/24]: /
[tags: {lift, Scala, xml}]: /
[path: /stringasinstanceofscalaxmlelem]: /

# String.asInstanceOf[scala.xml.Elem]


Up until a few weeks ago I was mostly using Scala to read Json data, but the time came when I had to read some XML. I already had a method to read the Json output from a web service, which returns a StringBuilder. So I thought that I could simply use: (This is just a simplified code sample)


```
println(parseXML(jsonAsString.asInstanceOf[scala.xml.Elem]))

package com.fmpwizard.examples

import scala.xml._

object Main{
  def main(args: Array[String])= {
    def getJsonAsString(url: String): StringBuilder= {
      new StringBuilder( """ <doc>   <node>info</node> </doc> """)
    }

    def parseXML(xmlIn: scala.xml.Elem): String= {
      (xmlIn \ "node").text
    }
    val jsonAsString= getJsonAsString("http://some.here.com").toString

    println(parseXML(jsonAsString.asInstanceOf[scala.xml.Elem]))
   }
}

```

I then run:

    $ scalac StringToElem.scala


And it compiled just fine, to my surprise, when I tried to run:

    $ scala com.fmpwizard.examples.Main

I got this error message:


```
java.lang.ClassCastException: java.lang.String cannot be cast to scala.xml.Elem
at com.fmpwizard.examples.Main$.main(StringToElem.scala:23)
at com.fmpwizard.examples.Main.main(StringToElem.scala)         
at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)         
at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:39)         
at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:25)         
at java.lang.reflect.Method.invoke(Method.java:597)         
at scala.tools.nsc.ObjectRunner$$anonfun$run$1.apply(ObjectRunner.scala:75)         
at scala.tools.nsc.ObjectRunner$.withContextClassLoader(ObjectRunner.scala:49)         
at scala.tools.nsc.ObjectRunner$.run(ObjectRunner.scala:74)         
at scala.tools.nsc.MainGenericRunner$.main(MainGenericRunner.scala:154         
at scala.tools.nsc.MainGenericRunner.main(MainGenericRunner.scala)

```



What do I do in cases like this? Google to the rescue, well, not so this time. I was mostly searching for a way to convert a String to [xml.Elem](http://www.scala-lang.org/api/current/scala/xml/Elem.html) and I just could not find any example, I searched the [mailing list archives](http://scala-programming-language.1934581.n4.nabble.com/Scala-User-f1934582.html) and nothing. I found how to convert from xml.Elem to String, using the .toString method inherited form [Node](http://www.scala-lang.org/docu/files/api/scala/xml/Node.html) but that was not what I needed

I was surely not the first person trying to convert a String to XML, but I just didn't know what else to try, I kept reading the scaladoc but I couldn't find anything there either. I even remembered reading about scala and xml on the book [Programming Scala](http://ofps.oreilly.com/titles/9780596155957/) but I somehow missed the solution to my problem.


## The solution.

    import scala.xml._
    XML.loadString(stringVal)

And of course, after I found XML.loadString(), I also saw it on the scaladoc pages. I hope that the next person that tries to do String.asInstanceOf[xml.Elem] find this post and saves a few hours/days of trying different things.

Just for completeness, this is the full object so that you can play around too:


    println(parseXML(jsonAsString.asInstanceOf[scala.xml.Elem]))

    package com.fmpwizard.examples
    import scala.xml._
    object Main{
      def main(args: Array[String])= {
        def getJsonAsString(url: String): StringBuilder= {
          new StringBuilder( """ <doc>   <node>info</node> </doc> """)
        }
        def parseXML(xmlIn: scala.xml.Elem): String= {
          (xmlIn \ "node").text
        }
        val jsonAsString= getJsonAsString("http://some.here.com").toString
        println(parseXML(XML.loadString(jsonAsString)))
      }
    }



### Comments copied from old blog:

```
robbbminson (Twitter) responded:
Whilst this is great, the loadString function actually seems to want to do a full SAX parse, validating the string. So a simple snippet of the form "<foo>content</foo>" will actually fail, even though it's a totally valid Elem. Any idea how to get round this?
Aug 7 2011, 7:16 PM
Diego Medina responded:
I get this using scala 2.8.1
scala> val x= XML.loadString("<foo>content</foo>")
x: scala.xml.Elem = <foo>content</foo>

so it works just fine, unless I'm missing something

Mar 15 2012, 2:36 PM
David Leppik responded:
If you're getting the error "The markup in the document following the root element must be well-formed" then it's because the parser expects a single root element. "<foo />" works, but "<foo /><foo />" gives that error.
Apr 24 2012, 8:05 AM
bastl responded:
the link to api is broken!
Apr 24 2012, 10:22 AM
Diego Medina responded:
Thanks, it is fixed now.
```
