#!/bin/bash
set -e
hugo
#recursive, archive, verbose, compress, keep times, delete left over fils from server
rsync -ravzt --delete public ssh.lovelydreamhomes.com:blog.fmpwizard/
