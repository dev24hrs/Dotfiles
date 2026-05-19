set -gx XDG_CONFIG_HOME "$HOME/.config"

set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"

# 2. 导出开发环境变量 (使用 set -gx)
set -gx GOPATH $HOME/Documents/Tools/GoPath
set -gx JAVA_HOME /Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
set -gx MAVEN_HOME $HOME/Documents/Tools/maven/maven-3.9.9
set -gx GRADLE_HOME $HOME/Documents/Tools/gradle/gradle-8.12
set -gx GRADLE_USER_HOME $HOME/Documents/Tools/gradle/gradle-repository

set -gx PATH /opt/homebrew/bin $PATH

source "$HOME/.cargo/env.fish"

# 3. 路径管理
# $GOPATH/bin: go install xxx 的存放路径
# /opt/homebrew/opt/go: 是 Homebrew 指向当前 Go 版本的软链
# 可用于多个 Go 版本时指定某一个版本

fish_add_path $GOPATH/bin
fish_add_path $JAVA_HOME/bin
fish_add_path $MAVEN_HOME/bin
fish_add_path $GRADLE_HOME/bin

fish_add_path /opt/homebrew/opt/imagemagick-full/bin
fish_add_path /opt/homebrew/opt/ffmpeg-full/bin
