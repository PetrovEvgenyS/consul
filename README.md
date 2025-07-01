# Установка и настройка Consul на AlmaLinux

Этот скрипт автоматизирует установку и базовую настройку Consul в режиме сервера на дистрибутиве AlmaLinux для трёх узлов (node-vm01, node-vm02, node-vm03).

## Возможности скрипта
- Установка необходимых пакетов (wget, unzip, firewalld)
- Загрузка и установка Consul
- Создание пользователя и директорий для Consul
- Настройка firewall для необходимых портов
- Генерация базового конфига Consul
- Создание systemd unit-файла для Consul
- Отключение SELinux
- Запуск и проверка статуса Consul

## Использование
1. Скопируйте скрипт на сервер AlmaLinux (node-vm01, node-vm02 или node-vm03).
2. Скачайте архив Consul соответствующей версии в /tmp (или раскомментируйте строки загрузки в скрипте).
    - Sanctions: This content is not currently available in your region.
3. Дайте права на исполнение: `chmod +x install_consul_almalinux.sh`
4. Запустите от root: `sudo ./install_consul_almalinux.sh`

## Важно
- Скрипт определяет IP-адрес по имени хоста. Поддерживаются только node-vm01, node-vm02, node-vm03.
- Для применения отключения SELinux требуется перезагрузка.
- После установки веб-интерфейс Consul будет доступен на порту 8500.

## Порты Consul
- 8300/tcp — серверный RPC
- 8301/tcp+udp — LAN-синхронизация
- 8302/tcp+udp — WAN-синхронизация
- 8500/tcp — HTTP API и UI
- 8600/tcp+udp — DNS

## Пример запуска
```bash
sudo ./install_consul_almalinux.sh
```
