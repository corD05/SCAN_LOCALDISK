#!/bin/bash

# Fungsi untuk mencari folder atau file yang melebihi batas
cari_folder_file() {
    local path=$1
    local batas_folder=$2
    local batas_file=$3
    local daftar=$(find "$path" -mindepth 1 -type d -size +$batas_folder -exec du -sh {} + 2>/dev/null | grep -v '^[[:space:]]*0[[:space:]]*')
    daftar+=$(find "$path" -type f -size +${batas_file}M -exec du -h {} + 2>/dev/null | awk '{ if($1~/G/) {print "\033[1;31m" $0 "\033[0m"} else if ($1~/M/) {print "\033[1;33m" $0 "\033[0m"} else {print $0}}' | grep -v '^[[:space:]]*0[[:space:]]*')
    if [ -n "$daftar" ]; then
        echo "Folder atau file yang melebihi batas kapasitas di $path:"
        echo "$daftar"
    else
        echo "Tidak ada folder atau file yang melebihi batas kapasitas di $path"
    fi
}

# Cek apakah script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Script harus dijalankan sebagai root" 1>&2
    exit 1
fi

# Mendapatkan daftar semua disk
daftar_disk=$(df -h | awk '{if(NR>1 && $5+0 >= 70) print $6}')

# Inisialisasi variabel untuk menandai apakah ada disk yang penuh
disk_penuh=0

# Loop melalui setiap disk
for disk in $daftar_disk; do
    # Mendapatkan persentase penggunaan disk
    persentase=$(df -h "$disk" | awk '{if(NR>1)print $5}')

    # Ambil hanya nilai numerik dari persentase
    persentase_numerik=$(echo "$persentase" | tr -d '%')

    # Tentukan batas persentase yang dianggap "penuh" (misal: 70%)
    batas_persentase="70"

    # Bandingkan persentase penggunaan disk dengan batas
    if [[ "$persentase_numerik" -ge "$batas_persentase" ]]; then
        echo "Disk $disk mencapai $persentase penggunaan"

        # Panggil fungsi untuk mencari folder atau file yang menyebabkan disk penuh
        cari_folder_file "$disk" "10G" "300"
        disk_penuh=1
    fi
done

# Jika tidak ada disk yang penuh, beri tahu pengguna
if [ $disk_penuh -eq 0 ]; then
    echo "Tidak ada disk yang mencapai batas penggunaan."
fi
