#!/bin/bash

### Определение цветовых кодов ###
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

### Цветные функции ##
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }


CONSUL_VERSION="1.20.0"
DATA_DIR="/opt/consul"
LOG_DIR="/var/log/consul"
CONFIG_DIR="/etc/consul.d"

# Определяем текущий узел по имени хоста
case $(hostname) in
  node-vm01) NODE_IP="10.100.10.1" ;;
  node-vm02) NODE_IP="10.100.10.2" ;;
  node-vm03) NODE_IP="10.100.10.3" ;;
  *) echo "Хост неизвестен! Скрипт поддерживает только node-vm01, node-vm02, node-vm03." && exit 1 ;;
esac

# Установка необходимых пакетов
magentaprint "Установка необходимых пакетов"
dnf install -y wget unzip firewalld

magentaprint "Загрузка и установка Consul"
# Загрузка и установка Consul
# wget https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
# unzip consul_${CONSUL_VERSION}_linux_amd64.zip
cd /tmp
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
mv consul /usr/bin/
chmod +x /usr/bin/consul

# Создание пользователя и директорий
magentaprint "Создание пользователя и директорий"
useradd -r -d ${DATA_DIR} -s /bin/false consul
mkdir -p ${DATA_DIR} ${CONFIG_DIR} ${LOG_DIR}
chown -R consul:consul ${DATA_DIR} ${CONFIG_DIR} ${LOG_DIR}

# Настройка firewall
magentaprint "Настройка firewall"
systemctl enable firewalld --now
firewall-cmd --permanent --add-port=8300/tcp
firewall-cmd --permanent --add-port=8301/tcp
firewall-cmd --permanent --add-port=8301/udp
firewall-cmd --permanent --add-port=8302/tcp
firewall-cmd --permanent --add-port=8302/udp
firewall-cmd --permanent --add-port=8500/tcp
firewall-cmd --permanent --add-port=8600/tcp
firewall-cmd --permanent --add-port=8600/udp
firewall-cmd --reload
firewall-cmd --list-all

# Создание конфигурационного файла
magentaprint "Создание конфигурационного файл"
cat <<EOF > ${CONFIG_DIR}/consul.hcl
datacenter = "dc1"              # Имя датацентра, к которому принадлежит этот узел
data_dir = "${DATA_DIR}"        # Путь к директории, где Consul будет хранить свои данные
log_level = "INFO"              # Уровень логирования (DEBUG, INFO, WARN, ERROR)
node_name = "$(hostname)"       # Уникальное имя узла, берётся из имени хоста
bind_addr = "${NODE_IP}"        # IP-адрес, на котором Consul будет слушать входящие соединения

# client_addr = "0.0.0.0"       # Разрешает Consul принимать соединения на всех интерфейсах (для тестирования)
log_file = "${LOG_DIR}"         # Путь к файлу логов
log_rotate_duration = "24h"     # Интервал ротации логов (каждые 24 часа)

server = true                   # Режим работы Consul как сервера (true) или агента (false)
# bootstrap = true              # Разрешает первичный запуск Consul-сервера без кворума (использовать осторожно)
bootstrap_expect = 3            # Количество ожидаемых серверных узлов для формирования кворума кластера
retry_join = ["10.100.10.1", "10.100.10.2", "10.100.10.3"] # Список IP-адресов других серверных узлов для автоматического подключения к кластеру

ui_config {                     # Конфигурация веб-интерфейса
  enabled = true                # Включение встроенного веб-интерфейса Consul
}
EOF

# Создание systemd-сервиса
magentaprint "Создание юнита"
cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul $CONSUL_VERSION
After=network.target

[Service]
User=consul
Group=consul
ExecStart=/usr/bin/consul agent -config-dir=${CONFIG_DIR} -log-file=${LOG_DIR}/consul.log
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Отключение SELinux:
disable_selinux() {
    magentaprint "Отключаем SELinux..."
    # Проверка, существует ли файл конфигурации SELinux
    if [ -f /etc/selinux/config ]; then
        # Изменение строки SELINUX= на SELINUX=disabled
        sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        redprint "SELinux был отключен. Перезагрузите систему для применения изменений."
    else
        magentaprint "Файл конфигурации SELinux не найден."
    fi
}
disable_selinux

# Запуск Consul
magentaprint "Запуск Consul"
systemctl daemon-reload
systemctl enable --now consul

magentaprint "Проверка статуса Consul"
systemctl status consul --no-page

magentaprint "Consul установлен и запущен на $(hostname) (${NODE_IP})!"
