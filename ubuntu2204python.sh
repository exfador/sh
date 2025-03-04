#!/bin/bash

echo ""
echo "Установщик создан @exfador, основан на предыдущей версии от @sidor0912"
echo "Почему этот установщик лучше:"
echo "1. Более гибкий выбор имени пользователя (не ограничен 'fpc' или 'cardinal')"
echo "2. Использует screen вместо systemd для удобного доступа к консоли бота"
echo "3. Упрощенная структура без лишних зависимостей и шагов"
echo "4. Более понятные инструкции в конце установки"
echo ""

echo -n "Введите имя пользователя, от имени которого будет запускаться бот: "
while true; do
  read username
  if [[ "$username" =~ ^[a-zA-Z][a-zA-Z0-9_-]+$ ]]; then
    if id "$username" &>/dev/null; then
      echo -n "Такой пользователь уже существует. Пожалуйста, введите другое имя пользователя: "
    else
      break
    fi
  else
    echo -n "Имя пользователя содержит недопустимые символы. Имя должно начинаться с буквы и может включать только буквы, цифры, '_', или '-'. Пожалуйста, введите другое имя пользователя: "
  fi
done

distro_version=$(lsb_release -rs)

echo "Добавляю репозитории..."
if ! sudo apt update ; then
  echo "Произошла ошибка при обновлении списка пакетов."
  exit 2
fi

if ! sudo apt install -y software-properties-common ; then
  echo "Произошла ошибка при установке software-properties-common."
  exit 2
fi

case $distro_version in
  "22.04" | "22.10" | "23.04" | "23.10" | "24.04" | "24.10")
    ;;
  "12")
    ;;
  "11")
    if ! sudo apt install -y gnupg ; then
      echo "Произошла ошибка при установке gnupg."
      exit 2
    fi
    if ! sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA6932366A755776 ; then
      echo "Произошла ошибка при добавлении ключа репозитория."
      exit 2
    fi
    if ! sudo add-apt-repository -s "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu focal main" ; then
      echo "Произошла ошибка при добавлении репозитория."
      exit 2
    fi
    sudo tee /etc/apt/preferences.d/10deadsnakes-ppa >/dev/null <<EOF
Package: *
Pin: release o=LP-PPA-deadsnakes
Pin-Priority: 100
EOF
    if $? -ne 0 ; then
      echo "Произошла ошибка при добавлении приоритета репозитория."
      exit 2
    fi
    ;;
  *)
    if ! sudo add-apt-repository -y ppa:deadsnakes/ppa ; then
      echo "Произошла ошибка при добавлении репозитория."
      exit 2
    fi
    ;;
esac

if ! sudo apt update ; then
  echo "Произошла ошибка при обновлении списка пакетов."
  exit 2
fi

echo "Устанавливаю необходимые пакеты..."
if ! sudo apt install -y curl unzip screen ; then
  echo "Произошла ошибка при установке необходимых пакетов."
  exit 2
fi

echo "Устанавливаю Python..."
case $distro_version in
  "24.04" | "24.10")
    if ! sudo apt install -y python3.12 python3.12-dev python3.12-gdbm python3.12-venv ; then
      echo "Произошла ошибка при установке Python."
      exit 2
    fi
    ;;
  *)
    if ! sudo apt install -y python3.11 python3.11-dev python3.11-gdbm python3.11-venv ; then
      echo "Произошла ошибка при установке Python."
      exit 2
    fi
    ;;
esac

echo "Создаю пользователя и устанавливаю/обновляю Pip..."
if ! sudo useradd -m "$username" ; then
  echo "Произошла ошибка при создании пользователя."
  exit 2
fi

case $distro_version in
  "24.04" | "24.10")
    if ! sudo -u "$username" python3.12 -m venv /home/"$username"/pyvenv ; then
      echo "Произошла ошибка при создании виртуального окружения."
      exit 2
    fi
    ;;
  *)
    if ! sudo -u "$username" python3.11 -m venv /home/"$username"/pyvenv ; then
      echo "Произошла ошибка при создании виртуального окружения."
      exit 2
    fi
    ;;
esac

if ! sudo /home/"$username"/pyvenv/bin/python -m ensurepip --upgrade ; then
  echo "Произошла ошибка при установке Pip."
  exit 2
fi

if ! sudo -u "$username" /home/"$username"/pyvenv/bin/python -m pip install --upgrade pip ; then
  echo "Произошла ошибка при обновлении Pip."
  exit 2
fi

if ! sudo chown -hR "$username":"$username" /home/"$username"/pyvenv ; then
  echo "Произошла ошибка при изменении владельца виртуального окружения."
  exit 2
fi

echo "Устанавливаю FunPayCardinal..."
if ! sudo mkdir /home/"$username"/fpc-install ; then
  echo "Произошла ошибка при создании директории для установки."
  exit 2
fi

gh_repo="sidor0912/FunPayCardinal"
LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases/latest | grep "zipball_url" | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g' )

if ! sudo curl -L "$LOCATION" -o /home/"$username"/fpc-install/fpc.zip ; then
  echo "Произошла ошибка при загрузке архива."
  exit 2
fi

if ! sudo unzip /home/"$username"/fpc-install/fpc.zip -d /home/"$username"/fpc-install ; then
  echo "Произошла ошибка при распаковке архива."
  exit 2
fi

if ! sudo mkdir /home/"$username"/FunPayCardinal ; then
  echo "Произошла ошибка при создании директории для бота."
  exit 2
fi

if ! sudo mv /home/"$username"/fpc-install/*/* /home/"$username"/FunPayCardinal/ ; then
  echo "Произошла ошибка при перемещении файлов."
  exit 2
fi

if ! sudo rm -rf /home/"$username"/fpc-install ; then
  echo "Произошла ошибка при удалении директории для установки."
  exit 2
fi

if ! sudo chown -hR "$username":"$username" /home/"$username"/FunPayCardinal ; then
  echo "Произошла ошибка при изменении владельца файлов."
  exit 2
fi

if ! sudo -u "$username" /home/"$username"/pyvenv/bin/pip install -U -r /home/"$username"/FunPayCardinal/requirements.txt ; then
  echo "Произошла ошибка при установке необходимых Py-пакетов."
  exit 2
fi

echo "Настраиваю кодировку сервера..."
case $distro_version in
  "11" | "12")
    if ! sudo apt install -y locales locales-all ; then
      echo "Произошла ошибка при установке локализаций."
      exit 2
    fi
    ;;
  *)
    if ! sudo apt install -y language-pack-en ; then
      echo "Произошла ошибка при установке языковых пакетов."
      exit 2
    fi
    ;;
esac

echo "Запускаю первичную настройку..."
sudo -u "$username" LANG=en_US.utf8 /home/"$username"/pyvenv/bin/python /home/"$username"/FunPayCardinal/main.py

echo "Запускаю FunPayCardinal в screen сессии..."
sudo -u "$username" screen -dmS fpc_"$username" bash -c "LANG=en_US.utf8 /home/\"$username\"/pyvenv/bin/python /home/\"$username\"/FunPayCardinal/main.py"

echo "################################################################################"
echo "!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!"
echo ""
echo "Готово!"
echo "FPC запущен в screen сессии fpc_$username"
echo "Для подключения к сессии используй команду: sudo -u $username screen -r fpc_$username"
echo "Для отсоединения от сессии нажми Ctrl+A D"
echo "Для списка сессий используй: sudo -u $username screen -ls"
echo "Теперь напиши своему Telegram-боту."
echo "################################################################################"
echo -n "Сделал скриншот? Тогда нажми Enter, чтобы продолжить."
read
