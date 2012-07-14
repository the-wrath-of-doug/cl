#!/usr/bin/env bash

# NOTES
#
# The "rl" is in the "randomize-lines" package, sources at
# http://arthurdejong.org/rl/
#
# The "primes" command is in "freebsd-games" package -- so I like prime
# numbers for random delays in my scripts.
#
# Both commands can be ommitted in the source and static delays can be used.
# For random delays, using the BASH method would more than suffice:
#
#   DELAY=$RANDOM && let "DELAY %= 30" 
#   sleep $DELAY
#

#export PROXY=http://192.168.4.1:3128
export AGENT="Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)"
export CITYFILE=cities_entire_usa.txt

#  Given a URL, dump all links found on the page
#
function dumplinks () {
  export URL=$1
  http_proxy=$PROXY \
    lynx -dump -image_links -connect_timeout=120 -useragent="$AGENT" \
    -force_html "$URL" 2>/dev/null |\
    egrep -i "^....\. http://|^....\. ftp://" |
    awk '{print $2}' | \
    sort -u
}



#  Given a URL for a SECTION page, dump all postings
#
function dumpposts () {
  dumplinks $1 |\
    egrep "[0-9]{10}\.html"
}  # END function dumpposts()



#  Given a POST URL, check for watchlist.txt tags then tag the file
#
function tagpost () {
  local  FILENAME DEST SOURCE
  FILENAME=`echo "$1" | awk -F\/ '{print $NF}'`
  SOURCE="downloaded/$FILENAME"
  DEST="tagged/$FILENAME"
  export FILENAME SOURCE DEST

  if [ ! -e $DEST ]; then

    egrep -v "^(#|$)" watchlist.txt | while read PHRASE; do
  
      grep -qil "$PHRASE" $SOURCE

      if [ $? -eq 0 ]; then
        echo "Matched: on \"$PHRASE\"" >> $DEST
      fi

    done  # going through "watchlist.txt"

    if [ -e $DEST ]; then

      echo "#################################################" >> $DEST
      echo "Source: $1" >> $DEST
      echo "#################################################" >> $DEST

      cat $SOURCE >> $DEST
      echo "    Post $SOURCE matched on a keyword"

    fi

  fi

}  #  End function tagpost()



#  Given a POST URL, dump the contents of that URL to file
#
function fetchpost () {
  local DESTFILE DEST
  export DESTFILE=$(echo "$1" | awk -F\/ '{print $NF}')
  export DEST=downloaded/$DESTFILE

  if [[ ! -e $DEST ]]; then
    echo "  Fetching: $1 ..."
    http_proxy=$PROXY \
      lynx --dump --nolist -connect_timeout=120 \
         -useragent="$AGENT" "$1" 2>/dev/null |\
      awk '/^[^ ]/, /PostingID:/' > $DEST
    if [ -s $DEST ]; then
      tagpost $1
      DELAY=$( primes 1 13 | rl | tail -1 )
      echo "    Sleeping for $DELAY seconds..."
      sleep $DELAY
    else
      rm -f $DEST 2>/dev/null
    fi
  fi

}  # END function fetchpost()






#  Generate combinations of cities and sections to poll
#

LOOPCOUNT=0

while true; do

  LOOPCOUNT=$((LOOPCOUNT+1))
  DATE=`date "+%Y.%m.%d.%H.%M"`
  echo "Starting main loop, count $LOOPCOUNT on $DATE" >> cl.log

  egrep -v "^(#|$)" $CITYFILE | sort -u | rl | while read CITY; do

    DOMAIN=$CITY.craigslist.com

    egrep -v "^(#|$)" sections.txt | rl | while read SECTION; do

      URL=http://$DOMAIN/$SECTION/
      echo "Processing main page $URL ..."

      dumpposts $URL | while read POST; do
        fetchpost $POST
      done  # Loop through posts on a SECTION page

      DELAY=$(primes 1 31 | rl | tail -1)
      echo "    Sleeping for $DELAY seconds..."
      sleep $DELAY

    done # Loop through SECTIONS

  done   # Loop through CITY

  DELAY=$(primes 1 3600 | rl | tail -1)
  echo "Master loop over.  Sleeping for $DELAY seconds..."
  sleep $DELAY

done   #  Master loop -- do it *all* again...
