# Image Processor - MVP

Короткая инструкция по запуску и управлению.

## Server (start/stop/restart/check)

1. Подготовка
	- Установлены PHP и GD: `php -v`, `php -m | grep gd`
	- В корне `.env`:
	  ```bash
	  SERVER_IP=185.209.20.80
	  SERVER_PORT=8001
	  ```
2. Старт
	```bash
	bash run.sh
	# альтернатива (в фоне с логом)
	nohup php -S "$SERVER_IP:$SERVER_PORT" -t web web/router.php > server.log 2>&1 &
	```
3. Стоп
	```bash
	pkill -f "php -S.*$SERVER_PORT"
	# или
	ps aux | grep "php -S" | grep $SERVER_PORT
	kill <PID>
	```
4. Рестарт
	```bash
	pkill -f "php -S.*$SERVER_PORT" ; nohup php -S "$SERVER_IP:$SERVER_PORT" -t web web/router.php > server.log 2>&1 &
	```
5. Проверка
	```bash
	curl http://$SERVER_IP:$SERVER_PORT/api/config
	ps aux | grep "php -S"
	tail -n 50 server.log
	```

## Local (WSL/Unix)

1. Установить зависимости
	```bash
	sudo apt update && sudo apt install -y php-cli php-gd
	```
2. Старт
	```bash
	php -S 127.0.0.1:8000 -t web web/router.php
	```
3. Открыть в браузере
	```
	http://127.0.0.1:8000
	```
4. Стоп
	- В терминале: Ctrl+C

