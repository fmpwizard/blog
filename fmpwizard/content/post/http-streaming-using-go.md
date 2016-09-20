+++
date = "2014-04-04T21:49:57-07:00"
title = "HTTP Streaming Using Go"
aliases = [
	"/blog/http-streaming-using-go"
]
+++

[title=]: /
[category: go]: /
[date: 2014/04/04]: /
[tags: { go, golang, cortex, http, streaming}]: /

# HTTP Streaming Using Go

As I continue adding features to [Cortex](https://github.com/fmpwizard/go-cortex) I needed to connect to the streaming api that Flowdock provides.

A quick Google search took me to this [post](http://dmathieu.com/articles/development/golang-streaming/) which shows how to do that. It works, but while I was reading the code, it looked pretty low level for my taste. So I decided to try and use the [http](http://golang.org/pkg/net/http/) package.

## Making the initial request


    url := "https://stream.flowdock.com/flows?filter=fmpwizard/mission-control"
    token := []byte(flowdockAccessToken) //used by Flowdock
    str := base64.StdEncoding.EncodeToString(token) //used by Flowdock
    req, _ := http.NewRequest("GET", url, nil) // This will be a GET request
    req.Header.Add("Authorization", fmt.Sprintf("Basic %s", str)) //Add the base64 encoded token
    client := &http.Client{}
    res, err := client.Do(req) // Do the actual HTTP GET request

    if err != nil {
        log.Panic(err)
    }
	defer res.Body.Close() //Close the body once we are done.

So far this looks like any other `GET` request that needs some specific header to be added. What is different when dealing with a stream is how you read the partial body.

## Reading the body, line by line.

    for {
		line, _ := reader.ReadBytes('\r') // we read until the carriage return, this may be diff on other streaming apis
		line = bytes.TrimSpace(line)
		jsonString := string(line[:])
		log.Printf("String: %v\n\n", jsonString)
		... //Do anything you want to with the line you just got, in my case I parse the json data
		    //into some struct and then I send it to [wit.ai](http://wit.ai)
	}


And that's it, pretty simple.


>Thank you for reading.

>Diego [@fmpwizard](https://twitter.com/fmpwizard)
