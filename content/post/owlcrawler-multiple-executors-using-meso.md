+++
date = "2015-03-01T21:49:57-07:00"
title = "OwlCrawler - Multiple executors using Mesos"
aliases = [
	"/blog/owlcrawler-multiple-executors-using-meso"
]
+++


[title=]: /
[category: Go]: /
[date: 2015/03/1]: /
[tags: {go, golang, mesos, mesos-go, distributed, async}]: /



# OwlCrawler - Multiple Executors per Scheduler using Mesos

As I continue working on [OwlCrawler](https://github.com/fmpwizard/owlcrawler), I have refactored the code a lot. After getting some great feedback on the Mesos mailing list, I went ahead and split the single executor into two separate `Executors` that are triggered by the main `Scheduler`.

On the scheduler, I now have these two `ExecutorInfo` entries:

```
fetcherExe := &mesos.ExecutorInfo{
	ExecutorId: util.NewExecutorID("owl-cralwer-fetcher"),
	Name:       proto.String("OwlCralwer Fetcher"),
	Source:     proto.String("owl-cralwer"),
	Command: &mesos.CommandInfo{
		Value: proto.String(fetcherExecutorCommand),
		Uris:  executorUris,
	},
}

extractorExe := &mesos.ExecutorInfo{
	ExecutorId: util.NewExecutorID("owl-cralwer-extractor"),
	Name:       proto.String("OwlCralwer Fetcher"),
	Source:     proto.String("owl-cralwer"),
	Command: &mesos.CommandInfo{
		Value: proto.String(extractorExecutorCommand),
		Uris:  executorUris,
	},
}
```
And inside `ResourceOffers` I use the `Executor's ID` to decide which executor is getting a task:

```
if sched.executor.GetExecutorId().GetValue() == "owl-cralwer-fetcher" {
	if ok, task := fetchTask(URLToFetchQueue, sched, offer.SlaveId); ok {
		tasks = append(tasks, task)
		remainingCpus -= cpuPerTask
		remainingMems -= memPerTask
	}
} else if sched.executor.GetExecutorId().GetValue() == "owl-cralwer-extractor" {
	if ok, task := extractTask(HTMLToParseQueue, sched, offer.SlaveId); ok {
		tasks = append(tasks, task)
		remainingCpus -= cpuPerTask
		remainingMems -= memPerTask
	}
}
```

This meant having two scheduler drivers in the same scheduler, but to start the driver, you call `driver.Run()` which blocks until the driver is shutdown. To work around the issue where I could only have one blocking driver, I used the same pattern you can use when you serve `http` and `https` handlers in Go, you start one on a goroutine and just block on the second one:

```
func main() {
	// build command executor
	exec := prepareExecutorInfo()
	go startSchedulerDriver(exec[0])
	startSchedulerDriver(exec[1])
}
```

## Goroutines.
Something else I found out is that you are not supposed to block doing your work on the `LaunchTask` function in the executor. So I moved most of the work into its own function:

```
func (exec *exampleExecutor) extractText(driver exec.ExecutorDriver, taskInfo *mesos.TaskInfo) {
	//Read information about this URL we are about to process
	...
	queue := mq.New(queueMessage.QueueName)
	...
	doc, err := getStoredHTMLForURL(queueMessage.URL)
	if err != nil {
		queue.DeleteMessage(queueMessage.ID)
	} else {
		err = saveExtractedData(extractData(doc))
		if err == cloudant.ERROR_NO_LATEST_VERSION {
			doc, err = getStoredHTMLForURL(queueMessage.URL)
			if err != nil {
				log.Errorf("Failed to get latest version of %s\n", queueMessage.URL)
				queue.DeleteMessage(queueMessage.ID)
				return
			}
			saveExtractedData(extractData(doc))
		} else if err != nil {
			_ = queue.DeleteMessage(queueMessage.ID)
			runStatus := &mesos.TaskStatus{
				TaskId: taskInfo.GetTaskId(),
				State:  mesos.TaskState_TASK_FAILED.Enum(),
			}
			_, err := driver.SendStatusUpdate(runStatus)
			if err != nil {
				log.Errorf("Failed to tell mesos that we died, sorry, got: %v", err)
			}
		}
	}
	// finish task
	finStatus := &mesos.TaskStatus{
		TaskId: taskInfo.GetTaskId(),
		State:  mesos.TaskState_TASK_FINISHED.Enum(),
	}
	_, err = driver.SendStatusUpdate(finStatus)
	if err != nil {
		log.Errorln("Got error", err)
	}
	log.V(2).Infof("Task finished %s\n", taskInfo.GetName())
}

```

Now I simply call `go exec.extractText(driver, taskInfo)`  from `LaunchTask` in the executor.

## New features.

The first version used to fetch the html and save it in CouchDB. The current version runs another executor that extracts structured text from the page and saves it to the database. I also extract and save all outgoing links.

To store the structured text I use this struct:

```

type PageStructure struct {
	Title string   `json:"title,omitempty"`
	H1    []string `json:"h1,omitempty"`
	H2    []string `json:"h2,omitempty"`
	H3    []string `json:"h3,omitempty"`
	H4    []string `json:"h4,omitempty"`
	Text  []string `json:"text,omitempty"`
}
```

This is a sample document stored in CouchDB:

```
{
    "_id": "aHR0cDovL2RyaGF5bGV5YmF1bWFuLmNvbS9zZXJlbmRpcGl0eV9hbmRfdGhlX3NlYXJjaF9mb3JfdHJ1ZV9zZWxmLmh0bWw=",
    "_rev": "27-728ef0b7a325e8b376f6dbc374c82c38",
    "url": "http://drhayleybauman.com/serendipity_and_the_search_for_true_self.html",
    "html": "<!DOCTYPE html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"utf-8\">\n    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n     <!-- omitted for this blog post -->  </body>\n</html>\n",
    "text": {
        "title": "Psychologist in Ashevillem NC - Serendipity and the Search for True Self - Dr Hayley Bauman",
        "h1": [
            "Hayley J. Bauman, Psy.D"
        ],
        "h2": [
            "Licensed Psychologist"
        ],
        "h3": [
            "Serendipity and the Search for True Self"
        ],
        "text": [
            "head",
            "Toggle navigation",
            "a",
            "Home",
            "a",
            "Education and Training",
            "a",
            "Frequently Asked Questions",
            "a",
            "Helpful Resources",
            "a",
            "Getting Started",
            "a",
            "Serendpity and the Search for True Self",
            "a",
            "Contact",
            "\"The right way to wholeness is full of detours and supposed wrong turns.\"",
            "Carl Jung",
            "strong",
            "Serendipity and the Search for True Self",
            "Believing that all paths lead to the same place, Dr. Bauman weaves seemingly distant topics like dreams, forgiveness, body-awareness, and critical inner voices into tools for connecting to your core. In her nonjudgmental way, Dr. Bauman teaches us to respect and value all parts of ourselves as she believes that \"Every single energy inside of us is necessary, useful, and capable of complementing one another. The key is knowing when, where, and how to integrate our different parts so that we feel whole.\"",
            "strong",
            "Serendipity and the Search for True Self",
            "a",
            "Buy from Amazon",
            "\n  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');\n\n  ga('create', 'UA-368436-5', 'auto');\n  ga('send', 'pageview');\n\n"
        ]
    },
    "links": [
        "http://drhayleybauman.com/",
        "http://drhayleybauman.com/educationandtraining.html",
        "http://drhayleybauman.com/frequentlyaskedquestions.html",
        "http://drhayleybauman.com/psychologyresources.html",
        "http://drhayleybauman.com/gettingstarted.html",
        "http://drhayleybauman.com/serendipity_and_the_search_for_true_self.html",
        "http://drhayleybauman.com/contact.html",
        "http://www.amazon.com/Serendipity-Search-Psy-D-Hayley-Bauman/dp/1607027674"
    ]
}
```

Storing the extracted text separated by tags will let me give tags like the `Title` higher ranking than the text from the rest of the page. I'll be adding [ElasticSearch](http://www.elasticsearch.org/) to  OwlCrawler in the near future.

### Extracting text from specific tags.

This is the code I'm using now to extract the text from the few tags I care about:

```
func ExtractText(payload string) PageStructure {
	var page PageStructure
	d := html.NewTokenizer(strings.NewReader(payload))
	var tok atom.Atom
Loop:
	for {
		tokenType := d.Next()
		if tokenType == html.ErrorToken {
			break Loop
		}
		token := d.Token()
		switch tokenType {
		case html.StartTagToken:
			if token.DataAtom == atom.Title {
				tok = atom.Title
			} else if token.DataAtom == atom.H1 {
				tok = atom.H1
			} else if token.DataAtom == atom.H2 {
				tok = atom.H2
			} else if token.DataAtom == atom.H3 {
				tok = atom.H3
			} else if token.DataAtom == atom.H4 {
				tok = atom.H4
			} else {
				tok = 0
			}
		case html.EndTagToken:
			tok = 0
		case html.TextToken:
			if txt := strings.TrimSpace(token.Data); len(txt) > 0 && tok == atom.Title {
				page.Title = txt
			} else if txt := strings.TrimSpace(token.Data); len(txt) > 0 && tok == atom.H1 {
				page.H1 = append(page.H1, txt)
			} else if txt := strings.TrimSpace(token.Data); len(txt) > 0 && tok == atom.H2 {
				page.H2 = append(page.H2, txt)
			} else if txt := strings.TrimSpace(token.Data); len(txt) > 0 && tok == atom.H3 {
				page.H3 = append(page.H3, txt)
			} else if txt := strings.TrimSpace(token.Data); len(txt) > 0 && tok == atom.H4 {
				page.H4 = append(page.H4, txt)
			} else if txt := strings.TrimSpace(token.Data); len(txt) > 0 {
				page.Text = append(page.Text, txt)
			}
		}
	}
	return page
}

```

Maybe there are better ways to do this, but basically I walk the tree and when I find an opening tag, I set `tok` to the type of tag I just found, on the next run of the loop, it may find either a closing tag or a text token, if it is a text token, I look up which tag we are in, and then save the text into the member variable of `page`. Once I find a closing tag, I reset my flag so I don't get extra text in the wrong place.

So far I'm doing my tests by crawling my blog site. Soon I should be able to start testing other sites and see what errors I run into.

These are most of the high level changes since my previous post.

## Code.
The project is in the same place, hosted on [github](https://github.com/fmpwizard/owlcrawler)


>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
