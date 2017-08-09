#! /bin/bash

RIP_DIR="/srv/ripped-music"
CUT_COUNT=${#RIP_DIR}
FILES="$1/*"

IFS=$'\n'
for f in $FILES
do
	truncated=${f:CUT_COUNT}
	echo "Uploading to $truncated"
	curl -X POST https://content.dropboxapi.com/2/files/upload \
		--header "Authorization: Bearer **DROPBOX_BEARER_TOKEN**" \
		--header "Dropbox-API-Arg: {\"path\": \"$truncated\", \"mute\": true}" \
		--header "Content-Type: application/octet-stream" \
		--data-binary @$f
done
