#!/bin/bash

read -d '' COMMANDS <<EOF
curl -I http://localhost:3001/static/cherry.jpg
curl -I http://localhost:3001/static/script.js
curl -I http://localhost:3001/static/style.css
curl -I http://localhost:3001/dynamic/param.php?name=alice
curl -I http://localhost:3001/dynamic/client.php
curl -I http://localhost:3001/dynamic/cookie.php
curl -I http://localhost:3001/dynamic/header.php
EOF

export IFS="\n"
for cmd in $COMMANDS; do
    echo $cmd
    eval $cmd
done
