+++
date = "2012-05-30T21:49:57-07:00"
title = "Why do we need Template(() => Templates()) ?"
aliases = [
	"/blog/why-do-we-need-template-templates"
]
+++

[title=Why do we need Template(() => Templates()) ?]: /
[category: Lift]: /
[date: 2012/05/30]: /
[tags: {lift, scala, sitemap}]: /



# Why do we need Template(() => Templates()) ?

I have seen a few emails on the Lift mailing list where people use

```
Template(() => Templates("filenamehere" :: Nill))
```

but I never knew why they used that, instead of just naming their templates on the sitemap entry like:

```
Menu.i("myPage") /  "filenamehere"
```

And today I run into at least one use case, which makes a lot of sense and I'm very happy is there.

##The problem.

I have a few template files organized under `webapp/mymodule1/` , but I don't want my users to see `mymodule1` as part of the URL.

##The solution.

Now I have:

```
Menu.i("myprofile") / "myprofile" >> Template(() => Templates("mymodule1" :: "myprofile" :: Nil).openOr(NodeSeq.Empty))
```

This allows me to give my users a url like `http://host/myprofile` , but internally I have the template for this snippet in `webapp/mymodule1/myprofile`.

That's all for today, simple, small, but I think it is very useful and makes the user experience much nicer, without sacrificing development organization.

##Next?

I'll share a tip Tim Nelson gave me last week, also related to Sitemap.

Update.

You can avoid using `.openOr` by using:

```
Menu.i("myprofile") / "myprofile" >> TemplateBox(() => Templates("mymodule1" :: "myprofile" :: Nil))
```

Thanks to David for the update on `TemplateBox`.
