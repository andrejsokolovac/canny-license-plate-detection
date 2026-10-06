#!/bin/bash

set -euo pipefail

PROJECT_DIR="/home/alarm/canny_linux_project"

BITSTREAM_NAME="design_1_wrapper.bit.bin"
BITSTREAM_SRC="$PROJECT_DIR/bitstream/$BITSTREAM_NAME"
BITSTREAM_DST="/lib/firmware/$BITSTREAM_NAME"

FPGA_FIRMWARE="/sys/class/fpga_manager/fpga0/firmware"
FPGA_STATE="/sys/class/fpga_manager/fpga0/state"

CANNY_COMPATIBLE="/sys/firmware/devicetree/base/amba_pl/canny_axi@43c00000/compatible"
EXPECTED_COMPATIBLE="xlnx,canny-axi-1.0"

DRIVER_KO="$PROJECT_DIR/driver/canny_driver.ko"
APP="$PROJECT_DIR/app/canny_app"

INPUT_IMG="$PROJECT_DIR/data/grayscale_full_zybo.txt"
OUTPUT_IMG="$PROJECT_DIR/data/final_edge_hardware_zybo.txt"
REFERENCE_IMG="$PROJECT_DIR/data/final_edge_full_zybo.txt"

LOW_THRESHOLD="${1:-50}"
HIGH_THRESHOLD="${2:-100}"

error_exit()
{
    echo "ERROR: $1" >&2
    exit 1
}

check_file()
{
    [ -f "$1" ] || error_exit "Nedostaje fajl: $1"
}

check_threshold()
{
    case "$1" in
        ""|*[!0-9]*)
            error_exit "$2 prag mora biti ceo broj od 0 do 255."
            ;;
    esac

    [ "$1" -le 255 ] ||
        error_exit "$2 prag mora biti u opsegu 0-255."
}

echo "=== Canny project run ==="

[ "$(id -u)" -eq 0 ] ||
    error_exit "Skripta mora biti pokrenuta kao root."

check_threshold "$LOW_THRESHOLD" "LOW"
check_threshold "$HIGH_THRESHOLD" "HIGH"

[ "$LOW_THRESHOLD" -le "$HIGH_THRESHOLD" ] ||
    error_exit "LOW prag ne sme biti veci od HIGH praga."

check_file "$BITSTREAM_SRC"
check_file "$DRIVER_KO"
check_file "$APP"
check_file "$INPUT_IMG"
check_file "$REFERENCE_IMG"

[ -e "$FPGA_FIRMWARE" ] ||
    error_exit "FPGA Manager firmware interfejs nije dostupan."

[ -r "$FPGA_STATE" ] ||
    error_exit "FPGA Manager state nije dostupan."

[ -r "$CANNY_COMPATIBLE" ] ||
    error_exit "Canny device-tree cvor nije aktivan."

ACTIVE_COMPATIBLE=$(tr -d '\0' < "$CANNY_COMPATIBLE")

[ "$ACTIVE_COMPATIBLE" = "$EXPECTED_COMPATIBLE" ] ||
    error_exit "Aktivan device-tree nije Canny: $ACTIVE_COMPATIBLE"

echo "Device tree: $ACTIVE_COMPATIBLE"
echo "Thresholds: LOW=$LOW_THRESHOLD HIGH=$HIGH_THRESHOLD"

echo "[1/6] Preparing kernel modules..."

if lsmod | awk '{print $1}' | grep -qx "canny_driver"; then
    echo "Removing previously loaded canny_driver..."
    rmmod canny_driver
fi

echo "[2/6] Loading Canny FPGA bitstream..."

if [ ! -f "$BITSTREAM_DST" ] ||
   ! cmp -s "$BITSTREAM_SRC" "$BITSTREAM_DST"; then
    cp "$BITSTREAM_SRC" "$BITSTREAM_DST"
else
    echo "Bitstream is already present in /lib/firmware."
fi

echo "$BITSTREAM_NAME" > "$FPGA_FIRMWARE"

STATE=$(cat "$FPGA_STATE")
echo "FPGA state: $STATE"

[ "$STATE" = "operating" ] ||
    error_exit "FPGA is not in operating state."

echo "[3/6] Loading Canny kernel driver..."

insmod "$DRIVER_KO"

lsmod | awk '{print $1}' | grep -qx "canny_driver" ||
    error_exit "canny_driver nije ucitan."

echo "[4/6] Checking device files..."

for device in /dev/canny_ctrl /dev/canny_input /dev/canny_edge; do
    [ -c "$device" ] ||
        error_exit "Nedostaje character device: $device"
done

ls -lh /dev/canny_ctrl /dev/canny_input /dev/canny_edge

echo "[5/6] Running Canny application..."

"$APP" \
    "$INPUT_IMG" \
    "$OUTPUT_IMG" \
    "$LOW_THRESHOLD" \
    "$HIGH_THRESHOLD" \
    "$REFERENCE_IMG"

echo "[6/6] Hardware output file..."

check_file "$OUTPUT_IMG"

OUTPUT_LINES=$(wc -l < "$OUTPUT_IMG")
echo "Output: $OUTPUT_IMG"
echo "Pixels written: $OUTPUT_LINES"

[ "$OUTPUT_LINES" -eq 12288 ] ||
    error_exit "Izlazni fajl nema 12288 piksela."

echo "=== CANNY RUN COMPLETED SUCCESSFULLY ==="
