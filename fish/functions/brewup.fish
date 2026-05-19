function brewup --description "Homebrew 管理工具 - 支持子命令"

    # 显示帮助信息
    function _brewup_help
        echo "用法: brewup [子命令]"
        echo ""
        echo "子命令:"
        echo "  formula   仅更新 formula"
        echo "  cask      仅更新 cask"
        echo "  deps      分析依赖关系"
        echo "  listformula      列出已安装的 formula"
        echo "  listcask  列出已安装的 cask"
        echo "  listall   列出所有已安装的 formula 和 cask"
        echo "  check     检查可用更新"
        echo "  cleandeps 清理独立依赖"
        echo "  cleantaps 清理冗余 Taps"
        echo "  help      显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  brewup           # 更新所有内容"
        echo "  brewup formula   # 仅更新 formula"
        echo "  brewup cask      # 仅更新 cask"
        echo "  brewup listformula      # 列出已安装的 formula"
        echo "  file             # 重新导出 Brewfile 到 Dotfiles"
    end

    # 获取子命令
    set -l subcommand $argv[1]
    set -e argv[1]

    switch "$subcommand"
        case formula
            if test (count $argv) -eq 0
                echo "更新所有 Homebrew formula..."
                brew update && brew upgrade && brew cleanup --prune=all
                echo "Formula 更新完成！"
            else
                echo "更新指定的 formula: "(set_color cyan)(string join ", " $argv)(set_color normal)
                brew update
                for pkg in $argv
                    echo ""
                    echo (set_color --bold)"升级 $pkg..."(set_color normal)
                    if brew upgrade $pkg
                        echo (set_color green)"✓ $pkg 升级成功"(set_color normal)
                    else
                        echo (set_color red)"✗ $pkg 升级失败或已是最新版本"(set_color normal)
                    end
                end
                brew cleanup --prune=all
                echo ""
                echo (set_color green)"指定 formula 更新完成！"(set_color normal)
            end
        case cask
            if test (count $argv) -eq 0
                echo "更新所有 Homebrew cask..."
                brew update && brew upgrade --cask --greedy && brew cleanup --prune=all
                echo "Cask 更新完成！"
            else
                echo "更新指定的 cask: "(set_color cyan)(string join ", " $argv)(set_color normal)
                brew update
                for pkg in $argv
                    echo ""
                    echo (set_color --bold)"升级 $pkg..."(set_color normal)
                    if brew upgrade --cask $pkg
                        echo (set_color green)"✓ $pkg 升级成功"(set_color normal)
                    else
                        echo (set_color red)"✗ $pkg 升级失败或已是最新版本"(set_color normal)
                    end
                end
                brew cleanup --prune=all
                echo ""
                echo (set_color green)"指定 cask 更新完成！"(set_color normal)
            end

        case deps
            if test (count $argv) -eq 0
                echo (set_color red)"错误: deps 命令需要指定包名"(set_color normal)
                echo "用法: brewup deps <包名> [--tree]"
                echo "示例: brewup deps python"
                echo "      brewup deps python --tree  # 显示依赖树"
                return 1
            end
            # 检查是否有 --tree 参数
            set -l show_tree false
            if contains -- --tree $argv
                set show_tree true
                # 移除 --tree 参数
                set -e argv[(contains -i -- --tree $argv)]
            end
            _brewup_deps $argv[1] $show_tree

        case listformula
            echo "已安装的 Formula:"
            brew list --formula
            echo ""
            set count (brew list --formula | wc -l | string trim)
            echo "总计: $count 个 formula"
        case listcask
            echo "已安装的 Cask:"
            brew list --cask
            echo ""
            set count (brew list --cask | wc -l | string trim)
            echo "总计: $count 个 cask"
        case listall
            echo "已安装的 Formula:"
            brew list --formula
            set formula_count (brew list --formula | wc -l | string trim)
            echo ""
            echo "已安装的 Cask:"
            brew list --cask
            set cask_count (brew list --cask | wc -l | string trim)
            echo ""
            echo "总计: $formula_count 个 formula, $cask_count 个 cask"
        case check
            echo "检查可用更新..."
            echo ""
            echo "Formula 可更新:"
            set outdated_formula (brew outdated --formula)
            if test -n "$outdated_formula"
                echo $outdated_formula
            else
                echo "所有 formula 都是最新的"
            end
            echo ""
            echo "Cask 可更新:"
            set outdated_cask (brew outdated --cask --greedy)
            if test -n "$outdated_cask"
                echo $outdated_cask
            else
                echo "所有 cask 都是最新的"
            end
        case file
            set brewfile "$HOME/Documents/Dotfiles/Brewfile"
            echo "→ Dumping Brewfile to $brewfile ..."
            brew bundle dump --file=$brewfile --force --no-vscode
            or begin
                echo "✗ Failed to dump Brewfile"
                return 1
            end
            and echo "✓ Done: $brewfile"
        case cleandeps
            _brewup_cleandeps $argv
        case cleantaps
            _brewup_cleantaps $argv
        case help -h --help ""
            _brewup_help
        case "*"
            echo (set_color red)"未知子命令: $subcommand"(set_color normal)
            _brewup_help
            return 1
    end

end

# --- 内部私有函数：查看依赖关系 ---
function _brewup_deps
    set -l pkg $argv[1]
    set -l show_tree $argv[2]

    echo ""

    # 检查包是否已安装
    if not brew list --formula | grep -q "^$pkg\$"
        echo (set_color red)"错误: $pkg 未安装"(set_color normal)
        echo ""
        echo "建议: 先安装该包或检查包名是否正确"
        echo "可用命令: brewup listformula"
        echo (set_color --bold cyan)"==========================================="(set_color normal)
        return 1
    end

    # 1. 显示该包依赖哪些包
    echo ""
    echo (set_color --bold yellow)"$pkg 依赖的包 (Dependencies):"(set_color normal)
    echo -------------------------------------------

    # 如果要显示树形结构
    if test "$show_tree" = true
        echo (set_color green)"依赖树:"(set_color normal)
        echo ""
        brew deps --tree $pkg 2>/dev/null
        echo ""
    else
        # 获取所有依赖（包括间接依赖）
        set -l all_dependencies (brew deps --installed $pkg 2>/dev/null)
        # 获取直接依赖（使用 --tree 解析第一层）
        set -l direct_dependencies (brew deps --tree $pkg 2>/dev/null | grep -E "^├──|^└──" | sed 's/^[├└]── //')

        if test -n "$all_dependencies"
            set -l dep_count (count $all_dependencies)
            echo (set_color green)"找到 $dep_count 个依赖："(set_color normal)

            # 先显示直接依赖
            if test -n "$direct_dependencies"
                echo (set_color --bold)"  直接依赖:"(set_color normal)
                for dep in $direct_dependencies
                    # 获取依赖的简短描述
                    set -l desc (brew info --json=v1 $dep 2>/dev/null | jq -r '.[0].desc' 2>/dev/null)
                    if test -n "$desc" -a "$desc" != null
                        echo "   • "(set_color --bold cyan)$dep(set_color normal)
                        echo "     └─ "(set_color cyan)$desc(set_color normal)
                    else
                        echo "   • "(set_color --bold cyan)$dep(set_color normal)
                    end
                end
            end

            # 找出间接依赖（在所有依赖中但不在直接依赖中）
            set -l indirect_dependencies
            for dep in $all_dependencies
                if not contains $dep $direct_dependencies
                    set -a indirect_dependencies $dep
                end
            end

            # 显示间接依赖
            if test -n "$indirect_dependencies"
                echo ""
                echo (set_color --bold)"  间接依赖 (通过其他依赖引入):"(set_color normal)
                for dep in $indirect_dependencies
                    echo "   • "(set_color cyan)$dep(set_color normal)
                end
            end
        else
            echo (set_color cyan)"该包没有依赖项"(set_color normal)
        end
    end

    # 2. 显示哪些包依赖该包
    echo ""
    echo (set_color --bold yellow)"依赖 $pkg 的包 (Dependents):"(set_color normal)
    echo -------------------------------------------

    set -l dependents (brew uses --installed $pkg 2>/dev/null)
    if test -n "$dependents"
        set -l dependent_count (count $dependents)
        echo (set_color green)"找到 $dependent_count 个包依赖 $pkg："(set_color normal)
        for dependent in $dependents
            # 获取包的简短描述
            set -l desc (brew info --json=v1 $dependent 2>/dev/null | jq -r '.[0].desc' 2>/dev/null)
            if test -n "$desc"
                echo " • "(set_color --bold magenta)$dependent(set_color normal)
                echo "   └─ "(set_color cyan)$desc(set_color normal)
            else
                echo " • "(set_color --bold magenta)$dependent(set_color normal)
            end
        end
    else
        echo (set_color cyan)"没有其他包依赖 $pkg"(set_color normal)
        echo (set_color yellow)"提示: 这个包可能是顶级包或孤立依赖"(set_color normal)
    end

    # 3. 显示额外信息
    echo ""
    echo (set_color --bold yellow)"附加信息:"(set_color normal)
    echo -------------------------------------------

    # 检查是否是手动安装
    set -l installed_on_request (brew info --json=v1 $pkg 2>/dev/null | jq -r '.[0].installed[0].installed_on_request' 2>/dev/null)
    if test "$installed_on_request" = true
        echo " • 安装方式: "(set_color blue)"手动安装"(set_color normal)
    else
        echo " • 安装方式: "(set_color magenta)"作为依赖自动安装"(set_color normal)
    end

    # 显示安装大小
    set -l size (du -sh (brew --prefix)/Cellar/$pkg 2>/dev/null | cut -f1)
    if test -n "$size"
        echo " • 占用空间: $size"
    end

    echo -------------------------------------------
    echo ""
end

# --- 内部私有函数：清理依赖 ---
function _brewup_cleandeps

    # set -l orphans (brew leaves)
    set -l orphans (brew leaves --installed-as-dependency)

    echo
    echo "  Homebrew Deps 清理"
    echo -------------------------------------------

    if test -z "$orphans"
        echo (set_color green)"󰄬  系统非常干净，没有发现冗余依赖。"(set_color normal)
        # 顺便建议清理缓存
        read -l -P "󰃥  是否顺便清理旧版本缓存 (brew cleanup)? [y/N] " clean_cache
        if contains (string lower $clean_cache) y yes
            brew cleanup --prune=all
        end
        return
    end

    # 2. 展示这些包及其用途
    echo (set_color yellow)"󱇝  发现以下 $(count $orphans) 个独立依赖（没有其它包依赖它们）："(set_color normal)
    echo -------------------------------------------
    for pkg in $orphans
        set -l info_json (brew info --json=v1 $pkg)
        set -l desc (echo $info_json | jq -r '.[0].desc' 2>/dev/null)
        # 获取安装原因 (on request 还是 dependency)
        set -l reason (brew info --json=v1 $pkg | jq -r '.[0].installed[0].installed_on_request' 2>/dev/null)

        if test "$reason" = true
            set reason_str (set_color blue)"[手动安装]"(set_color normal)
        else
            set reason_str (set_color magenta)"[自动随依赖安装]"(set_color normal)
        end

        echo " • "(set_color --bold)$pkg(set_color normal) " $reason_str"
        echo "   └─ $desc"
    end
    echo -------------------------------------------

    # 3. 交互式操作
    echo (set_color --bold cyan)"󰃥 请选择操作："(set_color normal)
    echo " [y] 批量卸载以上所有包"
    echo " [s] 逐个选择要卸载的包 (Selectively)"
    echo " [q] 退出"

    read -l -P "请输入指令: " action

    switch (string lower $action)
        case y yes
            echo (set_color red)"正在批量卸载..."(set_color normal)
            brew uninstall $orphans
            echo (set_color green)"  批量卸载完成！"(set_color normal)

        case s select
            for pkg in $orphans
                read -l -P "是否卸载 $pkg ? [y/N] " confirm
                if contains (string lower $confirm) y yes
                    brew uninstall $pkg
                end
            end
            echo (set_color green)"  选择性清理完成！"(set_color normal)

        case '*'
            echo (set_color white)"󰜺  操作已取消。"(set_color normal)
    end

    echo -------------------------------------------
end

# --- 内部私有函数：清理 Taps ---
function _brewup_cleantaps
    echo
    echo "  Homebrew Taps 清理"
    echo -------------------------------------------

    echo (set_color --bold yellow)"󰍉 正在扫描冗余的 Taps..."(set_color normal)
    set -l unused_taps

    # 获取所有已添加的 tap
    for tap in (brew tap)
        # 使用 Fish 原生的 string match 替代 grep，效率更高
        set -l pkgs (brew list --full-name | string match -r "^$tap/")
        set -l pkg_count (count $pkgs)

        if test $pkg_count -eq 0
            echo (set_color yellow)"󱇝 发现无用 Tap: 󰊤 $tap"(set_color normal)
            set -a unused_taps $tap
        end
    end

    # 检查收集到的无用 tap 数量
    set -l unused_count (count $unused_taps)

    if test $unused_count -eq 0
        echo (set_color green)"󰄬 恭喜！没有发现冗余 Tap. 无需清理"(set_color normal)
        echo
        echo -------------------------------------------
        return 0
    end

    echo -----------------------------------
    read -l -P "󰃥 是否现在移除这 $unused_count 个无用 Tap? [y/N] " confirm
    # 匹配多种确认输入格式 (y, Y, yes 等)
    if contains -- $confirm y Y yes YES
        for t in $unused_taps
            echo (set_color red)" 正在移除 $t..."(set_color normal)
            brew untap $t
        end
        echo (set_color green)" 清理完成！建议执行 `brew cleanup --prune=all` 释放磁盘空间"(set_color normal)
    else
        echo (set_color white)"󰜺 已取消操作"(set_color normal)
    end
    echo -------------------------------------------
end
