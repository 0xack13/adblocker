#!/bin/bash

files=(\
    'https://adaway.org/hosts.txt'\
    'http://winhelp2002.mvps.org/hosts.txt'\
    'http://hosts-file.net/.\ad_servers.txt'\
    'http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext'\
    'http://someonewhocares.org/hosts/hosts'\
    )

noip='127.0.0.1'

tmphosts=$(mktemp)
tmpraw=$(mktemp)
hostsfile=/etc/hosts

for item in ${files[*]}
do
    echo "Downloading $item ..."
    curl $item >> $tmpraw || { echo -e "\nError downloading $item"; exit 1; }
done

echo -e "127.0.0.1\tlocalhost $(hostname)\n" > $tmphosts

# \x0d = special ^M carriage return char on windows files
cat $tmpraw | sed 's/'$(echo "\x0d")'$//' |\
    grep '^\(127.0.0.1\|0.0.0.0\)' |\
    grep -v '\(\t\|\ \)*localhost$' |\
    sed 's/\(\t\|\ \)*#.*$//' |\
    sed "s/\(127.0.0.1\|0.0.0.0\)\(\t\|\ \)*/$noip\t/" |\
    # blocking s.ytimg.com makes youtube unusable:
    grep -Ev "$noip\ts.ytimg.com$" |\
    # amazon images:
    grep -Ev "$noip\tecx.images-amazon.com$" |\
    sort | uniq >> $tmphosts

sudo cp $tmphosts $hostsfile && rm $tmpraw $tmphosts
