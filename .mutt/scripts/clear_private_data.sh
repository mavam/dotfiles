#!/bin/sh

# Clears sensitve mail data securely.

locations=(
    ${HOME}/.mutt/tmp/*
    ${HOME}/.offlineimap
    ${HOME}/.gmail
)

for l in ${locations[@]} ; do 
    srm -rmv "${l}"
done
