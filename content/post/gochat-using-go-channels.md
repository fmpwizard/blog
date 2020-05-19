+++
date = "2014-01-05T21:49:57-07:00"
title = "GoChat - Using Go Channels"
aliases = [
	"/blog/gochat-using-go-channels",
	"/gochat-using-go-channels"
]
+++

[title= ]: /
[category: go]: /
[date: 2014/1/5]: /
[tags: {go, golang}]: /


# GoChat - Using Go Channels

A couple of weeks ago I [wrote](http://blog.fmpwizard.com/blog/twitter-flight-and-go) about using Go with Twitter Flight to write web applications.

But I didn't put too much emphasis on the go code, it was mostly to highlight some patterns which I think can be applied to any web application.

This post is more about the go code.

## Using Go channels.

One of the main features I like from Go is that it has concurrency solutions built into the language itself. Go offers goroutines and channels. In a nutshell, **goroutines** can spawn tasks to run in the background, they are light weight, so you can safely have thousands of them and not have to worry about overhead, etc. **Go Channels** are a type-safe way to communicate. If you are used to the **Actor model**, think of channels as an actor, but they have types, so if you declare a channel to handle `Strings`, it will only work with strings, which is great.

There is plenty of good documentation about Go's concurrency features, you may want to visit the [Go tour](http://tour.golang.org/#64) to take a look. And the other day I found this other [blog post](http://golangtutorials.blogspot.com/2011/06/channels-in-go-range-and-select.html) that was helpful too.

### Some code.

The first version of the simple chat application I wrote had a top level `var` that was a `map` of `Message`s. This was fine at the time because I wasn't too focused on the go code. But a better way to handle this is to use `go channels`.

First, I defined some `structs`, which are similar to `case classes` from Scala.

```
//This struct hold each message, the `json:"id"` part tells Go to use a lowercase name when serializing to json
type Message struct {
  Id        string `json:"id"`
  Body      string `json:"body"`
  CreatedOn int64  `json:"createdOn"`
}

//This is our map of messages
type ChatMessageResource struct {
  messages map[string]Message
}

//This is the struct that we will send out go channel
type MessageStore struct {
  chatMessages *ChatMessageResource
  msg          Message
}

//This is how you initialize a go channel, pretty simple.
//The * before `MessageStore` means that the channel gets a pointer to a MessageStore, not the actual value.
var messagesChan = make(chan *MessageStore)

```


### Using the channel

To do something with the channel, you need to define a function that will listen for new messages.

```
// handleAddMessage reads the payload channel and adds a new entry to
// the chat messages map as they become available.
func handleAddMessage(payload chan *MessageStore) {
  for msg := range payload {
    msg.chatMessages.messages[msg.msg.Id] = msg.msg
  }
}
```

In case the syntax doesn't look clear, the `msg` variable is assigned the first value received on the `payload` channel, and then we add an entry to our map of messages. Because we are using `range`, this function keep listening for new messages that will come to the channel, until we shut down the app.

Because this function will block waiting for new messages, we use a goroutine to run it, which in code simply means:

`go handleAddMessage(messagesChan)`

By adding the `go` keyword in front of a function, that function will end up running on the background. This is like [Lift](http://www.liftweb.net)'s `Schedule.schedule()`.

And finally, we handle the http requests that have a new chat message with this function:

```
func (chatMessages *ChatMessageResource) createChatMessage(request *restful.Request, response *restful.Response) {
  //Generate a guid
  guid, err := uuid.NewV4()
  if err != nil {
    fmt.Println("error:", err)
    return
  }
  //we create a partial message value, with the id we just generated a couple of lines above
  msg := Message{Id: guid.String()}
  //`ReadEntity` reads the json payload from the http request, and tries to parse it using
  //the msg vaue (which is a Struct of type Message)
  parseErr := request.ReadEntity(&msg)
  if parseErr == nil {
    //If no errors, we send the payload to the channel `messagesChan`
    messagesChan <- &MessageStore{chatMessages, msg}
    //The response to a create request is the id of the new message
    ret := map[string]string{"id": guid.String()}
    //with a sttus code of 201
    response.WriteHeader(http.StatusCreated)
    response.WriteEntity(ret)
  } else {
    response.AddHeader("Content-Type", "text/plain")
    response.WriteErrorString(http.StatusInternalServerError, parseErr.Error())
  }
}
```

Just to highlight it, you send new values to a channel with a syntax like:

`messagesChan <- &MessageStore{chatMessages, msg}`

`messagesChan` is our channel, the `<-` tells go that the value from the right goes towards the channel on the left.


That's it for this post, you can find the complete source code on my [go-examples](https://github.com/fmpwizard/go-examples/tree/gochat) repository, under the **gochat** branch.

>Thanks for feel free to leave comments.
>>Diego
