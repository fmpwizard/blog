#!/bin/bash
set -e
rm -r public
hugo
#recursive, archive, verbose, compress, keep times, delete left over files from server
rsync -ravzt  -e "ssh -i ~/.ssh/id_ed25519.asus"    --delete public root@157.245.213.245:/home/bot/blog.fmpwizard/ 
