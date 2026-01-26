-- Keymaps for VSCode-like experience

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Set leader key to space (like VSCode)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General keymaps
keymap("i", "jk", "<ESC>", opts) -- Exit insert mode with jk
keymap("n", "<leader>w", ":w<CR>", opts) -- Save file
keymap("n", "<C-s>", ":w<CR>", opts) -- Save file (VSCode-like)
keymap("i", "<C-s>", "<Esc>:w<CR>a", opts) -- Save in insert mode
keymap("n", "<leader>q", ":q<CR>", opts) -- Quit
keymap("n", "<leader>Q", ":qa!<CR>", opts) -- Quit all without saving
keymap("n", "<C-q>", ":bdelete<CR>", opts) -- Close buffer (alternative to Ctrl+W)

-- Window navigation (VSCode-like Ctrl+W alternatives)
keymap("n", "<C-h>", "<C-w>h", opts) -- Left window
keymap("n", "<C-l>", "<C-w>l", opts) -- Right window
keymap("n", "<C-j>", "<C-w>j", opts) -- Down window
keymap("n", "<C-k>", "<C-w>k", opts) -- Up window

-- Window splitting
keymap("n", "<leader>sv", ":vsplit<CR>", opts) -- Split vertically
keymap("n", "<leader>sh", ":split<CR>", opts) -- Split horizontally
keymap("n", "<leader>sx", ":close<CR>", opts) -- Close split
keymap("n", "<leader>se", "<C-w>=", opts) -- Make splits equal size

-- Window resizing
keymap("n", "<C-Up>", ":resize +2<CR>", opts) -- Increase height
keymap("n", "<C-Down>", ":resize -2<CR>", opts) -- Decrease height
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts) -- Decrease width
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts) -- Increase width

-- Tab management
keymap("n", "<leader>to", ":tabnew<CR>", opts) -- New tab
keymap("n", "<leader>tx", ":tabclose<CR>", opts) -- Close tab
keymap("n", "<leader>tn", ":tabnext<CR>", opts) -- Next tab
keymap("n", "<leader>tp", ":tabprev<CR>", opts) -- Previous tab

-- Buffer navigation
keymap("n", "<S-l>", ":bnext<CR>", opts) -- Next buffer
keymap("n", "<S-h>", ":bprevious<CR>", opts) -- Previous buffer
keymap("n", "<leader>bd", ":bdelete<CR>", opts) -- Delete buffer
keymap("n", "<leader>x", ":bdelete<CR>", opts) -- Close current buffer (shorter)
keymap("n", "<leader>bx", ":bdelete!<CR>", opts) -- Force close buffer

-- Better indenting
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)

-- Clear search highlighting
keymap("n", "<leader>nh", ":nohl<CR>", opts)

-- Plugin-specific keymaps will be defined in their respective plugin files
-- nvim-tree: <leader>e
-- telescope: <leader>ff, <leader>fg, <leader>fb, etc.
-- LSP: gd, gD, gr, K, etc.
