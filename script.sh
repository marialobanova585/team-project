
folder_path="$1"
N_percent="$2"
M_files="$3"
if [ -z "$folder_path" ] || [ -z "$N_percent" ] || [ -z "$M_files" ]; then
    echo "=== Ввод параметров ==="
    echo -n "Введи путь к папке: "
    read folder_path
    echo -n "Введите порог заполнения: "
    read N_percent
    echo -n "Введите количество старых файлов: "
    read M_files
fi
if [ ! -d "$folder_path" ]; then
    echo "Папка $folder_path не существует"
    exit 1
fi
disk_usage=$(df "$folder_path" | tail -n 1 | awk '{print $5}' | tr -d '%')
if [ -z "$disk_usage" ]; then disk_usage=0; fi

echo "Текущее заполнение: $disk_usage%"

if [ "$disk_usage" -gt "$N_percent" ]; then
    echo "Порог превышен, происходит архивация"
   
    sudo mkdir -p /backup
    sudo chmod 777 /backup
    
    cd "$folder_path" || exit 1
   
    old_files_list=$(ls -pt | grep -v / | tail -n "$M_files" | xargs)
    
    if [ -z "$old_files_list" ]; then
        echo "Файлы не найдены"
        exit 0
    fi
  
    archive_name="/backup/archive_$(date "+%Y%m%d_%H%M%S").tar.gz"
   
    tar -czf "$archive_name" $old_files_list 2>/dev/null
    rm -f $old_files_list
    
    echo "Успешно заархивировано и очищено"
else
    echo "Заполнение в норме"
fi

