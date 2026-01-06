# Инструкция по развёртыванию обновлений

## Workflow для работы с проектом

### 1. Настройка GitHub репозитория (один раз)

```bash
# На вашем компьютере
cd C:\OSPanel\home\image-processor

# Создать репозиторий на GitHub (через веб-интерфейс)
# Затем добавить remote
git remote add origin https://github.com/ваш-username/image-processor.git
git branch -M main
git push -u origin main
```

### 2. Настройка на сервере (один раз)

```bash
# На сервере подключиться по SSH
ssh root@185.209.20.80

# Перейти в директорию проекта
cd /root/image-processor

# Инициализировать git (если ещё не сделано)
git init

# Добавить remote
git remote add origin https://github.com/ваш-username/image-processor.git

# Получить изменения
git fetch origin
git reset --hard origin/main
```

### 3. Рабочий процесс обновлений

#### На вашем компьютере (Windows)

```bash
# 1. Внести изменения в код
# 2. Проверить изменения
git status

# 3. Добавить изменённые файлы
git add .

# 4. Создать коммит
git commit -m "Описание изменений"

# 5. Отправить на GitHub
git push origin main
```

#### На сервере (Linux)

```bash
# Подключиться к серверу
ssh root@185.209.20.80

# Перейти в директорию проекта
cd /root/image-processor

# Остановить сервер (если запущен через systemd)
sudo systemctl stop image-processor

# ИЛИ если запущен вручную, найти процесс и остановить
ps aux | grep "php -S"
kill [PID]

# Получить обновления с GitHub
git pull origin main

# Запустить сервер снова
sudo systemctl start image-processor
# ИЛИ
bash run.sh
```

### 4. Автоматизация обновлений (опционально)

Создайте скрипт `update.sh` на сервере:

```bash
#!/bin/bash
echo "Обновление Image Processor..."

# Остановить сервис
systemctl stop image-processor 2>/dev/null

# Получить изменения
cd /root/image-processor
git pull origin main

# Запустить сервис
systemctl start image-processor 2>/dev/null || bash run.sh &

echo "Обновление завершено!"
```

Использование:
```bash
ssh root@185.209.20.80 "bash /root/image-processor/update.sh"
```

### 5. Важные заметки

**Файлы, которые НЕ попадают в Git (.gitignore):**
- `uploads/` - загруженные изображения
- `output/` - сгенерированные миниатюры
- `.env` - конфигурация с IP-адресом
- `*.log` - логи

**Перед первым push создайте `.env` на сервере:**
```bash
# На сервере
echo "SERVER_IP=185.209.20.80" > /root/image-processor/.env
echo "SERVER_PORT=8000" >> /root/image-processor/.env
```

### 6. Проверка работы

После обновления проверьте:
```bash
# Проверить, что сервер запущен
ps aux | grep "php -S"

# Проверить доступность
curl http://185.209.20.80:8000/
```

Или откройте в браузере: http://185.209.20.80:8000/
