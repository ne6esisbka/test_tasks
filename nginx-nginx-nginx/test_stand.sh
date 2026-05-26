#!/bin/bash

# Цвета для вывода в терминал
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # Без цвета

echo -e "${BLUE}=== ЗАПУСК ПРОТОКОЛА ТЕСТИРОВАНИЯ СТЕНДА ===${NC}\n"

# 1. Проверка статуса контейнеров
echo -e "${YELLOW}[Служебный шаг] Проверка статуса контейнеров в Docker Compose...${NC}"
if ! docker compose ps | grep -q "Up"; then
    echo -e "${RED}Ошибка: Контейнеры не запущены! Выполни 'docker compose up -d' перед тестом.${NC}"
    exit 1
fi
docker compose ps
echo ""

# 2. ТЕСТ №1: Прямой запрос пользователя через балансировщик (3 повторения для Round-Robin)
echo -e "${YELLOW}ТЕСТ №1: Обычный запрос пользователя через LB (Ожидается честный IP шлюза)${NC}"
for i in {1..3}; do
    RESPONSE=$(curl -s http://localhost:8080/)
    echo -e " Запрос $i: ${GREEN}$RESPONSE${NC}"
done
echo ""

# 3. ТЕСТ №2: Защита от подмены IP (Спуфинга) со стороны пользователя (3 повторения)
echo -e "${YELLOW}ТЕСТ №2: Защита от подмены IP (Юзер шлет фейк 9.9.9.9 -> Ожидается удаление фейка)${NC}"
for i in {1..3}; do
    RESPONSE=$(curl -s -H "X-Forwarded-For: 9.9.9.9" http://localhost:8080/)
    if echo "$RESPONSE" | grep -q "9.9.9.9"; then
        echo -e " Запрос $i: ${RED}ПРОПОРТИЛСЯ ФЕЙК! $RESPONSE${NC}"
    else
        echo -e " Запрос $i: ${GREEN}ЗАЩИЩЕНО (Фейк удален): $RESPONSE${NC}"
    fi
done
echo ""

# 4. ТЕСТ №3: Эмуляция внутренних цепочек через docker exec (Сверка связности прокси)
echo -e "${YELLOW}ТЕСТ №3: Эмуляция внутренней цепочки (nginx1 -> nginx3 -> app)${NC}"
# Ставим заголовок X-Real-IP, как будто его передал LB, чтобы эмулировать честное прохождение
INTERNAL_RESPONSE=$(docker exec -it nginx1 wget -qO- --header="X-Real-IP: 172.28.0.10" http://nginx3/)
echo -e " Ответ цепочки: ${GREEN}$INTERNAL_RESPONSE${NC}"

echo -e "${YELLOW}Финальный тест X-Forwarded-For: 9.9.9.9, 172.28.0.1 (nginx1 -> nginx3 -> app)"
FINALE_RESPONSE=$(docker exec -it nginx1 curl -s -H "X-Forwarded-For: 9.9.9.9, 172.28.0.1" -H "X-Next-Proxy: nginx2" http://nginx3/)
echo -e "${YELLOW}Ответ цепочки: ${GREEN}$FINALE_RESPONSE${NC}"

echo -e "${BLUE}=== ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===${NC}"
