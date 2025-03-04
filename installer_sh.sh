#!/bin/bash


GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "Установщик создан @exfador, основан на предыдущей версии от @sidor0912${RESET}"
echo "Почему этот установщик лучше:"
echo "1. Более гибкий выбор имени пользователя (не ограничен 'fpc' или 'cardinal')"
echo "2. Использует screen вместо systemd для удобного доступа к консоли бота"
echo "3. Упрощенная структура без лишних зависимостей и шагов"
echo "4. Более понятные инструкции в конце установки"
echo "5. Возможность выбора версии FunPayCardinal"
echo -e "${RESET}"

echo -n -e "${GREEN}Введите имя пользователя, от имени которого будет запускаться бот: ${RESET}"
while true; do
  read username
  if [[ "$username" =~ ^[a-zA-Z][a-zA-Z0-9_-]+$ ]]; then
    if id "$username" &>/dev/null; then
      echo -n -e "${RED}Такой пользователь уже существует. Пожалуйста, введите другое имя пользователя: ${RESET}"
    else
      break
    fi
  else
    echo -n -e "${RED}Имя пользователя содержит недопустимые символы. Имя должно начинаться с буквы и может включать только буквы, цифры, '_', или '-'. Пожалуйста, введите другое имя пользователя: ${RESET}"
  fi
done

distro_version=$(lsb_release -rs)

echo -e "${GREEN}Получаю список доступных версий FunPayCardinal...${RESET}"
gh_repo="sidor0912/FunPayCardinal"
releases=$(curl -sS https://api.github.com/repos/$gh_repo/releases | grep "tag_name" | awk '{print $2}' | sed 's/"//g' | sed 's/,//g')
if [ -z "$releases" ]; then
  echo -e "${RED}Не удалось получить список версий с GitHub. Использую последнюю версию по умолчанию.${RESET}"
  use_latest="true"
else
  echo -e "${YELLOW}Доступные версии FunPayCardinal:${RESET}"
  versions=($releases)
  for i in "${!versions[@]}"; do
    echo "$i) ${versions[$i]}"
  done
  echo "latest) Последняя версия (по умолчанию)"
  
  echo -n -e "${YELLOW}Выберите версию (введите номер или 'latest'): ${RESET}"
  read version_choice
  if [[ "$version_choice" == "latest" || -z "$version_choice" ]]; then
    use_latest="true"
  elif [[ "$version_choice" =~ ^[0-9]+$ && $version_choice -ge 0 && $version_choice -lt ${#versions[@]} ]]; then
    selected_version=${versions[$version_choice]}
    echo -e "${GREEN}Выбрана версия: $selected_version${RESET}"
  else
    echo -e "${RED}Неверный выбор. Использую последнюю версию по умолчанию.${RESET}"
    use_latest="true"
  fi
fi

echo -e "${GREEN}Добавляю репозитории...${RESET}"
if ! sudo apt update ; then
  echo -e "${RED}Произошла ошибка при обновлении списка пакетов.${RESET}"
  exit 2
fi

if ! sudo apt install -y software-properties-common ; then
  echo -e "${RED}Произошла ошибка при установке software-properties-common.${RESET}"
  exit 2
fi

case $distro_version in
  "22.04" | "22.10" | "23.04" | "23.10" | "24.04" | "24.10")
    ;;
  "12")
    ;;
  "11")
    if ! sudo apt install -y gnupg ; then
      echo -e "${RED}Произошла ошибка при установке gnupg.${RESET}"
      exit 2
    fi
    if ! sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA6932366A755776 ; then
      echo -e "${RED}Произошла ошибка при добавлении ключа репозитория.${RESET}"
      exit 2
    fi
    if ! sudo add-apt-repository -s "deb https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu focal main" ; then
      echo -e "${RED}Произошла ошибка при добавлении репозитория.${RESET}"
      exit 2
    fi
    sudo tee /etc/apt/preferences.d/10deadsnakes-ppa >/dev/null <<EOF
Package: *
Pin: release o=LP-PPA-deadsnakes
Pin-Priority: 100
EOF
    if $? -ne 0 ; then
      echo -e "${RED}Произошла ошибка при добавлении приоритета репозитория.${RESET}"
      exit 2
    fi
    ;;
  *)
    if ! sudo add-apt-repository -y ppa:deadsnakes/ppa ; then
      echo -e "${RED}Произошла ошибка при добавлении репозитория.${RESET}"
      exit 2
    fi
    ;;
esac

if ! sudo apt update ; then
  echo -e "${RED}Произошла ошибка при обновлении списка пакетов.${RESET}"
  exit 2
fi

echo -e "${GREEN}Устанавливаю необходимые пакеты...${RESET}"
if ! sudo apt install -y curl unzip screen jq ; then
  echo -e "${RED}Произошла ошибка при установке необходимых пакетов.${RESET}"
  exit 2
fi

echo -e "${GREEN}Устанавливаю Python...${RESET}"
case $distro_version in
  "24.04" | "24.10")
    if ! sudo apt install -y python3.12 python3.12-dev python3.12-gdbm python3.12-venv ; then
      echo -e "${RED}Произошла ошибка при установке Python.${RESET}"
      exit 2
    fi
    ;;
  *)
    if ! sudo apt install -y python3.11 python3.11-dev python3.11-gdbm python3.11-venv ; then
      echo -e "${RED}Произошла ошибка при установке Python.${RESET}"
      exit 2
    fi
    ;;
esac

echo -e "${GREEN}Создаю пользователя и устанавливаю/обновляю Pip...${RESET}"
if ! sudo useradd -m "$username" ; then
  echo -e "${RED}Произошла ошибка при создании пользователя.${RESET}"
  exit 2
fi

case $distro_version in
  "24.04" | "24.10")
    if ! sudo -u "$username" python3.12 -m venv /home/"$username"/pyvenv ; then
      echo -e "${RED}Произошла ошибка при создании виртуального окружения.${RESET}"
      exit 2
    fi
    ;;
  *)
    if ! sudo -u "$username" python3.11 -m venv /home/"$username"/pyvenv ; then
      echo -e "${RED}Произошла ошибка при создании виртуального окружения.${RESET}"
      exit 2
    fi
    ;;
esac

if ! sudo /home/"$username"/pyvenv/bin/python -m ensurepip --upgrade ; then
  echo -e "${RED}Произошла ошибка при установке Pip.${RESET}"
  exit 2
fi

if ! sudo -u "$username" /home/"$username"/pyvenv/bin/python -m pip install --upgrade pip ; then
  echo -e "${RED}Произошла ошибка при обновлении Pip.${RESET}"
  exit 2
fi

if ! sudo chown -hR "$username":"$username" /home/"$username"/pyvenv ; then
  echo -e "${RED}Произошла ошибка при изменении владельца виртуального окружения.${RESET}"
  exit 2
fi

echo -e "${GREEN}Устанавливаю FunPayCardinal...${RESET}"
if ! sudo mkdir /home/"$username"/fpc-install ; then
  echo -e "${RED}Произошла ошибка при создании директории для установки.${RESET}"
  exit 2
fi

if [ "$use_latest" == "true" ]; then
  LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases/latest | jq -r '.zipball_url')
else
  LOCATION=$(curl -sS https://api.github.com/repos/$gh_repo/releases | jq -r ".[] | select(.tag_name == \"$selected_version\") | .zipball_url")
fi

if [ -z "$LOCATION" ]; then
  echo -e "${RED}Не удалось определить URL для загрузки. Проверьте доступность GitHub API или правильность выбранной версии.${RESET}"
  exit 2
fi

if ! sudo curl -L "$LOCATION" -o /home/"$username"/fpc-install/fpc.zip ; then
  echo -e "${RED}Произошла ошибка при загрузке архива.${RESET}"
  exit 2
fi

if ! sudo unzip /home/"$username"/fpc-install/fpc.zip -d /home/"$username"/fpc-install ; then
  echo -e "${RED}Произошла ошибка при распаковке архива.${RESET}"
  exit 2
fi

if ! sudo mkdir /home/"$username"/FunPayCardinal ; then
  echo -e "${RED}Произошла ошибка при создании директории для бота.${RESET}"
  exit 2
fi

if ! sudo mv /home/"$username"/fpc-install/*/* /home/"$username"/FunPayCardinal/ ; then
  echo -e "${RED}Произошла ошибка при перемещении файлов.${RESET}"
  exit 2
fi

if ! sudo rm -rf /home/"$username"/fpc-install ; then
  echo -e "${RED}Произошла ошибка при удалении директории для установки.${RESET}"
  exit 2
fi

if ! sudo chown -hR "$username":"$username" /home/"$username"/FunPayCardinal ; then
  echo -e "${RED}Произошла ошибка при изменении владельца файлов.${RESET}"
  exit 2
fi

echo -e "${GREEN}Устанавливаю зависимости для FunPayCardinal...${RESET}"
if [ -f /home/"$username"/FunPayCardinal/requirements.txt ]; then
  if ! sudo -u "$username" /home/"$username"/pyvenv/bin/pip install -U -r /home/"$username"/FunPayCardinal/requirements.txt ; then
    echo -e "${RED}Произошла ошибка при установке зависимостей из requirements.txt.${RESET}"
    exit 2
  fi
elif [ -f /home/"$username"/FunPayCardinal/setup.py ]; then
  echo -e "${YELLOW}setup.py найден. Устанавливаю фиксированный набор зависимостей вручную...${RESET}"
  if ! sudo -u "$username" /home/"$username"/pyvenv/bin/pip install \
    psutil>=5.9.4 \
    beautifulsoup4>=4.11.1 \
    colorama>=0.4.6 \
    requests==2.28.1 \
    pytelegrambotapi==4.15.2 \
    pillow>=9.3.0 \
    aiohttp==3.9.0 \
    requests_toolbelt==0.10.1 \
    lxml>=5.3.0 \
    bcrypt>=4.2.0 ; then
    echo -e "${RED}Произошла ошибка при установке фиксированного набора зависимостей.${RESET}"
    exit 2
  fi
else
  echo -e "${YELLOW}Не найден ни requirements.txt, ни setup.py. Устанавливаю минимальный набор зависимостей...${RESET}"
  if ! sudo -u "$username" /home/"$username"/pyvenv/bin/pip install requests pytelegrambotapi pyyaml aiohttp requests_toolbelt lxml bcrypt beautifulsoup4 ; then
    echo -e "${RED}Произошла ошибка при установке минимального набора зависимостей.${RESET}"
    exit 2
  fi
fi

echo -e "${GREEN}Настраиваю кодировку сервера...${RESET}"
case $distro_version in
  "11" | "12")
    if ! sudo apt install -y locales locales-all ; then
      echo -e "${RED}Произошла ошибка при установке локализаций.${RESET}"
      exit 2
    fi
    ;;
  *)
    if ! sudo apt install -y language-pack-en ; then
      echo -e "${RED}Произошла ошибка при установке языковых пакетов.${RESET}"
      exit 2
    fi
    ;;
esac

echo -e "${GREEN}Запускаю первичную настройку...${RESET}"
if ! sudo -u "$username" LANG=en_US.utf8 /home/"$username"/pyvenv/bin/python /home/"$username"/FunPayCardinal/main.py ; then
  echo -e "${RED}Произошла ошибка при первичной настройке FunPayCardinal. Проверьте зависимости и настройки.${RESET}"
  exit 2
fi

echo -e "${GREEN}Запускаю FunPayCardinal в screen сессии...${RESET}"
sudo -u "$username" screen -dmS fpc_"$username" bash -c "LANG=en_US.utf8 /home/\"$username\"/pyvenv/bin/python /home/\"$username\"/FunPayCardinal/main.py"

echo -e "${CYAN}################################################################################${RESET}"
echo -e "${CYAN}!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!!СДЕЛАЙ СКРИНШОТ!${RESET}"
echo ""
echo -e "${CYAN}Готово!${RESET}"
echo -e "${CYAN}FPC запущен в screen сессии fpc_$username${RESET}"
echo -e "${CYAN}Для подключения к сессии используй команду: sudo -u $username screen -r fpc_$username${RESET}"
echo -e "${CYAN}Для отсоединения от сессии нажми Ctrl+A D${RESET}"
echo -e "${CYAN}Для списка сессий используй: sudo -u $username screen -ls${RESET}"
echo -e "${CYAN}Теперь напиши своему Telegram-боту.${RESET}"
echo -e "${CYAN}################################################################################${RESET}"
echo -n -e "${CYAN}Сделал скриншот? Тогда нажми Enter, чтобы продолжить.${RESET}"
read