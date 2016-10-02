+++
date = "2016-10-01T21:49:57-07:00"
title = "Restricting your Go application with SELinux"
tags = ["go", "golang", "selinux", "fedora", "linux"]
+++

For years I have been just a passive users of [SELinux](http://selinuxproject.org/page/Main_Page), in the early days using it in Fedora, I would disable it because there were too many applications that didn't work with it, I knew it was wrong, but didn't have the knowledge nor the time to really look into the right way to deal with it.

Over the years Fedora added a huge number of policies to the point that 99% of the apps I use work just fine with SELinux enabled, and whenever I would get one of those denied warnings, I just followed the wizard-like-troubleshooting to update a policy and move on.

	ausearch -c '<some name here>' --raw | audit2allow -M <name-here-too>
	semodule -i <custom-policy-name-here>.pp

I only run into those few cases when I would move an install of my database to a separate partition, at the time I figure it was an easy fix, but about a month or two ago I learned there was a better way.

## SELinux policies, labels and custom types.

The time came that I needed to write a custom SELinux policy for an app that I was working on. And I didn't want to just use the shortcut of using `audit2allow`, I wanted to do it right.

I searched high and low gathering information on how to do this, most of what I found was targeted to administrators who did things like moving nginx to a non standard location. But in my case I needed to write a new set of rules for my new program.

I was about to give up when I decided to post this question: [how to create a custom SELinux label](http://unix.stackexchange.com/questions/309122/how-to-create-a-custom-selinux-label).

At that point I thought what I needed was a custom label, later on I learned I needed a custom type. And of course, after posting the question, I couldn't just sit and wait, so I kept on searching for the answer and eventually I found it.

## Requirements of my Go application.

[Mr Wilson](https://github.com/fmpwizard/mrwilson), the project I'm working on, is a simple http(s) service. The key features that SELinux cares about are:

1. Listens on port 443, 80 and 1212 on dev mode
2. Reads/Writes a file on `$HOME`
3. Uses dns to lookup hosts
4. Reads/Writes files to its own location, by default, `/srv/bot`

## Writing the actual policy.

You can get many of the permissions your app needs by running:

	sepolgen --init  /path/to/binary

That command will generate these files:

	app.fc
	app.sh
	app.if
	app.spec
	app.te

Unless you are creating an rpm, you can delete `app.spec` and ` app.sh`.

Let's start with the `app.te` file:

	policy_module(mrwilson, 1.0.0)

	########################################
	#
	# Declarations
	#

	type mrwilson_t;
	type mrwilson_exec_t;
	init_daemon_domain(mrwilson_t, mrwilson_exec_t)

	# Please remove this once your policy works as expected.
	permissive mrwilson_t;

	########################################
	#
	# mrwilson local policy
	#
	allow mrwilson_t self:fifo_file rw_fifo_file_perms;
	allow mrwilson_t self:unix_stream_socket create_stream_socket_perms;

	domain_use_interactive_fds(mrwilson_t)
	files_read_etc_files(mrwilson_t)
	auth_use_nsswitch(mrwilson_t)
	miscfiles_read_localization(mrwilson_t)
	sysnet_dns_name_resolve(mrwilson_t)



### Details of the Type Enforcement file.

	policy_module(mrwilson, 1.0.0)

This uses the name of the binary, which will be the name of the policy too, and a version.

	type mrwilson_t;
	type mrwilson_exec_t;
	init_daemon_domain(mrwilson_t, mrwilson_exec_t)

Here we defined the types `mrwilson_t` and `mrwilson_exec_t`, you can think of these as contexts that your application/daemon or service is allowed to work within.

* `mrwilson_exec_t` tells SELinux that we'll be **executing** this file.
* `mrwilson_t` is the unique type to describe this application.
* `init_daemon_domain` is a macro that among other things, tells SELinux that this program will run as a service (using systemd in my case).


`permissive mrwilson_t;`

This line tells SELinux to log permission errors, but let the application continue to run. When I originally worked with my program to find all the permissions it needed, I went the long way and removed this line from the start, so my application kept failing to run each time I run it, up to you which way you prefer. Regardless, **remember to remove this line when you are done.**

	files_read_etc_files(mrwilson_t)
	miscfiles_read_localization

I actually removed these two lines from my policy, because my app does not need to read anything from `/etc` and doesn't have any localization code.

	sysnet_dns_name_resolve(mrwilson_t)

I do need to connect to DNS servers so I left this one in.

### Adding rules to your Type Enforcement file.

This gave me a good starting point, but I still needed to add lots of rules that are specific to my go application.

I originally said I would run this program from `/srv/bot`, and because I was going to store files in there, I wanted to have a file context that was just for my app, instead of using the generic `file_var_t`.

So right under `init_daemon_domain`, I added:

	type mrwilson_var_t;
	files_type(mrwilson_var_t)

`files_type` takes the type we defined and makes it a file context, which is what we need.

### Assigning file contexts.

When you write a policy, you can tell SELinux where you expect to store/read files from, and you can tell it which context each path is supposed to have.

This is done using the `app.fc` file.

The default `app.fc` has one line:

	/path/to/binary		--	gen_context(system_u:object_r:mrwilson_exec_t,s0)

You need to update the path to match the path your executable file will have once deployed.

I also wanted to give `/srv/bot` the `mrwilson_var_t` context instead of the default `file_var_t`:

	/srv/bot/mrwilson		--	gen_context(system_u:object_r:mrwilson_exec_t,s0)
	/srv/bot(/.*)?      	gen_context(system_u:object_r:mrwilson_var_t,s0)

Notice the `--` on the first line? Those two dashes made me waste about 3 hours because I just assumed they were needed on all lines, and it kept messing with me when I used them on the second line. Turns out `--` means: **apply this rule to files only, no directories**. If you need to apply a rule just to a directory but not to a file that is matched by the regex, you can use `-d`

### Trial and error.

The way I have learned most things related to programming/computers/etc has been **trial and error**, and SELinux wasn't an exception. At this point I had a basic type enforcement file and a file context so I felt ready to deploy it and see what happens.

You run:

	make -f /usr/share/selinux/devel/Makefile

and this will generate a `.pp` file, you can then copy this file to your server and there run:

	sudo semodule -i app.pp

This will load the new policy and allow your app to execute the commands described in the `.te` file.
Now I needed to relabel the `/srv/bot` folder based on the new policy, you do this by running:

	restorecon -R -v /srv/bot

You can verify the new file context by running:

	$ ls -Z /srv
	system_u:object_r:mrwilson_var_t:s0 bot

It worked! and if you created a file inside the bot directory, it will also have the mrwilson_var_t context:

	$ ls -Z /srv/bot
	system_u:object_r:mrwilson_var_t:s0 2.log

Time to start the application using systemctl:

	sudo systemctl start mrwilson; sleep 1; sudo systemctl stop mrwilson;

on another terminal:

	journalctl -ef

I start my app, wait 1 second, and then stop it, why? because I knew it would generate some denied errors, it would fail, but systemd would try to start it again, so I wanted to reduce the number of log lines I needed to read.

And here starts the loop, to find out what privilege is still needed, run:

	ausearch -m avc -ts 02:59:59 | audit2allow -m mrwilson

* `-ts 02:59:59` tells `ausearch` to only look after this timestamp, very useful in our case.
* `audit2allow -m mrwilson` generates a new **.te** (type enforcement) file for us, read it and add the new instructions from the file to your main `app.te` file.

Once you update your type enforcement file, you call **make** again, upload it, run `sudo semodule -i app.pp`, start, wait, stop your app and see what else your app needs.

Depending on the size of your app, this could take a while, but if you are a glass half full kind of person, this will give you a huge insight into the inner workings of your app, which I personally find fascinating :).

## The final type enforcement file.

For mrwilson, the full file is:

	policy_module(mrwilson, 1.0.0)

	########################################
	#
	# Declarations
	#

	type mrwilson_t;

	type mrwilson_exec_t;
	init_daemon_domain(mrwilson_t, mrwilson_exec_t)

	type mrwilson_var_t;
	#make mrwilson_var_t a file context
	files_type(mrwilson_var_t)

	require {
		type user_home_t;
		type init_t;
		type user_home_dir_t;
		type sysctl_net_t;
		type unreserved_port_t;
		type http_port_t;
		class dir { add_name remove_name search write getattr };
		class file { create execute open read rename write unlink append getattr };
		class tcp_socket { accept listen name_bind name_connect };
		class capability net_bind_service;
	}


	### Manually added
	allow mrwilson_t mrwilson_var_t:dir { add_name remove_name write search getattr};
	allow mrwilson_t mrwilson_var_t:file { unlink create open rename write read append getattr };
	allow mrwilson_t user_home_dir_t:dir search;
	allow mrwilson_t user_home_t:file { open read write};
	allow mrwilson_t self:capability net_bind_service;
	allow mrwilson_t sysctl_net_t:dir search;
	allow mrwilson_t sysctl_net_t:file { read open };
	allow mrwilson_t http_port_t:tcp_socket { name_bind name_connect };
	allow mrwilson_t unreserved_port_t:tcp_socket { name_bind name_connect };
	allow mrwilson_t self:tcp_socket { listen accept };

	########################################

	allow mrwilson_t self:fifo_file rw_fifo_file_perms;
	allow mrwilson_t self:unix_stream_socket create_stream_socket_perms;
	domain_use_interactive_fds(mrwilson_t)
	auth_use_nsswitch(mrwilson_t)
	miscfiles_read_localization(mrwilson_t)
	sysnet_dns_name_resolve(mrwilson_t)


### Code

The files related to SElinux for my project are on [github, here](https://github.com/fmpwizard/mrwilson/tree/master/ansible/roles/mrwilson/templates) (They have the `j2` extension because I use ansible to provision the server, configure and deploy my app and all the requirements).

## Conclusion.

While writing a policy not knowing all the requirements of your Go application is time consuming, I believe that it is completely worth your time. By doing this we are assuring our users that if anyone finds a way to make our application misbehave, the damage will be contained to a minimum. My app isn't allowed to read or write outside `/srv/bot` or the user that runs the daemon's home directory (in my case it is a dedicated user that isn't even in the wheel user group).

Oh, and I know this isn't just for Go applications, this guide should work for any kind of application, I just happen to be working on Go :) .


You can find how I compile the separate files into a `pp` module by going [here](https://github.com/fmpwizard/mrwilson/blob/master/ansible/roles/mrwilson/tasks/install.yml)

I hope you find this useful.

>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
