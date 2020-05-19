+++
date = "2014-03-06T21:49:57-07:00"
title = "Go Cortex - using Wit.ai on a raspberry pi connected to an arduino and written in go"
aliases = [
	"/blog/go-cortex-using-wit-ai-using-raspberrypi-using-arduino",
	"/go-cortex-using-wit-ai-using-raspberrypi-using-arduino"
]
+++
[title=]: /
[category: go]: /
[date: 2014/03/06]: /
[tags: { go, golang, wit, machine learning, arduino, raspberrypi, cortex}]: /


# Go Cortex - using Wit.ai on a raspberry pi connected to an arduino and written in go

## What is it?

### Update

I wrote a follow up [post](http://blog.fmpwizard.com/blog/using-voice-recognition-and-an-ultrasonic-sensor) where I added voice recording capabilities.


**Cortex** is a service written in the [Go language](http://golang.org) that listens for regular sentences and tries to convert them into commands to execute. And in the near future, it will also give you relevant answers.

![Cortex](/images/arduino-1.jpg)

## Internals

Cortex understands what you asked by using [Wit.ai](http://wit.ai) to process the incoming sentence. Wit returns  an [intent](https://wit.ai/docs/intro#toc_5) with some [entities](https://wit.ai/docs/intro#toc_9), and then Cortex executes a service based on that information.

This is a sample json response:

```
curl \
>   -H 'Authorization: Bearer <access token key here>' \
>   'https://api.wit.ai/message?q=Turn%20light%206%20on'
{
  "msg_id" : "39ead2b0-f862-4285-bdd6-46941125fcf5",
  "msg_body" : "Turn light 6 on",
  "outcome" : {
    "intent" : "lights",
    "entities" : {
      "number" : {
        "end" : 12,
        "start" : 11,
        "value" : 6,
        "body" : "6"
      },
      "on_off" : {
        "value" : "on"
      }
    },
    "confidence" : 0.764
  }
}
```

Looks pretty easy to understand, right now I have a Wit instance that knows about an intent called `Lights`. The idea behind this intent is to allow me to say `Turn the light 5 on` and have Cortex send a command to an arduino board so that the LED number 5 turns on. From the json response I parse the `intent`, in this case I have two entities, one is a `number entity` with value `6` and then I have the `on_off` entity with the value `on`. You also see a `confidence` value, I have given Wit a lot of different sentences to parse, so it feels pretty confident right now :)

![Cortex](/images/arduino-2.jpg)

## Taking action.

Once Cortex gets the parsed data, we do a match on the intent value and then select the service to call.

```
func ProcessIntent(jsonResponse services.WitMessage) string {
	switch jsonResponse.Outcome.Intent {
	case "lights":
		light := jsonResponse.Outcome.Entities.Number.Value
		action := jsonResponse.Outcome.Entities.OnOff.Value
		services.Arduino(action, light)
		return fmt.Sprintf("Turning light %v %s", light, action)
	}
	return ""
}

```

You can see the go side of sending a command to the Arduino connected using USB on [github](https://github.com/fmpwizard/go-cortex/blob/master/services/arduino.go)

That whole file implements the binary protocol (very simple one) and translates the action from `on` to `u` and `off` to `d`. (For `up` and `down`). there are plenty of comments on that file that explain what each function does.

And in the end, the LED number 6 turns on.

![Cortex](/images/arduino-3.jpg)

## Why Wit?

Some of you may think *"I could do that with regular expressions"* or *"I would use xyz"*. The beauty of using Wit comes when you don't have to think ahead of time all the different ways in which a user may want to express their intention. You can say something like *On Monday the light 5 should really be off* and Wit knows that the entity `on_off` should have the value `off` (I just tried it to make sure and it works). And I didn't have to do any programming for this case (note tha word on in there, but Wit did not get confused by it.).

Using Wit makes for a more natural way of interacting with devices. And it learns as you use it. Each new message that Wit gets, goes to what they call your "Inbox", and there you can either correct Wit when it parsed something wrong, or validate the ones it got right.

![Cortex](/images/arduino-4.jpg)

## Arduino

You can find the complete code for arduino on the [go-cortex repo](https://github.com/fmpwizard/go-cortex/blob/master/arduino/) ( you will need both files from that directory).

The Arduino wiring is pretty simple, if you use the same code I posted:

```
int led1 = 7;
int led2 = 4;
int led3 = 13;
int led4 = 11;
int led5 = 8;
int led6 = 2;
```

Just connect those pins to and LED (remember to use a resistor between the positive and the LED) and then connect them all to ground on your breadboard and you should be good to go.

## Raspberry Pi
I'm running `Cortex` on a raspberry pi at home, you can access it at [http://fmpwizard.no-ip.org:8080/?q=turn+light+2+on](http://fmpwizard.no-ip.org:8080/?q=turn+light+2+on) , feel free to change the sentence to something else, remember that I only have lights from 1 to 6. If you would like to replicate this, take a look at the [README.md](https://github.com/fmpwizard/go-cortex/blob/master/README.md) file which has more details on the setup and leave a comment if you need some help.

## Go
Using Go for this has been great. Having a solid standard library means that to make http requests to the Wit service I simply do (everyone uses the same api, you don't have to pick one vs another):


	url := "https://api.wit.ai/message?q=" + url.QueryEscape(str)
	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", witAccessToken))
	res, err := client.Do(req)
	...

Need to serialize json string into Go structs? no problem:

    var jsonResponse WitMessage
	err = json.Unmarshal(intent, &jsonResponse)
	if err != nil {
		log.Println("error parsing json: ", err)
	}

`intent` is a byte array from the GET request that contains the json response, `json.Unmarshal` fits that into the `jsonResponse` variable based on a chain of structs that represent the structure of the json response. Sounds a lot more complex than looking at the actual code, so here, take a [look](https://github.com/fmpwizard/go-cortex/blob/master/services/wit.go)

Oh, at the first version of Cortex was a command line program, that accepted sentences as a command argument, to change that into a web service I added these lines:

    func main() {
	    flag.Parse()
	    http.HandleFunc("/", handler)
	    http.ListenAndServe(fmt.Sprintf(":%v", httpPort), nil)
    }

    func handler(w http.ResponseWriter, r *http.Request) {
	    //read the "q" GET query parameter and pass it to
	    // the wit service
	    message := r.FormValue("q")
	    if len(message) > 0 {
		    ret := ProcessIntent(services.FetchIntent(message))
		    //print what we understood from your request to the browser.
		    fmt.Fprintf(w, ret)
	    } else {
		    fmt.Fprintf(w, "Please add a ?q=<text here> to the url")
	    }
    }

And now we are using the same web server code that [dl.google.com uses - take a look at this presentation](http://talks.golang.org/2013/oscon-dl.slide#1)

Go is a simple language, easy to learn, with a standard library that has pretty much everything you need (for most cases). It runs fast, compiles fast (0.6 seconds on my regular laptop, 16 seconds on a raspberry pi) And it starts up in less than a second.

# Final thoughts.

Open an account with [Wit](https://wit.ai/) and try [Go!](http://golang.org)

# Source Code

All the code is on [github](https://github.com/fmpwizard/go-cortex). Feel free to leave a comment/question.

>Thanks

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
