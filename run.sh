#!/bin/bash

if [ -z "$1" ]; then
  echo "Error: No file path provided"
  exit 1
fi

export FILE_PATH=$1
echo "File to be used: $FILE_PATH"

echo "Starting server"
rails server
