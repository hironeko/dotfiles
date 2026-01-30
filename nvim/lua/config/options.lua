-- Basic Options for VSCode-like experience

local opt = vim.opt

-- Ensure Homebrew binaries are available even when Neovim is launched from GUI apps.
local function _prepend_path(dir)
  if vim.fn.isdirectory(dir) == 1 and not vim.env.PATH:find(dir, 1, true) then
    vim.env.PATH = dir .. ":" .. vim.env.PATH
  end
end
_prepend_path("/opt/homebrew/bin")
_prepend_path("/usr/local/bin")

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false

-- Split windows
opt.splitbelow = true
opt.splitright = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Backspace behavior
opt.backspace = "indent,eol,start"

-- File encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- Filetype detection
vim.filetype.add({
  pattern = {
    [".*%.blade%.php"] = "blade",
  },
})

-- Undo and backup
opt.undofile = true
opt.backup = false
opt.swapfile = false

-- Mouse support
opt.mouse = "a"

-- Command line
opt.cmdheight = 1
opt.showmode = false

-- Update time for better experience
opt.updatetime = 300
opt.timeoutlen = 1000 -- Increased for better keymap experience

-- Scroll offset
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Folding
opt.foldmethod = "indent"
opt.foldlevel = 99
