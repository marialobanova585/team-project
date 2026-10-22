#!/bin/bash
TEST_LOG_DIR="./test_log"
TEST_BACKUP_DIR="/backup"
MAIN_SCRIPT="./main_backup.sh"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
chmod +x "$MAIN_SCRIPT" 2>/dev/null
setup_env() {
    sudo rm -rf "$TEST_LOG_DIR"
    mkdir -p "$TEST_LOG_DIR"
    sudo rm -f "$TEST_BACKUP_DIR"/archive_*.tar.gz 2>/dev/null
}
echo " СТАРТ ТЕСТОВ"
setup_env
touch "$TEST_LOG_DIR/dummy.log"
echo "Выполнение Теста 1"
sudo "$MAIN_SCRIPT" "$TEST_LOG_DIR" 99 1
if [ -z "$(sudo find "$TEST_BACKUP_DIR" -maxdepth 1 -name "archive_*.tar.gz" 2>/dev/null)" ]; then
    echo -e "${GREEN}[PASS] Тест 1 пройден: архив не создавался.${NC}"
else
    echo -e "${RED}[FAIL] Тест 1 провален: архив обнаружился в /backup!${NC}"
fi
setup_env
touch "$TEST_LOG_DIR/old_file1.log"
sleep 1.5
touch "$TEST_LOG_DIR/old_file2.log"
sleep 1.5
touch "$TEST_LOG_DIR/new_file.log"
echo -e "\nВыполнение Теста 2 "
sudo "$MAIN_SCRIPT" "$TEST_LOG_DIR" 0 2
LATEST_BACKUP=$(sudo ls -t "$TEST_BACKUP_DIR"/archive_*.tar.gz 2>/dev/null | head -n 1)
if [ -n "$LATEST_BACKUP" ]; then
    echo -e "${GREEN}[PASS] Тест 2 пройден: Архив успешно создан -> $LATEST_BACKUP${NC}"
    ARCHIVE_CONTENT=$(sudo tar -tf "$LATEST_BACKUP" | awk -F/ '{print $NF}' | sort | xargs)
    echo "Содержимое созданного архива: $ARCHIVE_CONTENT"
    if [[ "$ARCHIVE_CONTENT" == *"old_file1.log"* ]] && [[ "$ARCHIVE_CONTENT" == *"old_file2.log"* ]]; then
        echo -e "${GREEN}[PASS] Валидация результатов: в архив попали самые старые файлы.${NC}"
    else
        echo -e "${RED}[FAIL] Ошибка контроля результатов: файлы отфильтрованы неверно!${NC}"
    fi
else
    echo -e "${RED}[FAIL] Тест 2 провален: архив не был найден в $TEST_BACKUP_DIR${NC}"
fi
echo -e "\n ТЕСТИРОВАНИЕ ЗАВЕРШЕНО "
