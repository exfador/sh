#!/bin/bash


sudo apt update && sudo apt upgrade -y

sudo apt install -y software-properties-common


sudo add-apt-repository -y ppa:deadsnakes/ppa


sudo apt update


sudo apt install -y python3.10 python3.10-full


wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py


python3.10 /tmp/get-pip.py


python3.10 -m pip install --upgrade pip


rm /tmp/get-pip.py
