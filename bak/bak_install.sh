#!/bin/bash

# Install bak command
if [[ ! -d '/usr/local/bin' ]]; then
  sudo mkdir /usr/local/bin
fi
sudo cp bak.sh /usr/local/bin/bak
sudo chmod +x /usr/local/bin/bak

echo "bak command installed successfully."

