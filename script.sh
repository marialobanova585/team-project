
if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]; then
folder_path="$1"
N_percent="$2"
M_files="$3"
else
echo "Ввод параметров"
echo -n "Введи путь к папке"
read folder_path
echo -n "Введите порог заполнения"
read N_percent
echo -n "Введите колличество старых файлов"
read M_files
fi
if [ ! -d "$folder_path" ]; then
echo "Папка $folder_path не существует"
exit 1
fi
df "$folder_path" > /tmp/df_out.txt
disk_line=$(tail -n 1 /tmp/df_out.txt)
disk_usage=$(echo "$disk_line" | awk '{print $5}' | tr -d '%')
echo "Текущее заполнение: $disk_usage%"
if [ "$disk_usage" -gt "$N_percent" ]; then
echo "Порог превышен, происходит архивация"
mkdir -p /backup
cd "$folder_path"
ls -pt > /tmp/files_all.txt
grep -v / /tmp/files_all.txt > /tmp/files_only.txt
old_files_list=$(tail -n "$M_files" /tmp/files_only.txt)
if [ -z "$old_files_list" ]; then
echo "Файлы не найдены"
exit 0
fi
archive_name="/backup/archive_$(date "+%Y%m%d_%H%M%S").tar.gz"
tar -czf "$archive_name" $old_files_list
rm -f $old_files_list
echo "Успешно заархивировано и очищено"
else
echo "Заполнение в норме"
fi

