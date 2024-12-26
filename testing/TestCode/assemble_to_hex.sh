#!/bin/bash

# Check if an input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <assembly_file.s>"
    exit 1
fi

input_file="$1"
base_name=$(basename "$input_file" .s)
output_file="${base_name}.hex"  # _be indicates big-endian
temp_o="temp.o"
temp_bin="temp.bin"

# 1) Assemble the .s file into an object
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o "$temp_o" "$input_file" || {
    echo "Assembly failed"
    exit 1
}

# 2) Extract only the .text section into a raw binary
riscv64-unknown-elf-objcopy -O binary --only-section=.text "$temp_o" "$temp_bin" || {
    echo "Objcopy failed"
    exit 1
}

# 3) Convert the binary to a little-endian hex dump
little_endian_hex=$(xxd -p "$temp_bin" | tr -d '\n')

# 4) Convert little-endian hex to big-endian hex
# Process each 8-character (4-byte) chunk and reverse byte order
big_endian_hex=""
for (( i=0; i<${#little_endian_hex}; i+=8 )); do
    chunk=${little_endian_hex:i:8}
    if [ ${#chunk} -lt 8 ]; then
        # Pad the last chunk if it's less than 8 characters
        chunk=$(printf "%-8s" "$chunk" | tr ' ' '0')
    fi
    # Reverse the byte order: AB CD EF GH -> GH EF CD AB
    byte1=${chunk:0:2}
    byte2=${chunk:2:2}
    byte3=${chunk:4:2}
    byte4=${chunk:6:2}
    big_endian_hex+="${byte4}${byte3}${byte2}${byte1}"
done

# 5) Write the big-endian hex to the output file
echo "$big_endian_hex" > "$output_file"

# 6) Clean up temporary files
rm "$temp_o" "$temp_bin"

echo "Big-endian machine code written to $output_file"
