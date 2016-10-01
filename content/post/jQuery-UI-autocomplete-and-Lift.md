+++
date = "2012-06-20T21:49:57-07:00"
title = "Lift autocomplete with jQueryUI"
aliases = [
	"/blog/jquery-ui-autocomplete-and-lift"
]
+++

[title=]: /
[category: Personal]: /
[date: 2012/06/20]: /
[tags: {lift}]: /


A couple of days ago I had to rework an autocomplete widget we had at work.

The old implementation was using Lift as a REST service, and then jQuery to do the autocomplete. It worked well, but it was exposing some internal database IDs and I knew we could do better.

## The goals.

I had a few ideas of what I wanted to get out of this rewrite:

1. As the user typed a name, there should be a drop down menu with the found results. If you clicked on any of those, it had to take you to a details page.
2. It should only send the minimum required information to the client.
3. It should not expose internal database IDs.

## Some code.
_Well, a lot of code._

#### Snippet

    def nameAutoComplete = {
      "#search [onkeyup]" #> SHtml.ajaxCall(JE.JsRaw("""$("#search").val()"""), search _)
    }

#### HTML

    <div data-lift="MySnippet.nameAutoComplete">
      <label for="search" class="span-4"><lift:Loc>general.search</lift:Loc>: </label>
      <input id="search" name="search" class="span-8" />
    </div>

The basic idea is that we bind the onkeyup event to an ajaxCall that sends the current text entered in the search box to a method on my snippet class. This method takes the string, does a search on our Neo4J graph, and returns the result as a JavaScript array.

#### Generating the source data

    private def search(term: String): JsCmd = {
      //Get a json payload from Neo4j
      val names = Service.byName(term)
      //Change the id field for a link to the details page. And set a RequestVar with the current name id
      val jsonWithLinks= names transform {
        case JField("id", JString(s)) => {
          JField("id",
            JString( SHtml.link(Paths.details.loc.calcDefaultHref,
              () => NameId.set(s), <span>Link</span>).toString
            )
          )
        }
        //I needed to rename my name Json value for label, which is what jQueryUI wants.
        case JField("name", JString(s)) =>  JField("label", JString(s))
      }
      //Call this JavaScript function with the JavaScript array as a parameter
      JE.JsRaw("myautocomplete(" + compact(render(jsonWithLinks)) + " )").cmd
    }

The code has comments, so I hope it's easy to understand.  
I was very happy to find out about the transform method from lift-json. It lets me replace something like ``[{id: "1234"}]`` for ``[{id: "<a href=\"/details?FGTR45W345F=_\"><span>Link Name</span></a>"}]``  
Later, on my JavaScript function, I take the value from the href to set the `select` action on the Autocomplete code.


    function autocomplete(names) {
      $("#search").autocomplete({
      source: names,
      focus: function( event, ui ) {
        $( "#search" ).val( ui.item.label );
        return false;
      },
      select: function( event, ui ) {
        $( "#search" ).val( ui.item.label );
        var url= ui.item.organizationId.split('"');
        //Here I redirect the page to the details url, passing the
        //Lift variable obfuscated name
        window.location=url[1];
        return false;
      }
    }).data( "autocomplete" )._renderItem = function( ul, item ) {
      var itemDescription = self.buildItemDescription(item);
      return $( "<li></li>" )
        .data( "item.autocomplete", item )
        .append( itemDescription )
        .appendTo( ul );
      };
    };

    function buildItemDescription(item){
      var description = '<a>';
      //If my json data shows a logo url, show that on the menu, otherwise, show the name of
      //the person.
      if(item.logoURL != ""){
        description += '<img src="' + item.logoURL + '" height=32/>';
      } else {
        description += '<span style="font-size: 1.2em;">' + item.label + '</span>';
      }
      return description + "</a>"
    }

Note that the JavaScript autocomplete code does not have to be so much, we are just using several options to fit our needs.

## Summary.
The basic idea behind this approach is that instead of having a REST API endpoint to server my results, I'm simply passing a JavaScript Array to the autocomplete jQuery code. And then I use this data to populate the drop down menu. To jQuery, it is a local source, but thanks to Lift Is is actually dynamic information based on the data you enter on the search box.

I use this same technique with jQuery DataTables, I tell jQuery that the source is a local array, but I regenerate the values based on the results processed by my snippet.

As always, if you have any questions or comments, don't hesitate to email the Lift mailing list or email me directly at diego@fmpwizard.com
