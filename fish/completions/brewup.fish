# 禁用默认的文件补全，因为我们只希望补全子命令
complete -c brewup -f

function __fish_brewup_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

function __fish_brewup_using_command
    set -l cmd (commandline -opc)
    if test (count $cmd) -gt 1
        if contains -- $cmd[2] $argv
            return 0
        end
    end
    return 1
end

function __fish_brewup_installed_formulae
    brew list --formula 2>/dev/null
end

function __fish_brewup_installed_casks
    brew list --cask 2>/dev/null
end
function __fish_brewup_outdated_casks
    brew outdated --cask 2>/dev/null | awk '{print $1}'
end
function __fish_brewup_outdated_formulae
    brew outdated --formula 2>/dev/null | awk '{print $1}'
end

complete -c brewup -n __fish_brewup_needs_command -a file -d "导出 Brewfile"
complete -c brewup -n __fish_brewup_needs_command -a formula -d "更新 formula"
complete -c brewup -n __fish_brewup_needs_command -a cask -d "更新 cask"
complete -c brewup -n __fish_brewup_needs_command -a deps -d "查看包的依赖关系 "
complete -c brewup -n __fish_brewup_needs_command -a listformula -d "列出已安装的 formula"
complete -c brewup -n __fish_brewup_needs_command -a listcask -d "列出已安装的 cask"
complete -c brewup -n __fish_brewup_needs_command -a listall -d "列出所有已安装的包 "
complete -c brewup -n __fish_brewup_needs_command -a check -d "检查可用更新 "
complete -c brewup -n __fish_brewup_needs_command -a cleandeps -d "清理独立依赖 "
complete -c brewup -n __fish_brewup_needs_command -a cleantaps -d "清理冗余 Taps"
complete -c brewup -s h -l help -d "显示帮助信息 "

complete -c brewup -n "__fish_brewup_using_command formula" -a "(__fish_brewup_outdated_formulae)" -d "可更新的 formula"
complete -c brewup -n "__fish_brewup_using_command formula" -a "(__fish_brewup_installed_formulae)" -d "已安装的 formula"
complete -c brewup -n "__fish_brewup_using_command cask" -a "(__fish_brewup_outdated_casks)" -d "可更新的 cask"
complete -c brewup -n "__fish_brewup_using_command cask" -a "(__fish_brewup_installed_casks)" -d "已安装的 cask"
complete -c brewup -n "__fish_brewup_using_command deps" -a "(__fish_brewup_installed_formulae)" -d "已安装的 formula"
complete -c brewup -n "__fish_brewup_using_command deps" -l tree -d "显示完整依赖树 "
