#!/bin/bash

un=[username]
pw=[password]
lang=English

## set login cookie

curl --cookie-jar ./batoto "https://bato.to/forums/index.php?app=core&module=global&section=login&do=process" -H "Host: bato.to" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.5" --compressed -H "Content-Type: application/x-www-form-urlencoded" -H "Referer: https://bato.to/forums/index.php?app=core&module=global&section=login" -H "Connection: keep-alive" -H "Upgrade-Insecure-Requests: 1" --data "auth_key=880ea6a14ea49e853634fbdc5015a024&ips_username=$un&ips_password=$pw&rememberMe=1"

curl -s --cookie ./batoto "$1" | grep reader -A2 > batotohtml.tmp

pathroot=$(echo "$1"| awk -F "/" '{print $NF}' | sed 's/-r[[:digit:]]\{1,\}$//')

while read line; do
  if [ ${#line} -gt 20 ]; then
    if [ $(cat batotohtml.tmp | grep -A2 "$line" | tail -n1 | grep $lang | wc -l) -gt 0 ]; then
      linedata=$(echo $line | awk -F "\"" '{print $4 " -- " $2}')
      path="$pathroot/$(echo $linedata | awk -F "|" '{print $1}')"
      path=${path::-1}
      mkdir -p "$path"
      echo "Downloading to $path"
      url="http://bato.to/areader?id=$(echo $linedata | awk -F "#" '{print $2}')"
      lastpage=$(curl -s "$url&p=1" -H "Host: bato.to" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0" -H "Accept: */*" -H "Accept-Language: en-US,en;q=0.5" --compressed -H "X-Requested-With: XMLHttpRequest" -H "Referer: http://bato.to/reader" --cookie ./batoto -H "Connection: keep-alive" | grep "option value" | tail -n1 | awk -F "page" '{print $NF}' | tr -d " " | sed -e "s/<\/option>$//")
      if [ "$lastpage" -eq "$lastpage" ] 2>/dev/null; then
        for i in $(seq 1 $lastpage); do
          wget -q -P "$path" $(curl -s "$url&p=$i" -H "Host: bato.to" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0" -H "Accept: */*" -H "Accept-Language: en-US,en;q=0.5" --compressed -H "X-Requested-With: XMLHttpRequest" -H "Referer: http://bato.to/reader" --cookie ./batoto -H "Connection: keep-alive" | grep comic_page | awk '{print $5}' | tr -d "\"" | cut -c5-)
        done
      else
        for i in $(curl -s "$url&p=1" -H "Host: bato.to" -H "User-Agent: Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0" -H "Accept: */*" -H "Accept-Language: en-US,en;q=0.5" --compressed -H "X-Requested-With: XMLHttpRequest" -H "Referer: http://bato.to/reader" --cookie ./batoto -H "Connection: keep-alive" | grep "http://img.bato.to/comics/" | tail -n1 | grep -P -o "http:\/\/img.bato.to\/comics.+?\.jpg|\.png"); do
          wget -q -P "$path" $i
        done
      fi
    fi
  fi
done < batotohtml.tmp
rm batotohtml.tmp
