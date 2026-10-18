#!/bin/bash
TEST_LOG_DIR="./test_log"
TEST_BACKUP_DIR="/backup"
MAIN_SCRIPT="./main_backup.sh"
chmod +x "$MAIN_SCRIPT" 2>/dev/null
setup_env() {
rm -rf "$TEST_LOG_DIR"
mkdir -p "$TEST_LOG_DIR"
sudo rm -f "$TEST_BACKUP_DIR"/log_backup_*.tar.gz 2>/dev/null
}
echo "   СТАРТ ТЕСТОВ   "
setup_env
echo "Тест 1: Пустая папка"
$MAIN_SCRIPT -d "$TEST_LOG_DIR" -m 100 -t 50 -c 2
setup_env
echo "Тест 2: Превышение порога"
dd if=/dev/zero of="$TEST_LOG_DIR/old_file1.log" bs=1M count=5 2>/dev/null
touch -d "3 days ago" "$TEST_LOG_DIR/old_file1.log"
dd if=/dev/zero of="$TEST_LOG_DIR/new_file.log" bs=1M count=5 2>/dev/null
touch -d "1 day ago" "$TEST_LOG_DIR/new_file.log"
$MAIN_SCRIPT -d "$TEST_LOG_DIR" -m 10 -t 40 -c 1
LATEST_BACKUP=$(ls -t "$TEST_BACKUP_DIR"/log_backup_*.tar.gz 2>/dev/null | head -n 1)
if [ -f "$LATEST_BACKUP" ]; then
echo -e "\033[0;32m[PASS]\033[0m Архив создан: $LATEST_BACKUP"
else
echo -e "\033[0;31m[FAIL]\033[0m Архив не найден!"
fi

