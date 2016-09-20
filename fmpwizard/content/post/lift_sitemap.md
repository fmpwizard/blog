+++
date = "2012-11-11T21:49:57-07:00"
title = "Lift Sitemaps - a better way"
aliases = [
	"/blog/lift_sitemap"
]
+++

[title: ]: /
[category: Lift]: /
[date: 2012/11/11]: /
[tags: {lift, scala, site map}]: /


# Lift Sitemap

One of the many things I have recently learned from [Tim Nelson](https://twitter.com/eltimn) is how to better use `Sitemap`.

You know, most of us declare our site maps in Lift like this:

```
def sitemap = SiteMap(
      Menu.i("Home")         / "index",
      Menu.i("About")        / "about",
      Menu.i("user.list")    / "user" / "list"   >> LoggedIn,
      Menu.i("user.create")  / "user" / "create" >> LoggedIn
)
```

To most people this looks just like any other site map they have implemented in the past. And in your snippets, if you need to link to, let's say, the user's list page, you would som something like:

    SHtml.link("/user/list", () => someMethodHere(someValueHere))

Now, if for any reason, you then need to change the path from http://hostname/user/list to some over path, you will have to do some search/replace from your preferred IDE/text editor/etc. And this just does;t feel right.

## Solution?

Declare each sitemap entry as a `val`. So, taking our example, your sitemap would look like:

```
object Paths {
  lazy val home       = Menu.i("Home")         / "index"
  lazy val about      = Menu.i("About")        / "about"
  lazy val userList   = Menu.i("user.list")    / "user" / "list"
  lazy val userCreate = Menu.i("user.create")  / "user" / "create"

  def sitemap = SiteMap(
    home,
    about,
    userList   >> LoggedIn
    userCreate >> LoggedIn
  )
}
```

And, from your snippet, if you want to link to the `/user/list` page, you can use `Paths.userList.loc.calcDefaultHref`

I have enjoyed using this technique a lot, and I hope you do as well.

Thanks for reading.

  Diego
