#!/bin/bash

warp-proxy \
--bind 0.0.0.0:1080 \
--country US &

sleep 3

bash /rotate_ip.sh &

while true
do
  bash /healthcheck.sh
  sleep 60
done
