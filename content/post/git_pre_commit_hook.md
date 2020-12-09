+++
date = "2020-12-07T21:49:57-07:00"
title = "Git pre-commit hooks not committing"
tags = ["git", "commit", "hooks", "go"]
+++

We use [reflex](https://github.com/cespare/reflex) to restart our local app whenever we make changes to any Go file. But I run into a small problem, because we use Go mod with the vendor pattern, `reflex` ends up on our `go.mod` and `go.sum` files, but I really don't want them there. They are not part of the app and should not be vendored.

I didn't want to ask developers to run `go mod tidy` before sending a Pull Request, so I looked into using a git pre-commit hook. After some trial and error, I ended up with:

```
#!/bin/bash

# format go code before commit
# exclude vendor folder and go installation (affects CI/CD)
gofmt -w -e `find . -name "*.go" -not -path "./go/*" | grep -v vendor`
# remove any extra dependency we don't need
go mod tidy
```

This file was committed to our repo, at the path `githooks/pre-commit`.

### Side note.

You need to ask each dev to run `git config core.hooksPath ./githooks` to **activate** the hook path. This is a local by default command, it will only affect this repository.

## Problems.

The hook **seemed** to had worked, but here and there I would run into a corner case where a PR would still make it with the extra entries in `go.mod`. Today, I had a few minutes to look into it and it turns out that a pre commit hook doesn't update the changes you had already added (staged changes). In other words, the pre commit hook run, it cleaned up `go.mod`, but it did not run `git add` on the changed files. You had to stage the new changes to make them part of your Pull Request.

## So what do we do now?

A small change:


```
#!/bin/bash

# format go code before commit
# exclude vendor folder and go installation (affects CI/CD)
gofmt -w -e `find . -name "*.go" -not -path "./go/*" | grep -v vendor`
# remove any extra dependency we don't need
go mod tidy
git diff --exit-code
```

Adding `git diff --exit-code` as the last line causes the pre-commit hook to cancel the commit call, then the dev simply reruns whichever commit command they had run, and now the code will be as I had expected it, clean.




>Thank you for reading and don't hesitate to leave a comment/question.

>[@fmpwizard](https://twitter.com/fmpwizard)

>Diego
