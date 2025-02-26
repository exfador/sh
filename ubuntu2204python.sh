#!/bin/bash

echo "Обновление системы..."
sudo apt update
sudo apt upgrade -y

echo "Установка Python 3.10..."
sudo apt install python3.10 -y

echo "Установка pip для Python 3..."
sudo apt install python3-pip -y


echo "Установка русского языка..."
sudo apt install language-pack-ru -y


echo "Генерация локали для русского языка..."
sudo locale-gen ru_RU.UTF-8


echo "Установка локали по умолчанию..."
sudo update-locale LANG=ru_RU.UTF-8


echo "Проверка версии Python..."
python3.10 --version


echo "Проверка версии pip..."
pip3 --version

echo "Проверка локали..."
locale | grep LANG

echo "Установка завершена. Пожалуйста, перезагрузите систему для применения изменений локали."
