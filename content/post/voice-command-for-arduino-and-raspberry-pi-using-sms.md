+++
date = "2014-03-29T21:49:57-07:00"
title = "Voice command for Arduino and Raspberry Pi using SMS"
aliases = [
	"/blog/voice-command-for-arduino-and-raspberry-pi-using-sms"
]
+++

[title=Voice command for Arduino and Raspberry Pi using SMS]: /
[category: go]: /
[date: 2014/03/29]: /
[tags: { go, golang, wit, machine learning, arduino, raspberrypi, cortex, sms, text message}]: /


# Voice command for Arduino and Raspberry Pi using SMS and Google Now.

A couple of weeks ago I went ahead and bought the [Wolfson sound card](http://www.element14.com/community/community/raspberry-pi/raspberry-pi-accessories/wolfson_pi) for the raspberry pi. I was hoping to integrate it into Cortex to improve the [voice recognition setup](http://blog.fmpwizard.com/blog/using-voice-recognition-and-an-ultrasonic-sensor) I had.

This turned out not to work so well. The card has two built in microphones, but I had to be really close to the board to get a good quality recording. And even after applying some noise removal, the service I was using for voice recognition wasn't getting what I was saying (at least not all the time).

## SMS to the rescue.

Looking for alternatives, I went ahead and opened an account with [nexmo.com](https://www.nexmo.com/). They give you a US number you can send text messages to, and they go and send those to a URL callback you provide.

This was a perfect alternative for me. I can now use my Moto X and Google Now to send a text to my nexmo number, nexmo processes this text message and sends a request to my raspberry pi running cortex, which in turn sends the text message content to [Wit.ai](https://wit.ai/) and once the Wit service parses the important data from the message, it gives cortex enough information to send the right command to an Arduino board.

See this diagram for a clear picture of the workflow:

![workflow](/images/cortex-sms-1.png)

*diagram made using [sketchboard.me](https://sketchboard.me)

## API.

The Nexmo API to receive message is just dead simple to use. All you have to do is have a public url that can receive `GET` requests and returns an `OK 200` response.

The Go code I had to add was:

```
//Add a handler for the /sms path
func init() {
	http.HandleFunc("/sms", handler)
}

//Handle the GET requests from nexmo
func handler(w http.ResponseWriter, r *http.Request) {
	//A sample request from the nexmo service is
	//?msisdn=19150000001&to=12108054321
	//&messageId=000000FFFB0356D1&text=This+is+an+inbound+message
	//&type=text&message-timestamp=2012-08-19+20%3A38%3A23
	//So we read all those parameters
	messageId := r.FormValue("messageId")
	text := r.FormValue("text")
	typ := r.FormValue("type")
	timestamp := r.FormValue("message-timestamp=")
	if len(text) > 0 && typ == "text" {
		ret := ProcessIntent(FetchIntent(text))
		log.Printf("We got messageId: %v on %v ", messageId, timestamp)
		log.Printf("Wit gave us: %+v ", ret)
	} else {
		log.Print("Error: we got a blank text message")
	}
	w.WriteHeader(http.StatusOK)
}
```

## Demo

Here is a short video where I use Google now to send text messages to Cortex and in return it turns lights on or off after Wit.ai processes each message. Note how the process is fairly fast, considering it goes from my cellphone to the Nexmo number. Nexmo uses my callback url running on the rasbperry pi, it then sends that text content to Wit and then we parse the json from Wit and tell the Arduino board what to do.

<p>
<iframe width="560" height="315" src="//www.youtube.com/embed/dwVUE8kWNLQ?rel=0" frameborder="0" allowfullscreen></iframe>
</p>

## Code

Cortex is hosted on [github](https://github.com/fmpwizard/go-cortex), as always, feel free to leave a comment or get in contact using any network you happen to find me in.

## Final notes.

I think that this is a good enough setup to start building more useful things on top of. The Google voice recognition on my phone is used to my voice and is pretty accurate by now. Nexmo's API to receive messages is very simple to use and it is also very fast. I have trained my Wit instance pretty well and I really like the json response they provide and using Go for this project has been a great choice. It is a lightweight language that runs just fine on a multicore server as well as on a tiny ARM computer, the standard library gives me all I need, http client and server, plus communication using USB port.

>Thank you for reading.

>Diego [@fmpwizard](https://twitter.com/fmpwizard)
