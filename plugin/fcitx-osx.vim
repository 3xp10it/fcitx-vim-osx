" fcitx.vim  记住插入/命令行模式下 macOS 输入法的状态（中文 <-> 英文）
"
" 上游:      lilydjwg/fcitx.vim (Linux fcitx)
" macOS 适配: codefalling / xcodebuild/fcitx-remote-for-osx
" 本 fork:   https://github.com/3xp10it/fcitx-vim-osx
"
" 本 fork 主要改动 (2026-11-24):
"   1. 切输入法从 fcitx-remote -c/-o (toggle, 不可靠) 改为 -s <source-id> 幂等指定。
"   2. 新增 CmdlineLeave 自动切回英文 (FcitxCmdline2en)，且不碰 b:inputtoggle。
"
" 重要: 依赖 fcitx-remote-for-osx 的 SPECIFIC 版 (build.py build macos-wubi us)。
"       GENERAL 版的 -s 仍是 Ctrl+Shift+Z toggle, 本插件将不可靠。详见 README.md。
" ---------------------------------------------------------------------
" Load Once:
if exists('g:fcitx_remote')
  finish
endif

set ttimeoutlen=50

if (has("win32") || has("win95") || has("win64") || has("win16"))
  " Windows 下不要载入
  finish
endif
if exists('$SSH_TTY')
  finish
endif
if !executable("/usr/local/bin/fcitx-remote")
  finish
endif
let s:keepcpo = &cpo
let g:loaded_fcitx = 1
set cpo&vim
" ---------------------------------------------------------------------
" Functions:
" 【改动 2026-11-24】改用 -s 按 ID 幂等指定输入源，替代原 -c/-o：
" 原 -c/-o 在 macOS 版都是发 Ctrl+Shift+Z「切到上一个输入源」(toggle)，
" 轮转历史一变就切错；-s 走 TIS API 按 ID 直接选中，实测连续调用结果不变。
function Fcitx2en()
  let inputstatus = system("/usr/local/bin/fcitx-remote")
  if inputstatus == 2
    let b:inputtoggle = 1
  endif
  let t = system("/usr/local/bin/fcitx-remote -s com.apple.keylayout.US")
endfunction
function Fcitx2zh()
  try
    if b:inputtoggle == 1
      let t = system("/usr/local/bin/fcitx-remote -s com.apple.inputmethod.SCIM.WBX")
      let b:inputtoggle = 0
    endif
  catch /inputtoggle/
    let b:inputtoggle = 0
  endtry
endfunction
" ---------------------------------------------------------------------
" Autocmds:
function Fcitx2zhOnce()
  call Fcitx2zh()
  call UnBindAu()
endfunction

function BindAu2zhOnce()
  augroup Fcitx
   au InsertEnter * call Fcitx2zhOnce()
  augroup END
endfunction

function BindAu()
  augroup Fcitx
   au InsertLeave * call Fcitx2en()
   au InsertEnter * call Fcitx2zh()
   au VimEnter * call Fcitx2en()
  augroup END
endfunction

function UnBindAu()
  au! Fcitx InsertLeave *
  au! Fcitx InsertEnter *
endfunction

call BindAu()

" ============================================================
" 【改动 2026-11-24】CmdlineLeave：命令行/搜索退出后自动切回英文。
" 注意：本段位于文件开头的 $SSH_TTY / executable 检查之后，SSH 环境或
" fcitx-remote 缺失时整份插件（含本段）都不加载。
" 用独立的 augroup FcitxCmdline，不会被上面 UnBindAu()（只清 Fcitx 组的
" InsertLeave/InsertEnter）影响。
function! FcitxCmdline2en()
  " 设计要点：本函数只切输入源，绝不读写 b:inputtoggle。
  " b:inputtoggle 由 Fcitx2en/Fcitx2zh 维护，记录「上次离开插入模式时是否为中文」。
  " 若这里碰了它，cmdline 搜索就会污染插入模式的输入法记忆：
  " 下次按 i 时应按进入 cmdline 之前的 b:inputtoggle 决定恢复哪种输入法。
  " 以下 CmdlineLeave 不是「用户确认搜索/命令」，跳过，避免误切输入法：
  "   '='   : auto-pairs 的 <BS> 映射 <C-R>=AutoPairsDelete()<CR> 表达式求值
  "   '/' '?' : incsearch 增量搜索每输入一个字符都会 feedkeys('/xxx<CR>') 产生假 leave；
  "             若在此切英文，中文选字（如五笔按空格选字）会被误切。
  " 用户真正按回车确认搜索后，incsearch 走 ':' 类型收尾(let &hlsearch)，仍会执行下方切换，
  " 保留「/ 搜索后回车自动切英文」的行为。
  if getcmdtype() ==# '=' || getcmdtype() ==# '/' || getcmdtype() ==# '?'
    return
  endif
  " 回车确认搜索/命令后强制回英文。用 -s 按 ID 幂等指定 US（底层 TIS API）。
  " 不用 -c：它发 Ctrl+Shift+Z 是「切到上一个输入源」toggle，轮转历史一变就切错。
  call system('/usr/local/bin/fcitx-remote -s com.apple.keylayout.US')
endfunction
augroup FcitxCmdline
  autocmd!
  autocmd CmdlineLeave * call FcitxCmdline2en()
augroup END
" ============================================================

"Called once right before you start selecting multiple cursors
function! Multiple_cursors_before()
  call UnBindAu()
  call BindAu2zhOnce()
endfunction

function! Multiple_cursors_after()
  call Fcitx2en()
  call BindAu()
endfunction

" ---------------------------------------------------------------------
"  Restoration And Modelines:
let &cpo=s:keepcpo
unlet s:keepcpo
"vim:fdm=expr:fde=getline(v\:lnum-1)=~'\\v"\\s*-{20,}'?'>1'\:1

let g:fcitx_remote = 1
