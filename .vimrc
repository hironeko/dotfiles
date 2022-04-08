set term=xterm-256color

highlight Comment ctermfg=DarkCyan
"変更時に再読み込み
set autoread

"カーソルの位置表示
set ruler

"行番号表示
set number

"現在の行番号
set cursorline

"行の折り返し
set wrap

"syntax hight light
syntax enable
"color scheme
colorscheme koehler

"background color
"set background=dark

"tab=Half-width space true
set expandtab

"space with 4
set tabstop=4
">> or << autoindet
set shiftwidth=4
set paste

"back space true
set backspace=indent,eol,start

"no sowe mode
set noshowmode

"set autoindent
set autoindent

"行頭に移動しない
set nostartofline

" [ って打ったら [] って入力されてしかも括弧の中にいる(以下同様)
imap [ []<left>
imap ( ()<left>
imap { {}<left>


" search
"大文字小文字の区別をしない
set ignorecase
"行末までの検索されたら行頭へ
set wrapscan
"検索結果をhighlight
set hlsearch


