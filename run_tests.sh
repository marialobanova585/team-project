#!/bin/bash
TEST_LOG_DIR="./test_log"
TEST_BACKUP_DIR="/backup"
MAIN_SCRIPT="./main_backup.sh"
START_TIME=$(date +%s)
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; }
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "Ошибка: нет файла $MAIN_SCRIPT"
    exit 1
fi
chmod +x "$MAIN_SCRIPT"
clean_archives() {
    find "$TEST_BACKUP_DIR" -maxdepth 1 -name '*.tar.gz' -newermt "@$START_TIME" -delete 2>/dev/null
}
setup() {
    rm -rf "$TEST_LOG_DIR"
    mkdir -p "$TEST_LOG_DIR"
    clean_archives
}
echo "Тест 1: лимит не превышен"
setup
touch "$TEST_LOG_DIR/file1.log"
"$MAIN_SCRIPT" "$TEST_LOG_DIR" 99 1
rc=$?
if [ $rc -ne 0 ]; then
    fail "main_backup.sh завершился с ошибкой (код $rc)"
elif [ -z "$(find "$TEST_BACKUP_DIR" -maxdepth 1 -name '*.tar.gz' -newermt "@$START_TIME" 2>/dev/null)" ]; then
    pass "новый архив не создан"
else
    fail "архив создан, хотя не должен был"
fi
echo
echo "Тест 2: лимит превышен"
setup
touch -d "2 days ago" "$TEST_LOG_DIR/old1.log"
touch -d "2 days ago" "$TEST_LOG_DIR/old2.log"
touch                  "$TEST_LOG_DIR/new.log"
"$MAIN_SCRIPT" "$TEST_LOG_DIR" 0 2
rc=$?
if [ $rc -ne 0 ]; then
    fail "main_backup.sh завершился с ошибкой (код $rc)"
else
    ARCHIVE=$(find "$TEST_BACKUP_DIR" -maxdepth 1 -name '*.tar.gz' -newermt "@$START_TIME" 2>/dev/null | head -n1)
    if [ -z "$ARCHIVE" ]; then
        fail "архив не создан"
    else
        pass "архив создан"
        if [ ! -f "$TEST_LOG_DIR/old1.log" ] && [ ! -f "$TEST_LOG_DIR/old2.log" ] && [ -f "$TEST_LOG_DIR/new.log" ]; then
            pass "старые файлы удалены, новый сохранён"
        else
            fail "неверный набор файлов после архивации"
        fi
    fi
fi
clean_archives
rm -rf "$TEST_LOG_DIR"
echo
echo "Готово"
