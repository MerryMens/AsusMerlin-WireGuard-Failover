#!/bin/sh

sleep 60

#### Wait for NTP to sync ####
ntpCheck="0"
while [ "$(nvram get ntp_ready)" = "0" ] && [ "ntpCheck" -lt "300" ]
do
  ntptimer="$((ntpCheck + 1))"
  if [ "$ntpCheck" = "60" ]
  then
    logger -st "Wireguard VPN Failover - Waiting for NTP to sync"
  fi
  sleep 5
done

#### Don't execute script if NTP sync fails ####
if [ "$ntpCheck" -ge "300" ]
then
  logger -st "Wireguard VPN Failover failed to start - NTP sync failed after 5 mins"
  exit
fi

#### Set default parameters ####
wgFailoverConfigFilePath="/jffs/configs/wg_vpn_failover_config"
wgClientConfigFilesDir="/jffs/configs/wg_vpn_config_files"

#### Run script forever ####
while true
do
  #### Read Wireguard config file into variables ####
  while read line
  do
    wgClientPriority="$(echo $line | cut -d " " -f1)"
    wgClientConfigFileName="$(echo $line | cut -d " " -f2)"
    wgClientDescription="$(echo $line | cut -d " " -f3)"
    wgClientConfigFilePath=$wgClientConfigFilesDir/$wgClientConfigFileName

    logger -s "Wireguard VPN Client Monitor: Setting Wireguard VPN Client to $wgClientDescription"
    
    #### Read Wireguard client config file into variables and generate nvram set commands ####
    while read line
    do
      #### Remove spaces around equal sign to make formatting easy ####
      if test "$line" != "${line%" = "*}"
      then
        lineFormatted="${line//" "/""}"
        #### Generate nvram set commands from Wireguard client config file ####
        if test "$lineFormatted" != "${lineFormatted%"Address"*}"
        then
          nvram set wgc1_addr="${lineFormatted#*=}"
        fi
        if test "$lineFormatted" != "${lineFormatted%"Endpoint"*}"
        then
          endpointFull="${lineFormatted#*=}"
          nvram set wgc1_ep_addr="${endpointFull%:*}"
          nvram set wgc1_ep_port="${endpointFull#*:}"
        fi
        if test "$lineFormatted" != "${lineFormatted%"PublicKey"*}"
        then
          nvram set wgc1_ppub="${lineFormatted#*=}"
        fi
        if test "$lineFormatted" != "${lineFormatted%"PrivateKey"*}"
        then
          nvram set wgc1_priv="${lineFormatted#*=}"
        fi
        if test "$lineFormatted" != "${lineFormatted%"PresharedKey"*}"
        then
          nvram set wgc1_psk="${lineFormatted#*=}"
        fi
        if test "$lineFormatted" != "${lineFormatted%"AllowedIPs"*}"
        then
          nvram set wgc1_aips="${lineFormatted#*=}"
        fi
        if test "$lineFormatted" != "${lineFormatted%"DNS"*}"
        then
          nvram set wgc1_dns="${lineFormatted#*=}"
        fi
      fi
    done < "$wgClientConfigFilePath"
    #### Generate default nvram set commands ####
    nvram set wgc1_desc="$wgClientDescription"
    nvram set wgc1_alive=25
    nvram set wgc1_enable=1
    nvram set wgc1_fw=1
    nvram set wgc1_nat=1
    service restart_wgc
    sleep 5
    wg show wgc1
    
    #### Check for latest handshake ####
    lhs=`wg show wgc1 | grep handshake | cut -d ":" -f3 | cut -d ")" -f1`

    #### Keep monitoring latest handshake, exit loop if it past threshold of 180 secs ####
    while [ $lhs -lt 180 ]
    do
      logger -s "Wireguard VPN Client Monitor: $wgClientDescription - Latest handshake in seconds: $lhs"
      logger -s  "Wireguard VPN Client Monitor: $wgClientDescription - Handshake check will be performed in another 30 secs..."
      sleep 180
      lhs=`wg show wgc1 | grep handshake | cut -d ":" -f3 | cut -d ")" -f1`
    done
    logger -s "Wireguard VPN Client Monitor: Latest handshake past the threshold of 180 secs"
    logger -s "Wireguard VPN Client Monitor: Switching to a different VPN config..."

  done < "$wgFailoverConfigFilePath"
done
