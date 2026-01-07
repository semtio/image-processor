Image Processor — простой оптимизатор изображений и генератор миниатюр.

Сервер (пошагово)

1) Зайти на сервер по SSH
	Пример: ssh root@SERVER_IP

2) Выбрать папку установки приложения
	В этой папке будут лежать только файлы приложения. Системные пакеты (php, gd) ставятся в систему, а не в папку проекта.
	Примеры папок: /home/USER/web/DOMAIN/public_html/app

3) Перейти в выбранную папку
```
cd /home/USER/web/DOMAIN/public_html/app
```

4) Скопировать сюда файлы проекта (через git clone или загрузить архив и распаковать)
```
git clone https://github.com/ВАШ_АККАУНТ/image-processor.git .
```

5) Проверить, установлен ли PHP и модуль GD
```
php -v
php -m | grep gd
```
Если не установлено (Ubuntu/Debian), установить системно:
```
sudo apt update
sudo apt install -y php-cli php-gd
```

6) Создать файл настроек .env в корне приложения
```
echo "SERVER_IP=0.0.0.0" > .env
echo "SERVER_PORT=8001" >> .env
```
SERVER_IP — интерфейс для прослушивания (0.0.0.0 — на всех). SERVER_PORT — порт сервера.

7) Запустить приложение
Вариант 1 (простой, с заголовком и подсказками):
```
bash run.sh
```
Вариант 2 (в фоне, лог в server.log, продолжит работу после закрытия терминала):
```
nohup php -S "$SERVER_IP:$SERVER_PORT" -t web web/router.php > server.log 2>&1 & disown
```
Вариант 3 (еще один способ фонового запуска):
```
(php -S "$SERVER_IP:$SERVER_PORT" -t web web/router.php > server.log 2>&1 &)
```

8) Открыть порт в фаерволе (если требуется)
Ubuntu UFW:
```
sudo ufw allow $SERVER_PORT/tcp
```
iptables (общий случай):
```
sudo iptables -I INPUT -p tcp --dport $SERVER_PORT -j ACCEPT
```

9) Проверить, что приложение запущено
```
curl http://$SERVER_IP:$SERVER_PORT/api/config
ps aux | grep "php -S"
tail -n 50 server.log
```

10) Остановить приложение
```
pkill -f "php -S.*$SERVER_PORT"
```

11) Перезапустить приложение
```
pkill -f "php -S.*$SERVER_PORT" ; nohup php -S "$SERVER_IP:$SERVER_PORT" -t web web/router.php > server.log 2>&1 & disown
```

12) Автозапуск через systemd (опционально, для постоянной работы)
Создать файл службы:
```
sudo nano /etc/systemd/system/image-processor.service
```
Содержимое файла:
```
[Unit]
Description=Image Processor PHP Server
After=network.target

[Service]
Type=simple
User=ВАШ_ПОЛЬЗОВАТЕЛЬ
WorkingDirectory=/home/USER/web/DOMAIN/public_html/app
ExecStart=/usr/bin/php -S 0.0.0.0:8001 -t web web/router.php
Restart=always
StandardOutput=append:/home/USER/web/DOMAIN/public_html/app/server.log
StandardError=append:/home/USER/web/DOMAIN/public_html/app/server.log

[Install]
WantedBy=multi-user.target
```
Команды управления:
```
sudo systemctl daemon-reload
sudo systemctl enable image-processor  # автозапуск при загрузке системы
sudo systemctl start image-processor   # запустить
sudo systemctl stop image-processor    # остановить
sudo systemctl restart image-processor # перезапустить
sudo systemctl status image-processor  # проверить статус
```

Локальный запуск (WSL/Linux)

1) Установить пакеты
```
sudo apt update
sudo apt install -y php-cli php-gd
```
2) Перейти в папку проекта
```
cd /mnt/c/OSPanel/home/image-processor
```
3) Запустить
```
php -S 127.0.0.1:8000 -t web web/router.php
```
4) Открыть в браузере
```
http://127.0.0.1:8000
```
5) Остановить
В том же терминале: Ctrl+C



----

А теперь на практике, основные команды которые реально могут помочь
заходим в папку с прогой cd /home/admin/web/staycasino7.de/public_html/towebp/

CTRL + C
pkill -f "php -S"
git pull origin master
nohup bash run.sh > server.log 2>&1 & disown

Или напрямую запустить PHP-сервер в фоне:
```
nohup php -S 185.209.20.80:8082 -t web web/router.php > server.log 2>&1 & disown
```

Проверить работу:
```
ps aux | grep "php -S"
tail -f server.log
```
