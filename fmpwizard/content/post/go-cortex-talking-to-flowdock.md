+++
date = "2014-04-23T21:49:57-07:00"
title = "Go Cortex - talking to Flowdock"
aliases = [
	"/blog/go-cortex-talking-to-flowdock"
]
+++

[title=]: /
[category: go]: /
[date: 2014/04/23]: /
[tags: { go, golang, wit, machine learning, raspberrypi, cortex, IoT, flowdock}]: /


#Go Cortex - talking to Flowdock

While on one side Go-Cortex let's me control an Arduino using [voice recognition](http://blog.fmpwizard.com/blog/voice-command-for-arduino-and-raspberry-pi-using-sms), I also wanted to expand Cortex into helping me and my team at [Brokc Alloy](http://brickalloy.com/). we currently use flowdock for internal conversations and there were two things that I wasn't too happy about:

 1. There were times when people would say the current temperature where they live, and that meant I had to go and convert them from Celsius to Fahrenheit.

 2. The other case was that someone would say "Look at #44 and see if you can fix it", referring to a github issue. Again, I would had to go to the github page and add that issue number to a url, etc.

While they are not terrible things, over time it gets old and I really wanted to experiment more with Go.

##Talking to Flowdock.

I'm using the the flowdock [streaming api](https://www.flowdock.com/api/streaming) to listen for messages posted to our flows. I wrote about [consuming a streaming api using go before](http://blog.fmpwizard.com/blog/http-streaming-using-go) .

The basic idea is:

 1. A message comes in.
 2. Send it to Wit.ai to get the intent and some metadata
 3. If it is a temperature intent:
     1. I convert the temperature from C to F or viceversa.
     2. And post it as a reply to the original message.
 2. If it is a github intent
     1. I get the issue number
     2. Read some config data to see which project we are using on this flow
     3. And post a reply with the link to the issue.

The complete logic is on [flowdock.go](https://github.com/fmpwizard/go-cortex/blob/v0.4.0/flowdock.go).

On previus versions of Cortex I was using command line flags to get configuration data, when I added the flowdock integration I moved to reading a json file for configuration. This is a sample  cortex.config.json file:

```
{
  "httpPort": "7070",
  "flowdockAccessToken": "token here",
  "witAccessToken" : "token here",
  "flows": "fmpwizard/mission-control,fmpwizard/another-flow-here",
  "flowsTicketsUrls" : [
    {"mission-control":  "https://github.com/fmpwizard/go-cortex/issues/"}
  ]
}
```

Note how this example tells cortex to listen on two different flows, and it knows about the  github url of one of those flows.

Parsing the json file and loading that into a struct was dead simple, from the [main.go](https://github.com/fmpwizard/go-cortex/blob/v0.4.0/main.go) file you can see:

```
func readCortexConfig() {
	configBytes, error := ioutil.ReadFile(configFile)
	if error != nil {
		log.Fatalf("Could not read config file, error: %+v", error)
	}
	error = json.Unmarshal(configBytes, &config)
	if error != nil {
		log.Fatalf("Could not parse json file, got: %+v", error)
	}
	log.Printf("Using configuration: %+v", config)
}

type CortexConfig struct {
	HttpPort            string
	FlowdockAccessToken string
	WitAccessToken      string
	Flows               string
	FlowsTicketsUrls    []map[string]string
}
```

##In action.

Here is what it looks like:

![Flowdock integration](/images/cortex-flowdock-integration.png)


## Code.

I just pushed a tag to keep track of these changes, this is at [v0.4.0 ](https://github.com/fmpwizard/go-cortex/tree/v0.4.0).

##Final notes.

Wit recently added an [Explore](https://wit.ai/blog/2014/04/17/explore-explore) feature which in the near future will allow you to do something analogous to forking my instance. This means you can take the training data I have used for my cortex instance and train your own instance.

There are still some cases where cortex would not classify certain messages the right way, but as time goes by, I get more and more training data and things get better every day.


>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
