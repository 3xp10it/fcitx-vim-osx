# fcitx-vim-osx (fork)

在 macOS 的 Vim/Neovim 中自动记住并切换中英文输入法：离开插入模式切英文、回到插入模式恢复之前的输入法，命令行/搜索结束也切回英文。

基于 [xcodebuild/fcitx-vim-osx](https://github.com/xcodebuild/fcitx-vim-osx)（其上游为 lilydjwg 的 fcitx.vim）修改。

## 与上游的区别

| 行为 | 上游 | 本 fork |
| --- | --- | --- |
| 切英文 | `fcitx-remote -c` | `fcitx-remote -s com.apple.keylayout.US` |
| 切中文 | `fcitx-remote -o` | `fcitx-remote -s com.apple.inputmethod.SCIM.WBX` |
| 命令行退出后切英文 | 无 | 有（`CmdlineLeave`，跳过 incsearch 假 leave） |

上游的 `-c` / `-o` 依赖 Ctrl+Shift+Z 热键（"切到上一个输入源"），轮转历史一乱就会切错。本 fork 改用 `-s` 按输入源 ID 幂等指定，不依赖热键历史。

## 依赖

需要 `fcitx-remote-for-osx` 的 **SPECIFIC** 版本（不是 GENERAL 版）。

**GENERAL 版**的 `-c` / `-o` / `-s` 全部走 Ctrl+Shift+Z 热键；只有 **SPECIFIC 版**的 `-s` 才走 TIS API 按 ID 精确选中，插件才可靠。

编译 SPECIFIC 版（以 macOS 自带五笔 + 美式键盘为例）：

```bash
git clone https://github.com/xcodebuild/fcitx-remote-for-osx.git
cd fcitx-remote-for-osx
python3 build.py build macos-wubi us
cp ./fcitx-remote-macos-wubi /usr/local/bin/fcitx-remote
```

校验你装的是不是 SPECIFIC 版：

```bash
fcitx-remote -s com.fake.nonexistent.zzz
fcitx-remote -n
```

输入源**不变** = SPECIFIC 版（正确）；输入源来回切 = GENERAL 版（不对，需重编译）。

## 安装

用 Vundle：

```vim
Plugin '3xp10it/fcitx-vim-osx'
```

其他插件管理器按各自语法添加即可。

## 自定义输入法 ID

插件里写死了两个 ID（在 `plugin/fcitx-osx.vim` 顶部附近）：

```vim
com.apple.keylayout.US              " 英文（美式键盘）
com.apple.inputmethod.SCIM.WBX      " 中文（macOS 自带五笔）
```

换成你自己的输入法时，用 `fcitx-remote -n` 读出当前输入源 ID，然后替换这两处。常见 ID：

- macOS 拼音：`com.apple.inputmethod.SCIM.ITABC`
- macOS 双拼：`com.apple.inputmethod.SCIM.Shuangpin`
- 搜狗拼音：`com.sogou.inputmethod.sogou.pinyin`

也可以直接用 `build.py` 里对应的 `macos-pinyin` / `macos-shuangpin` / `sogou-pinyin` 重新编译 `fcitx-remote`，ID 与上面一致。

## 注意

- SSH 远程会话中插件不加载（`exists('$SSH_TTY')` 时直接 finish），避免误改远程输入法。
- 装了 `incsearch` + `easymotion` 的用户：本插件的 `CmdlineLeave` 会跳过 `/` 和 `?` 类型（因为 incsearch 增量刷新会产生假 leave，此时切英文会打断中文选字）。搜索确认后自动切英文需在别处处理，例如在 vimrc 里包装 easymotion module。
- Windows 下不加载。

## License

GPLv3（沿用上游许可证）。
