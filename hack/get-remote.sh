#!/bin/bash
#
# Take the current origin and return the https remote.
# This works regardless if the repo was cloned with https or ssh

remote=$(git remote get-url origin)

if [[ "${remote}" == http* ]]
then
	printf "%s" "${remote}"
	exit 0
fi

remote=${remote##*@}
remote=${remote/:/\/}

printf "https://${remote}"
