# Rime 输入法

## 安装 squirrel

- 官网下载 [Rime](https://github.com/rime/squirrel). 安装完成后需要到设置->键盘->输入法 中添加鼠须管输入法

- Homebrew安装. 注销用户重新登录才能在系统设置的输入法处看到鼠须管输入法

  ```bash
  brew install --cask squirrel
  ## brew install squirrel-app
  ```

## 安装[雾凇拼音](https://dvel.me/posts/rime-ice/)

- 点击 mac右上角输入法squirrel图标,打开settings目录
- 下载仓库内容,解压后全部复制到 settings目录
- 再次点击squirrel图标,然后点击deploy 部署, 即可开始使用

### 配置雾凇拼音

- 在settings目录下创建`default.custom.yaml`,添加内容

```yaml
 patch:
  schema_list:
   # 可以直接删除或注释不需要的方案，对应的 *.schema.yaml 方案文件也可以直接删除
   # 除了 t9，它依赖于 rime_ice，用九宫格别删 rime_ice.schema.yaml
    - schema: rime_ice               # 雾凇拼音（全拼）
    - schema: double_pinyin          # 自然码双拼
    - schema: double_pinyin_abc      # 智能 ABC 双拼
    - schema: double_pinyin_sogou    # 搜狗双拼
  # 菜单
  menu:
    page_size: 7  # 候选词个数
# 中西文切换
#
# good_old_caps_lock:
# true   切换大写
# false  切换中英
# macOS 偏好设置的优先级更高，如果勾选【使用大写锁定键切换“ABC”输入法】则始终会切换输入法。
# 切换中英：
# 不同的选项表示：打字打到一半时按下了 CapsLock、Shift、Control 后：
# commit_code  上屏原始的编码，然后切换到英文
# commit_text  上屏拼出的词句，然后切换到英文
# clear        清除未上屏内容，然后切换到英文
# inline_ascii 切换到临时英文模式，按回车上屏后回到中文状态
# noop         屏蔽快捷键，不切换中英，但不要屏蔽 CapsLock
########## 关闭  macos 使用大写锁定键切换“ABC”输入法
  ascii_composer:
 good_old_caps_lock: true
 switch_key:
   Caps_Lock: commit_code
   Shift_L: commit_code
   Shift_R: noop
   Control_L: clear
   Control_R: noop
  key_binder:
    bindings:
    - { when: always, accept: Release+Escape, toggle: ascii_mode }
```

- 在settings目录下创建`squirrel.custom.yaml`, 添加内容

```yaml
patch:
  # options: last | default | _custom_
  # last: the last used latin keyboard layout
  # default: US (ABC) keyboard layout
  # _custom_: keyboard layout of your choice, e.g. 'com.apple.keylayout.USExtended' or simply 'USExtended'
  keyboard_layout: default
  # for veteran chord-typist
  chord_duration: 0.1 # seconds
  # options: always | never | appropriate
  show_notifications_when: appropriate

  # 以下软件默认英文模式
  # ascii_mode: false  默认输入法模式: false 中文 true 英文
  # ascii_punct: true  是否设置为英文标点
  # 使用 osascript -e 'id of app "kitty"' 命令获取对应的app 标识
  app_options:
    com.jetbrains.goland:
      ascii_mode: true
      vim_mode: true
      ascii_punct: true
    com.jetbrains.intellij:
      ascii_mode: true
      vim_mode: true
      ascii_punct: true

  # 如果想要修改皮肤，直接更改 color_scheme 的值即可
  style:
    color_scheme: macos_dark
    color_scheme_dark: macos_dark

  preset_color_schemes:
    macos_light:
      font_face: "RecMonoCasual Nerd Font Mono"
      font_point: 16.0
      label_font_face: "RecMonoCasual Nerd Font Mono"
      label_font_point: 16.0
      comment_font_face: "RecMonoCasual Nerd Font Mono"
      comment_font_point: 16.0
      candidate_list_layout: linear
      text_orientation: horizontal
      inline_preedit: true
      translucency: true
      color_space: display_p3
      corner_radius: 10.0
      hilited_corner_radius: 8.0
      border_height: -3.0
      border_width: -3.0
      line_spacing: 8.0
      base_offset: 6.0
      shadow_size: 3.0
      back_color: 0x4CDDDDDD
      candidate_text_color: 0x333333
      comment_text_color: 0x333333
      label_color: 0x5B5B5B
      hilited_candidate_back_color: 0x9A8150
      hilited_candidate_text_color: 0xFFFDFE
      hilited_comment_text_color: 0xFFFDFE
      hilited_candidate_label_color: 0xFFFFFF
      text_color: 0x333333
      hilited_text_color: 0xF7F7F7

    macos_dark:
      font_face: "RecMonoCasual Nerd Font Mono"
      font_point: 16.0
      label_font_face: "RecMonoCasual Nerd Font Mono"
      label_font_point: 16.0
      comment_font_face: "RecMonoCasual Nerd Font Mono"
      comment_font_point: 16.0
      candidate_list_layout: linear
      text_orientation: horizontal
      inline_preedit: true
      translucency: true
      corner_radius: 10.0
      hilited_corner_radius: 8.0
      border_height: -3.0
      border_width: -3.0
      line_spacing: 8.0
      base_offset: 6.0
      shadow_size: 3.0
      back_color: 0x4CDDDDDD
      candidate_text_color: 0x333333
      comment_text_color: 0x333333
      label_color: 0x5B5B5B
      hilited_candidate_back_color: 0x9A8150
      hilited_candidate_text_color: 0xFFFDFE
      hilited_comment_text_color: 0xFFFDFE
      hilited_candidate_label_color: 0xFFFFFF
      text_color: 0x333333
      hilited_text_color: 0xF7F7F7
```

- 配置完成后点击deploy即可使用.
