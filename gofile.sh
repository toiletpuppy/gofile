#!/bin/bash
set -e

# Define color codes for output
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

display_usage() {
    echo -e "${YELLOW}Usage Instructions:${NC}"
    echo -e "${CYAN}Provide the 'files' input as a space-separated list of file paths to upload.${NC}"
}

human_readable_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size} bytes"
    elif [ "$size" -lt 1048576 ]; then
        echo "$(echo "scale=2; $size/1024" | bc) KB"
    elif [ "$size" -lt 1073741824 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc) MB"
    else
        echo "$(echo "scale=2; $size/1073741824" | bc) GB"
    fi
}

install_jq() {
    echo -e "${CYAN}jq is required for JSON parsing. Installing jq...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    else
        echo -e "${RED}Error: Unsupported package manager. jq cannot be installed automatically.${NC}"
        exit 1
    fi
}

install_bc() {
    echo -e "${CYAN}bc is required for size calculations. Installing bc...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y bc
    else
        echo -e "${RED}Error: Unsupported package manager. bc cannot be installed automatically.${NC}"
        exit 1
    fi
}

check_dependencies() {
    if ! command -v jq &> /dev/null; then
        install_jq
    fi
    if ! command -v bc &> /dev/null; then
        install_bc
    fi
}

# If the GitHub Action input "files" is set (via the environment variable INPUT_FILES),
# then convert it to positional parameters.
if [ -n "$INPUT_FILES" ]; then
    # Using eval ensures that any spaces in the input are handled correctly.
    eval set -- "$INPUT_FILES"
fi

if [[ "$#" -eq 0 ]]; then
    display_usage
    exit 1
fi

check_dependencies

# Retrieve a random GoFile server.
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers | map(.name) | .[]' | shuf -n 1)
if [[ -z "$SERVER" || "$SERVER" == "null" ]]; then
    echo -e "${RED}Error: Could not retrieve GoFile server information.${NC}"
    exit 1
fi

echo -e "${GREEN}Using server:${NC} ${YELLOW}${SERVER}${NC}"

success_count=0
total_files=$#
file_number=0

is_multiple_files=false
if [[ "$total_files" -gt 1 ]]; then
    is_multiple_files=true
fi

for file in "$@"; do
    file_number=$((file_number + 1))

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error - File \"$file\" not found! Skipping...${NC}"
        continue
    fi

    filename=$(basename "$file")
    filesize=$(wc -c < "$file")
    human_size=$(human_readable_size $filesize)
    extension="${filename##*.}"
    md5sum=$(md5sum "$file" | awk '{ print $1 }')

    if $is_multiple_files; then
        echo -e "• ${YELLOW}$file_number:${NC} Uploading file ${YELLOW}$filename${NC}"
    else
        echo -e "Uploading file ${YELLOW}$filename${NC}"
    fi

    response=$(curl -s -# -F "file=@$file" "https://${SERVER}.gofile.io/uploadFile")

    if echo "$response" | grep -q '"status":"ok"'; then
        download_link=$(echo "$response" | jq -r '.data.downloadPage')
        echo ""
        echo -e "${GREEN}Name:${NC} ${CYAN}$filename${NC}"
        echo -e "${GREEN}File size:${NC} ${CYAN}$human_size${NC}"
        echo -e "${GREEN}File type:${NC} ${CYAN}$extension${NC}"
        echo -e "${GREEN}Md5sum:${NC} ${CYAN}$md5sum${NC}"
        echo -e "${GREEN}File URL:${NC} ${YELLOW}$download_link${NC}"
        success_count=$((success_count + 1))
    else
        echo -e "${RED}Error: Failed to upload $filename${NC}"
    fi
    echo ""
done

echo -e "${CYAN}Upload Status:${NC} ${GREEN}$success_count of $total_files files uploaded successfully.${NC}"
