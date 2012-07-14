#!/bin/sh

ls -1 tagged | while read FILE; do

  if [ ! -e read/$FILE ]; then
    clear ; less tagged/$FILE
    ln -f tagged/$FILE read/$FILE
  fi

done

