function proxy --description 'proxy [on|off|show]'
    switch "$argv[1]"
        case on
            git config --global http.proxy 127.0.0.1:7897
            git config --global https.proxy 127.0.0.1:7897
            # set -gx http_proxy http://127.0.0.1:7890
            # set -gx https_proxy http://127.0.0.1:7890
            echo (set_color green)"󰄬 代理已开启 (Git & Session)"(set_color normal)

        case off
            git config --global --unset http.proxy
            git config --global --unset https.proxy
            echo (set_color red)"󰜺 代理已关闭"(set_color normal)

        case show
            echo (set_color blue)"--- Git Proxy ---"(set_color normal)
            git config --global --get http.proxy
            git config --global --get https.proxy

        case '*'
            echo "Usage: proxy [on|off|show]"
    end
end
