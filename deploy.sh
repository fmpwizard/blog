#!/bin/bash
set -e
rm -r public
hugo
#recursive, archive, verbose, compress, keep times, delete left over fils from server
rsync -ravzt --delete public diego@blog.fmpwizard.com:blog.fmpwizard/
