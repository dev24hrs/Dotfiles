# Llama.cpp 统一命令函数
# 使用方式:
#   llama cli <model_name> [额外参数...]
#   llama server <model_name> [额外参数...]
#   llama bench <model_name> [额外参数...]

function llama --description "Llama.cpp 统一命令入口"
    # 配置部分
    set -l MODELS_DIR ~/.llama

    # 预设性能参数
    set -l DEFAULT_NGL 30 # GPU 层数 (根据你的 GPU 调整)
    set -l DEFAULT_CTX 4096 # 上下文大小
    set -l DEFAULT_THREADS 8 # CPU 线程数
    set -l DEFAULT_SERVER_PORT 8080 # 服务器端口

    # 检查子命令
    if test (count $argv) -lt 2
        echo "用法: llama <子命令> <模型名称> [额外参数...]"
        echo ""
        echo "子命令:"
        echo "  cli      - 运行命令行交互模式"
        echo "  server   - 启动 API 服务器"
        echo "  bench    - 运行性能基准测试"
        echo ""
        echo "示例:"
        echo "  llama cli qwen2.5-7b-instruct"
        echo "  llama server llama-3.1-8b -c 8192"
        echo "  llama bench mistral-7b --help"
        echo ""
        echo "可用模型 (在 $MODELS_DIR):"
        if test -d $MODELS_DIR
            for model in $MODELS_DIR/*.gguf
                echo "  - "(basename $model .gguf)
            end
        else
            echo "  模型目录不存在: $MODELS_DIR"
        end
        return 1
    end

    set -l subcommand $argv[1]
    set -l model_name $argv[2]
    set -l extra_args $argv[3..-1]

    # 构建模型文件路径
    set -l model_path "$MODELS_DIR/$model_name"

    # 如果没有 .gguf 后缀,自动添加
    if not string match -q "*.gguf" $model_path
        set model_path "$model_path.gguf"
    end

    # 检查模型文件是否存在
    if not test -f $model_path
        echo "错误: 模型文件不存在: $model_path"
        echo ""
        echo "可用模型:"
        for model in $MODELS_DIR/*.gguf
            echo "  - "(basename $model .gguf)
        end
        return 1
    end

    # 根据子命令执行相应操作
    switch $subcommand
        case cli
            echo "启动 llama-cli 与模型: $model_name"
            echo "模型路径: $model_path"
            echo ""

            llama-cli \
                -m $model_path \
                -ngl $DEFAULT_NGL \
                -c $DEFAULT_CTX \
                -t $DEFAULT_THREADS \
                -n -1 \
                $extra_args

        case server
            echo "启动 llama-server 与模型: $model_name"
            echo "模型路径: $model_path"
            echo "端口: $DEFAULT_SERVER_PORT"
            echo ""

            llama-server \
                -m $model_path \
                -ngl $DEFAULT_NGL \
                -c $DEFAULT_CTX \
                -t $DEFAULT_THREADS \
                --port $DEFAULT_SERVER_PORT \
                --host 0.0.0.0 \
                -np 4 \
                -cb \
                $extra_args

        case bench
            echo "运行 llama-bench 与模型: $model_name"
            echo "模型路径: $model_path"
            echo ""

            llama-bench \
                -m $model_path \
                -ngl $DEFAULT_NGL \
                -t $DEFAULT_THREADS \
                -p 128,512,1024 \
                -n 128,512 \
                -r 3 \
                $extra_args

        case '*'
            echo "错误: 未知的子命令 '$subcommand'"
            echo "支持的子命令: cli, server, bench"
            return 1
    end
end
