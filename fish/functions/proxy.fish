function proxy --description 'proxy [on|off]'
    switch "$argv[1]"
        case on
            set -gx HTTP_PROXY http://127.0.0.1:7897
            set -gx HTTPS_PROXY http://127.0.0.1:7897
            set -gx ALL_PROXY socks5://127.0.0.1:7897
            echo (set_color green)"proxy on → 127.0.0.1:7897"(set_color normal)

        case off
            set -e HTTP_PROXY
            set -e HTTPS_PROXY
            set -e ALL_PROXY
            echo (set_color red)"proxy off"(set_color normal)
        case '*'
            echo "Usage: proxy [on|off]"
    end
end
