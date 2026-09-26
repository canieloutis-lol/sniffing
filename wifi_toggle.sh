#!/bin/bash

# Script otomatis untuk mengubah mode kartu jaringan Wi-Fi (wlp1s0)
# Jalankan dengan: sudo ./wifi_toggle.sh

INTERFACE="wlp1s0"

show_help() {
    echo "Penggunaan: sudo $0 [monitor|managed|status]"
    echo "  monitor : Mengubah kartu Wi-Fi ke Monitor Mode"
    echo "  managed : Mengubah kartu Wi-Fi ke Mode Normal (Internet)"
    echo "  status  : Mengecek status mode kartu Wi-Fi saat ini"
}

if [ "$EUID" -ne 0 ]; then
    echo "❌ Silakan jalankan script ini dengan akses root (sudo)."
    exit 1
fi

case "$1" in
    monitor)
        echo "🔄 Mengaktifkan Monitor Mode pada $INTERFACE..."
        systemctl stop NetworkManager
        ip link set $INTERFACE down
        iw $INTERFACE set type monitor
        ip link set $INTERFACE up
        echo "✅ Monitor Mode Berhasil Diaktifkan!"
        iwconfig $INTERFACE | grep -i "mode"
        ;;
    managed)
        echo "🔄 Mengembalikan ke Managed Mode (Normal) pada $INTERFACE..."
        ip link set $INTERFACE down
        iw $INTERFACE set type managed
        ip link set $INTERFACE up
        systemctl start NetworkManager
        echo "✅ Mode Normal Berhasil Dipulihkan! Menghubungkan ulang ke internet..."
        sleep 2
        iwconfig $INTERFACE | grep -i "mode"
        ;;
    status)
        echo "📊 Status kartu jaringan saat ini:"
        iwconfig $INTERFACE 2>/dev/null || ip link show $INTERFACE
        ;;
    *)
        show_help
        ;;
esac
