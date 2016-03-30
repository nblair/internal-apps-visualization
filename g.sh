#!/usr/bin/env bash

while IFS='' read -r line || [[ -n "$line" ]]; do
    IFS=', ' read -r -a array <<< "$line"
    git clone git@git.doit.wisc.edu:${array[0]}/${array[1]}.git workdir/${array[1]}
    gource --output-custom-log workdir/${array[1]}.txt workdir/${array[1]}
    sed "s/\|\//\|\/${array[0]}\/${array[1]}\//" workdir/${array[1]}.txt > workdir/${array[1]}.edited.txt
done < "$1"

cat workdir/*.edited.txt | sort -n > $1.log

# sed command for linux (edits in place)
#sed -i -r "s#\(.+\)\|#\1|/$2#" $2.txt
