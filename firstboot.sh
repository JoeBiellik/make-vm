#!/bin/bash

cat << EOF > /etc/resolv.conf
nameserver 8.8.8.8
EOF
