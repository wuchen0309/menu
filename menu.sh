#!/bin/bash

# Termux菜单式一键脚本

# ==== 彩色输出定义 ====
YELLOW='\033[1;33m'
GREEN='\033[38;5;40m'
BLUE='\033[38;5;33m'
MAGENTA='\033[38;5;129m'
CYAN='\033[38;5;44m'
BRIGHT_BLUE='\033[38;5;39m'
BRIGHT_MAGENTA='\033[38;5;135m'
BRIGHT_CYAN='\033[38;5;51m'
BRIGHT_GREEN='\033[38;5;46m'
BRIGHT_RED='\033[38;5;196m'
BOLD='\033[1m'
NC='\033[0m'

# 启动时自动清屏
clear

# 强制二选一函数 (y/n)
confirm_choice() {
    local prompt="$1"
    local choice
    
    while true; do
        echo -ne "$prompt"
        read -r choice
        # 转换为小写并去除前后空格
        choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]' | xargs)
        
        case "$choice" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                echo -e "${RED}请输入 y/yes 或 n/no！${NC}"
                ;;
        esac
    done
}

# 初始化备份脚本（如果不存在）
init_backup_script() {
    local backup_script="$HOME/backup_sillytavern.sh"
    if [ ! -f "$backup_script" ]; then
        echo -e "${YELLOW}${BOLD}创建备份脚本...${NC}"
        cat > "$backup_script" << 'EOF'
#!/bin/bash

# 源目录：SillyTavern 数据在 Termux 主目录下的路径
src_dir="$HOME/SillyTavern/data/default-user/"

# 临时中转目录（Termux 内部）
tmp_dir="$HOME/tmp_sillytavern_backup_copy"

# 备份目标目录：内部共享存储下的 "MySillyTavernBackups" 文件夹
# 通过 Termux 的 storage 符号链接访问
backup_dir_base="$HOME/storage/shared/"
backup_dir_name="MySillyTavernBackups"
backup_dir="${backup_dir_base}${backup_dir_name}"

# 设置备份压缩包的文件名格式（包含时间戳）
timestamp=$(date +%Y%m%d_%H%M%S)
backup_name="sillytavern_backup_$timestamp.zip"

echo "== 开始备份 SillyTavern 数据 =="
echo "源目录: $src_dir"
echo "备份目标目录: $backup_dir"

# 检查源目录是否存在
if [ ! -d "$src_dir" ]; then
    echo "❌ 错误：源目录 '$src_dir' 不存在！请检查路径。"
    exit 1
fi

# 检查 Termux 存储符号链接是否存在 (基本判断 termux-setup-storage 是否生效)
if [ ! -d "$backup_dir_base" ]; then
    echo "❌ 错误：Termux 存储链接目录 '$backup_dir_base' 不存在。"
    echo "请先执行 'termux-setup-storage' 并授予权限，然后重新启动 Termux。"
    exit 1
fi

# 创建备份目标目录（如果它不存在）
mkdir -p "$backup_dir"
if [ ! -d "$backup_dir" ]; then
    echo "❌ 错误：无法创建备份目标目录 '$backup_dir'！请检查权限或路径。"
    exit 1
fi

# 清理可能存在的旧的临时中转目录
rm -rf "$tmp_dir"
mkdir -p "$tmp_dir" # 确保临时目录存在
if [ ! -d "$tmp_dir" ]; then
    echo "❌ 错误：无法创建临时目录 '$tmp_dir'！"
    exit 1
fi

# 将数据从源目录拷贝到临时中转目录
echo "正在拷贝数据到临时目录..."
cp -r "$src_dir" "$tmp_dir/data_to_backup" || {
  echo "❌ 拷贝失败！请检查源路径 '$src_dir' 是否正确且可访问，以及是否有足够空间。"
  rm -rf "$tmp_dir" # 清理失败的拷贝
  exit 1
}

# 进入临时目录，准备压缩
cd "$tmp_dir" || {
    echo "❌ 无法进入临时目录 '$tmp_dir'！"
    rm -rf "$tmp_dir" # 清理
    exit 1
}

# 将临时目录中的数据压缩到最终的备份目标位置
echo "正在压缩备份文件..."
zip -r "$backup_dir/$backup_name" "data_to_backup"

# 检查压缩是否成功
if [ $? -eq 0 ]; then
    echo "✅ 备份成功完成！备份文件保存至: $backup_dir/$backup_name"
else
    echo "❌ 压缩失败！请检查是否有足够空间或相关权限，以及目标目录 '$backup_dir' 是否可写。"
fi

# 返回之前的目录
cd "$HOME"

# 清理临时中转目录
echo "正在清理临时文件..."
rm -rf "$tmp_dir"
echo "== 备份流程结束 =="
EOF
        chmod +x "$backup_script"
        echo -e "${GREEN}${BOLD}备份脚本初始化完成！${NC}"
    fi
}

# 调用初始化函数
init_backup_script

# 检查并安装必要工具（详细提示）
check_tools() {
    echo -e "${CYAN}${BOLD}==== 检查必要工具 ====${NC}"
    
    local tools_installed=0
    local tools_missing=0
    local install_failed=0

    # 检查 git
    if command -v git &>/dev/null; then
        echo -e "${GREEN}✓ git 已安装${NC}"
        tools_installed=$((tools_installed + 1))
    else
        echo -e "${YELLOW}⚠ git 未安装，准备安装...${NC}"
        tools_missing=$((tools_missing + 1))
        pkg install git -y
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ git 安装成功${NC}"
        else
            echo -e "${RED}✗ git 安装失败${NC}"
            install_failed=1
        fi
    fi

    # 检查 nodejs
    if command -v node &>/dev/null; then
        echo -e "${GREEN}✓ nodejs 已安装${NC}"
        tools_installed=$((tools_installed + 1))
    else
        echo -e "${YELLOW}⚠ nodejs 未安装，准备安装...${NC}"
        tools_missing=$((tools_missing + 1))
        pkg install nodejs-lts -y
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ nodejs 安装成功${NC}"
        else
            echo -e "${RED}✗ nodejs 安装失败${NC}"
            install_failed=1
        fi
    fi

    # 检查 nano
    if command -v nano &>/dev/null; then
        echo -e "${GREEN}✓ nano 已安装${NC}"
        tools_installed=$((tools_installed + 1))
    else
        echo -e "${YELLOW}⚠ nano 未安装，准备安装...${NC}"
        tools_missing=$((tools_missing + 1))
        pkg install nano -y
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ nano 安装成功${NC}"
        else
            echo -e "${RED}✗ nano 安装失败${NC}"
            install_failed=1
        fi
    fi

    # 检查 zip
    if command -v zip &>/dev/null; then
        echo -e "${GREEN}✓ zip 已安装${NC}"
        tools_installed=$((tools_installed + 1))
    else
        echo -e "${YELLOW}⚠ zip 未安装，准备安装...${NC}"
        tools_missing=$((tools_missing + 1))
        pkg install zip -y
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ zip 安装成功${NC}"
        else
            echo -e "${RED}✗ zip 安装失败${NC}"
            install_failed=1
        fi
    fi

    if [ $install_failed -eq 1 ]; then
        echo -e "${RED}${BOLD}工具安装失败！请检查网络连接或存储空间${NC}"
        return 1
    fi

    echo -e "${GREEN}${BOLD}工具检查完成！已安装: $tools_installed 个，新安装: $tools_missing 个${NC}"
    return 0
}

# 部署酒馆
deploy_sillytavern() {
    echo -e "${CYAN}${BOLD}==== 部署酒馆 ====${NC}"
    
    # 强制回到主目录执行
    cd "$HOME"
    
    # 检查是否已存在
    if [ -d "$HOME/SillyTavern" ]; then
        echo -e "${YELLOW}${BOLD}酒馆目录已存在${NC}"
        if confirm_choice "${BLUE}${BOLD}是否重新部署? (y/n): ${NC}"; then
            echo -e "${YELLOW}${BOLD}重新克隆酒馆...${NC}"
            rm -rf "$HOME/SillyTavern"
        else
            echo -e "${YELLOW}${BOLD}取消部署${NC}"
            return 0
        fi
    fi
    
    # 统一检查工具（不管全新部署还是重新部署，都只检查一次）
    check_tools
    if [ $? -ne 0 ]; then
        echo -e "${RED}${BOLD}工具安装失败，部署取消！${NC}"
        return 1
    fi
    
    # 执行克隆，并捕获退出码
    echo -e "${YELLOW}${BOLD}正在克隆酒馆仓库...${NC}"
    echo -e "${CYAN}提示：按 CTRL+C 可中断克隆过程${NC}"
    
    # 设置信号处理，捕获 CTRL+C
    trap 'echo -e "\n${RED}${BOLD}检测到中断信号！${NC}"; exit 130' INT
    
    git clone https://github.com/SillyTavern/SillyTavern -b release "$HOME/SillyTavern"
    local clone_exit_code=$?
    
    # 恢复信号处理
    trap - INT

    if [ $clone_exit_code -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✅ 酒馆部署完成！${NC}"
        return 0
    elif [ $clone_exit_code -eq 130 ]; then
        echo -e "${RED}${BOLD}❌ 克隆过程被用户中断（CTRL+C）！${NC}"
        echo -e "${YELLOW}${BOLD}正在返回主菜单...${NC}"
        # 清理可能存在的部分克隆的目录
        if [ -d "$HOME/SillyTavern" ]; then
            rm -rf "$HOME/SillyTavern"
            echo -e "${YELLOW}已清理部分克隆的目录${NC}"
        fi
        return 1
    else
        echo -e "${RED}${BOLD}❌ 酒馆克隆失败，退出码: $clone_exit_code${NC}"
        echo -e "${YELLOW}请检查网络连接或GitHub访问权限${NC}"
        return 1
    fi
}

# 启动酒馆
start_sillytavern() {
    echo -e "${CYAN}${BOLD}==== 启动酒馆 ====${NC}"

    # 智能检测目录位置
    if [[ "$(basename "$(pwd)")" == "SillyTavern" ]]; then
        echo -e "${GREEN}${BOLD}已在酒馆目录，直接启动${NC}"
    elif [ -d "$HOME/SillyTavern" ]; then
        echo -e "${YELLOW}${BOLD}切换到酒馆目录...${NC}"
        cd "$HOME/SillyTavern"
    else
        echo -e "${RED}${BOLD}酒馆目录不存在，请先部署酒馆！${NC}"
        return 1
    fi

    if [ -f "start.sh" ]; then
        echo -e "${GREEN}${BOLD}执行启动脚本...${NC}"
        bash start.sh
    else
        echo -e "${RED}${BOLD}启动脚本不存在！${NC}"
    fi
}

# 更新酒馆
update_sillytavern() {
    echo -e "${CYAN}${BOLD}==== 更新酒馆 ====${NC}"

    # 智能检测目录位置
    if [[ "$(basename "$(pwd)")" == "SillyTavern" ]]; then
        echo -e "${GREEN}${BOLD}已在酒馆目录，直接更新${NC}"
    elif [ -d "$HOME/SillyTavern" ]; then
        echo -e "${YELLOW}${BOLD}切换到酒馆目录...${NC}"
        cd "$HOME/SillyTavern"
    else
        echo -e "${RED}${BOLD}酒馆目录不存在，请先部署酒馆！${NC}"
        return 1
    fi

    if [ -d ".git" ]; then
        git pull --rebase --autostash
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${BOLD}酒馆更新完成！${NC}"
        else
            echo -e "${RED}${BOLD}酒馆更新失败！${NC}"
        fi
    else
        echo -e "${RED}${BOLD}当前目录不是git仓库！${NC}"
    fi
}

# 删除酒馆
delete_sillytavern() {
    echo -e "${CYAN}${BOLD}==== 删除酒馆 ====${NC}"

    # 强制回到主目录执行
    cd "$HOME"

    # 检查目录是否存在
    if [ ! -d "$HOME/SillyTavern" ]; then
        echo -e "${YELLOW}${BOLD}酒馆目录不存在，无需删除${NC}"
        return 0
    fi

    # 确认删除
    echo -e "${BRIGHT_RED}${BOLD}警告：此操作将永久删除 SillyTavern 目录及其所有内容！${NC}"
    if confirm_choice "${YELLOW}${BOLD}确认删除? (y/N): ${NC}"; then
        # 执行删除
        rm -rf "$HOME/SillyTavern"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}${BOLD}酒馆删除完成！${NC}"
        else
            echo -e "${RED}${BOLD}酒馆删除失败！${NC}"
        fi
    else
        echo -e "${YELLOW}${BOLD}取消删除${NC}"
    fi
}

# 备份酒馆
backup_sillytavern() {
    echo -e "${CYAN}${BOLD}==== 备份酒馆 ====${NC}"
    local backup_script="$HOME/backup_sillytavern.sh"

    if [ -f "$backup_script" ]; then
        bash "$backup_script"
    else
        echo -e "${RED}${BOLD}备份脚本不存在！${NC}"
    fi
}

# 显示菜单
show_menu() {
    clear
    echo -e "${CYAN}${BOLD}==== TERMUX 一键脚本菜单 ====${NC}"
    echo -e "${YELLOW}${BOLD}0. 退出脚本${NC}"
    echo -e "${GREEN}${BOLD}1. 部署酒馆${NC}"
    echo -e "${BLUE}${BOLD}2. 启动酒馆${NC}"
    echo -e "${MAGENTA}${BOLD}3. 更新酒馆${NC}"
    echo -e "${BRIGHT_RED}${BOLD}4. 删除酒馆${NC}"
    echo -e "${BRIGHT_CYAN}${BOLD}5. 备份酒馆${NC}"
    echo -e "${CYAN}${BOLD}================================${NC}"
    echo -ne "${BRIGHT_CYAN}${BOLD}请选择操作 (0-5): ${NC}"
}

# 退出脚本
exit_script() {
    echo -e "${YELLOW}${BOLD}退出脚本，再见！${NC}"
    cd "$HOME"
    clear
    exit 0
}

# 按任意键继续
press_any_key() {
    echo -e "${CYAN}${BOLD}>> 按任意键返回菜单...${NC}"
    read -n1 -s
}

# 主循环
while true; do
    show_menu
    read -r choice
    case $choice in
        0)
            exit_script
            ;;
        1)
            # 先更新系统包列表
            echo -e "${CYAN}${BOLD}==== 更新系统包 ====${NC}"
            echo -e "${YELLOW}正在更新系统包，请稍候...${NC}"
            
            # 设置超时时间（300秒=5分钟）
            timeout 300 pkg update && pkg upgrade -y
            update_status=$?
            
            if [ $update_status -eq 0 ]; then
                echo -e "${GREEN}${BOLD}✅ 系统包更新完成！${NC}"
            elif [ $update_status -eq 124 ]; then
                echo -e "${RED}${BOLD}❌ 系统包更新超时！${NC}"
                if confirm_choice "${YELLOW}${BOLD}是否继续部署? (y/N): ${NC}"; then
                    echo -e "${YELLOW}${BOLD}继续部署...${NC}"
                else
                    echo -e "${YELLOW}${BOLD}取消部署，返回主菜单${NC}"
                    press_any_key
                    continue
                fi
            else
                echo -e "${RED}${BOLD}❌ 系统包更新失败！错误代码: $update_status${NC}"
                if confirm_choice "${YELLOW}${BOLD}是否继续部署? (y/N): ${NC}"; then
                    echo -e "${YELLOW}${BOLD}继续部署...${NC}"
                else
                    echo -e "${YELLOW}${BOLD}取消部署，返回主菜单${NC}"
                    press_any_key
                    continue
                fi
            fi
            
            deploy_sillytavern
            press_any_key
            ;;
        2)
            start_sillytavern
            press_any_key
            ;;
        3)
            update_sillytavern
            press_any_key
            ;;
        4)
            delete_sillytavern
            press_any_key
            ;;
        5)
            backup_sillytavern
            press_any_key
            ;;
        *)
            echo -e "${RED}${BOLD}无效选择，请重新输入！${NC}"
            sleep 1
            ;;
    esac
done
