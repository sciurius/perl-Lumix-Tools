#!/bin/sh

# Simple shell script that runs forever and periodically (every 30
# seconds) polls a wifi connected camera.

host=tz200.squirrel.nl
tmp=~/tmp/watch$$
year=$(date +%Y)
albums=`resinfo media.albums.root`

current=off

while true
do
    ping -q -w5 ${host} > ${tmp} 2>&1
    if [ $? = 0 ]; then
	state="on"
	if [ $current = "off" ]; then

	    # Camera has been connected. Fetch images and poweroff.
	    make -C "$albums/${year}" fetch POWEROFF=--poweroff > ${tmp} 2>&1
	    mail -s "tz200: ${state}" jv < ${tmp}
	fi

    else
	state="off"
    fi
    current=$state

    sleep 30

    # To terminate, remove the watch file.
    if [ ! -f ${tmp} ]; then
	exit
    fi
done
