+++
date = "2016-09-30T21:49:57-07:00"
title = "Automatic TLS certificates for your Go application"
tags = ["go", "golang", "ssl", "tls"]
+++

I have enjoyed automatic ssl/tls certificates from [Let's Encrypt](https://letsencrypt.org/) thanks to [caddy server](https://caddyserver.com/) for several months already. But a couple of weeks ago I started a new side project, where I needed to run a web application that would listen for incoming requests from the [nexmo](https://www.nexmo.com/) servers.

This was a great opportunity to try one of the many let's encrypt/acme clients in Go. I originally used [rsc.io/letsencrypt](https://godoc.org/rsc.io/letsencrypt) and that same evening while reading Twitter, I saw that [bradfitz](https://github.com/bradfitz) [proposed adding autocert to Go 1.8](https://github.com/golang/go/issues/17053).

I wasn't completely happy with rsc's library because it had an old vendored library in it and I got the impression that it was a one off project not actively maintained, so I decided to try autocert and see how far I would get.

### Like most things in Go, it turned out to be pretty easy to integrate.

	m := autocert.Manager{
		Prompt:     autocert.AcceptTOS,
		HostPolicy: autocert.HostWhitelist(config.HostNames...),
		Cache:      autocert.DirCache(config.LECacheFilePath),
		Email:      config.LEEmail,
	}
	s := &http.Server{
		Addr:      ":https",
		TLSConfig: &tls.Config{GetCertificate: m.GetCertificate},
	}
	log.Println("Running on port: 443")
	s.ListenAndServeTLS("", "")


### Let's break this down:

	m := autocert.Manager{
		Prompt:     autocert.AcceptTOS,
		HostPolicy: autocert.HostWhitelist(config.HostNames...),
		Cache:      autocert.DirCache(config.LECacheFilePath),
		Email:      config.LEEmail,
	}

You first define a manager, supply a function that will accept the terms of service, a list of domains you are planning on hosting. How to cache the certificates, by default autocert provides a directory based cache, which works well for single server, so this is what I'm using, and finally supply your email address, which will be used by let's encrypt to notify you of any issues.

	s := &http.Server{
		Addr:      ":https",
		TLSConfig: &tls.Config{GetCertificate: m.GetCertificate},
	}

Here we defined a `Server` that will listen on the https port and we tell it how we'll get certificates.

	s.ListenAndServeTLS("", "")

Finally we start the server.

### Getting the actual certificates.

The first time you point your browser to your server, it will request a certificate, save a copy to a predefined path where only your application has access to, and then move on to serve your site. In my initial setup (arm7 server), it took just 3 seconds to do all this.
This library will also take care of updating/renewing the certificate about a week before it expires!

### Security concerns

A few months ago I had a brief conversation with a co-worker where he was concerned about giving root access to the let's encrypt client. This issue doesn't apply to Go applications because:

1. Your app doesn't have to run as root in Linux, you can run it as a regular user that isn't even in the wheel group by executing:

		setcap cap_net_bind_service=+ep </path/to/binary>

2. You can set the permissions for the cert path so that nobody else has access to them and the library creates the file with 0600 automatically
3. If you run under Fedora or any other distribution that uses SELinux, you can restrict your application in a way that it can't even sneeze the wrong way :)

That's all!

### Code

I mentioned that I was working on a side project, the repo with this code and other things is [here](https://github.com/fmpwizard/mrwilson)

>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
