"カーソルの位置表示
set ruler

"行番号表示
set number

"現在の行番号
set cursorline

"行の折り返し
set wrap

"syntax hight light
syntax on

"background color
"set background=dark

"tab=Half-width space true
set expandtab

"space with 4space
set tabstop=4
">> or << autoindet
set shiftwidth=4

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
