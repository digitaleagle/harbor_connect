#!/bin/bash

CALLING_DIR=$(dirname $0)

cd $CALLING_DIR
pwd
if [ ! -d "web" ]; then
  echo "web directory doesn't exist"
  exit 1
fi
if [ -d "front" ]; then
  mv "front" "front-$(date +%Y%m%d_%H%M%S)"
fi
mv web front