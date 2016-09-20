+++
date = "2012-07-22T21:49:57-07:00"
title = "Dynamically adding fields to a Lift application"
aliases = [
	"/blog/adding-fields-dynamically-lift"
]
+++

[title=]: /
[category: Lift]: /
[date: 2012/07/22]: /
[tags: {lift, jQuery, dynamic, scala}]: /

# Dynamically adding fields to a Lift application

A question that I see on the mailing list from time to time is how to dynamically add fields to a page.

The usual answer is that they cannot really do that, at least in a clean way, but we offer a few work arounds. One of them is to declare x number of fields, and just use jQuery to hide/show them.

This past week I had the same requirement at work. One of our Lift applications sends and email invite, and we want users to be able to add x number of reminder emails to follow up the initial invite email.

At first I told my team that we would need to limit the number of reminders to 10, and see if our users could live with it, they were ok with it, but I just could not live with that.

I was right there, staring at IntelliJ, I typed the usual  `def render = {}` and then I could not type those 10 variables and 10 css selector transform (well 20 because we needed two fields per email reminder).

Then I remembered this one [email](https://groups.google.com/d/topic/liftweb/mrRWu0SOymQ/discussion) on the mailing list. There, Antoine shows one way to add fields to a page. While it works, in my case I needed to add two related fields at the time, and I didn't want to have to zip two lists to get my original data.

So I was back at the drawing board. I had one solution that was really ugly, then I had another solution, but it was too fragile for my use case, and the thing with me is that I love being proud of the code I write, not just the open source code, but also the closed source, but I was running out of time, so I started talking with [Tim Nelson](https://twitter.com/eltimn/) and the solution came up, just use plain html fields, and use `jsonCall` to send the data to the Lift server.

## The idea.

The idea is pretty simple, you have your default number of fields on the screen, you do not have any Lift closure associated with them, they are plain old html forms on an html page. I added two buttons, one to __add__ and one to __remove__ fields.

![Initial fields](/images/picture1.jpg)

You can find the JavaScript code on [github](https://github.com/fmpwizard/lift_starter_2.4/blob/lift_dynamic_fields/src/main/webapp/js/myjsfunctions.js). (Note how I'm using an external JavaScript file to hold my functions, this is something else I learned from Tim not too long ago.)

You press the blue button, and the ``div`` that holds the two boxes is duplicated, I change the name of each input field and I'm done.

The next part of the puzzle is the `Finish` button. I needed a way to call a Lift method from JavaScript. You normally do this by using `ajaxCall/jsonCall` but here I added a small twist, I'm using a __named ajax function__, I had seen this idea mentioned before and recently __Brent Sowers__  [wrote](https://groups.google.com/d/topic/liftweb/EqzKHbL6A5E/discussion) how he does it.

## Some code.

I have this snippet method

    def sendToServer = {
      "#sendToServer" #> Script(
        Function(ourFnName, List("paramName"),
          SHtml.jsonCall(JsVar("paramName"), (s: JValue) => addRowsToDB(s) )._2.cmd //use on lift >= 2.5
          //SHtml.jsonCall(JsVar("paramName"), (s: Any) => addRowsToDB(s) )._2.cmd //Use this on Lift < 2.5
        )
      ) &
      "#initDynamic" #> Script(JE.JsRaw(js2).cmd)
    }

that adds a JavaScript function to the page, that in turn executes a `jsonCall` to the server. This is the value of `js2`:

      val js2 =
    """
      |            $(document).ready(function() {
      |              $('#btnDel').attr('disabled','disabled');
      |              window.dyTable = new window.fmpwizard.views.DynamicFields();
      |              window.dyTable.addFields();
      |              window.dyTable.removeFields();
      |            });
    """.stripMargin


My `render` method is pretty simple:

    //This is used to prevent replay attacks
    val ourFnName = Helpers.nextFuncName

    def render = {
      "#next [onclick]" #> JE.JsRaw(js1)
    }

    val js1 =
    """
      |window.dyTable = new window.fmpwizard.views.DynamicFields();
      |window.dyTable.collectFormData(%s);
    """.format(ourFnName).stripMargin


The JavaScript function collectFormData is:

    self.collectFormData = function(fnName) {
      var formData = new Array();
      $(".emailContent").each(function() {
        formData.push([$(this).val(), $(this).parent().children('input').val()]);
      });
      fnName(formData);
    };

So I walk down all the elements with the `class` attribute `.emailContent` and I push its value, and the value of the input field next to it, to an array. I then send this array to our named ajax function and then it is sent to the Lift server. Pay attention that I pass the name of the function to call using the fnName parameter, I added this to prevent replay attacks.

On the server side I processed the array with this method:

    private def addRowsToDB(x: JValue) : JsCmd ={
      val res = for {
        JArray(child) <- x
        JArray(List(JString(text), JString(n))) <- child
      } yield{
        asInt(n).map( num => logger.info("The text we got was: %s and the related field value was: %s".format(text,num)))
        //This is where you can store the data on a database.
        asInt(n).map( num => (text, num))
      }
      JsCmds.Alert("The server got %s" format res)
    }


And finally, this is the markup:

    <form data-lift="form.ajax" action="#" class="well form-inline">
      <div data-lift="Sample">
        <div id="input1" class="clonedInput">
          <label for="Text1">Some textarea box</label><br>
          <textarea class="emailContent" id="Text1" rows="4" cols="100"></textarea><br>
          <hr>
          <label for="runReminderInDays1">Related numeric field: </label>
          <input id="runReminderInDays1" class="runReminderInDays" size="2">
        </div>
        <div>
          <input class="btn btn-primary" type="button" id="btnAdd" value="add another row" />
          <input class="btn btn-danger" type="button" id="btnDel" value="remove last row" />
        </div>
        <div>
          <button id="next" value="Submit" type="button" class="btn"><Lift:Loc>Finish</Lift:Loc></button>
        </div>
      </div>
    </form>
    <div data-lift="Sample.sendToServer">
      <script id="sendToServer"></script>
      <script id="initDynamic"></script>
    </div>


## Sample application.
This time i didn't publish a running application, but I did put the source code on github, so you can clone this [repo](https://github.com/fmpwizard/lift_starter_2.4/tree/lift_dynamic_fields) and you can try it out at home/work.

## Final notes
I'm pretty happy with how all the pieces work together, it looks pretty clean and I don't think I have sacrificed any of Lift's core ideas by doing this. I am still wondering if this technique makes an application vulnerable to any hacking attack and if I find a way I'll update this post.

Turns out there was a problem with the first implementation I wrote (about 1 hour ago), you could just call the JavaScript function that sends the data to the Lift server, and pass any parameters to it. So that would allow anyone to just submit any arbitrary value to our server, something we don;t want.

To prevent this I now use `Helpers.nextFuncName` to generate a unique name for each user that comes to the application, and I then pass this value to the myCompanyjs.js file, so that the script knows which name to use.

>Thank you for reading and don't hesitate to leave a comment/question.
>
>[@fmpwizard](https://twitter.com/fmpwizard)
>
>Diego
