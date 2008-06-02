#!/bin/sh

# Clears sensitve mail data securely.

locations=(
    ${HOME}/.mutt/cache/{bodies,headers}
    ${HOME}/.mutt/tmp/*
    ${HOME}/.mutt/tmp/*
    ${HOME}/.offlineimap
    ${HOME}/.gmail
)

for l in ${locations[@]} ; do 
    srm -rmv "${l}"
done
