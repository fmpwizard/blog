#!/bin/bash
set -e
hugo
#recursive, archive, verbose, compress, keep times, delete left over fils from server
rsync -ravzt --delete public blog.fmpwizard.com:blog.fmpwizard/
