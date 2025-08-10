#!/usr/bin/env bash

# 定義顏色常量
readonly GREEN='\033[32m'
readonly RED='\033[31m'
readonly NC='\033[0m' # No Color

# --- 檢查函數 ---

# 檢查是否為 root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}錯誤：此腳本必須以 root 身份運行！${NC}"
        exit 1
    fi
}

# 檢查是否為 OpenVZ
check_ovz() {
    if [[ -d /proc/vz ]]; then
        echo -e "${RED}您的 VPS 基於 OpenVZ，不支持！${NC}"
        exit 1
    fi
}

# --- 功能函數 ---

# 添加 Swap 空間
add_swap() {
    # 如果 swapfile 已存在，直接返回
    if [[ -f /swapfile ]]; then
        echo -e "${RED}錯誤：swapfile 已存在。請先刪除現有 swap！${NC}"
        return
    fi

    echo -e "${GREEN}請輸入要添加的 swap 大小，建議為內存的2倍：${NC}"
    read -p "大小: " swapsize

    # 驗證輸入是否為有效數字
    if ! [[ "$swapsize" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}錯誤：請輸入有效的數字！${NC}"
        return
    fi

    echo -e "${GREEN}正在創建 ${swapsize}MB 的 swapfile...${NC}"
    # 創建、設置權限、格式化並啟用 swap
    fallocate -l "${swapsize}" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # 添加到 fstab 以便開機自動掛載
    echo '/swapfile none swap defaults 0 0' >> /etc/fstab

    echo -e "${GREEN}Swap 創建成功。當前狀態：${NC}"
    swapon --show
    grep SwapTotal /proc/meminfo
}

# 刪除 Swap 空間
remove_swap() {
    # 如果 swapfile 不存在，直接返回
    if [[ ! -f /swapfile ]]; then
        echo -e "${RED}錯誤：未找到 swapfile，無需刪除！${NC}"
        return
    fi

    echo -e "${GREEN}正在移除 swap...${NC}"
    # 停用 swap，並從 fstab 和檔案系統中刪除
    swapoff /swapfile
    sed -i '/swapfile/d' /etc/fstab
    rm -f /swapfile

    echo -e "${GREEN}Swap 刪除成功。${NC}"
}

# --- 主程式 ---

main() {
    check_root
    check_ovz

    while true; do
        clear
        echo -e "---"
        echo -e "${GREEN}Linux VPS 一鍵添加/刪除 Swap 腳本${NC}"
        echo -e "1) 添加 Swap"
        echo -e "2) 刪除 Swap"
        echo -e "3) 退出"
        echo -e "---"

        read -p "請輸入選項 [1-3]: " choice

        case "$choice" in
            1) add_swap ;;
            2) remove_swap ;;
            3) exit 0 ;;
            *) echo -e "${RED}無效的選項，請重新輸入！${NC}" && sleep 1 ;;
        esac

        read -p "按 Enter 鍵繼續..."
    done
}

main
