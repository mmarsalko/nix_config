#!/usr/bin/env bash

logdest="dyndns-log"

oldip=$(cat /home/matt-htpc/.dyndns/old_ip)
myip=`curl -s "https://api.ipify.org"`
echo "`date '+%Y-%m-%d %H:%M:%S'` - Current External IP is $myip, Old IP is $oldip"

if [ "$oldip" != "$myip" -a "$myip" != "" ]; then
  echo $myip > /home/matt-htpc/.dyndns/old_ip

  echo "IP has changed!! Updating on Namecheap (Mine)"
  ncapikey="$(cat /home/matt-htpc/.dyndns/ncapikey_shaffle)"
  mydomain="shaffle.me"

  # Update all the endpoints
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=cloud&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=hass&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=lnbits&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=photos&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=srb2dev&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=vpn&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=tv&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=movies&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=rss&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=plex&password=$ncapikey&ip=$myip"
  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=lnaddress&password=$ncapikey&ip=$myip"

  sleep 1
  echo "IP has changed, updating Namecheap (Bayareabtc)"
  ncapikey="$(cat /home/matt-htpc/.dyndns/ncapikey_bayareabtc)"
  mydomain="bayareabtc.com"
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&password=$ncapikey&ip=$myip"

  echo "IP has changed!! Updating on Namecheap (Ali)"
  ncapikey="$(cat /home/matt-htpc/.dyndns/ncapikey_ali)"
  mydomain="alisonbarnes.com"

  sleep 1
  curl "https://dynamicdns.park-your-domain.com/update?domain=$mydomain&host=photos&password=$ncapikey&ip=$myip"


fi
