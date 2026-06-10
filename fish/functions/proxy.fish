function proxy --description 'proxy [on|off]'
    switch "$argv[1]"
        case on
            set -x http_proxy http://127.0.0.1:7897
            set -x https_proxy http://127.0.0.1:7897
            set -x all_proxy socks5://127.0.0.1:7897
            echo (set_color green)"proxy on → 127.0.0.1:7897"(set_color normal)

        case off
            set -e http_proxy
            set -e https_proxy
            set -e all_proxy
            echo (set_color red)"proxy off"(set_color normal)
        case '*'
            echo "Usage: proxy [on|off]"
    end
end
