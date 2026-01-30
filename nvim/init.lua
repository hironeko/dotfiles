-- Neovim Configuration
-- This config aims to provide a VSCode-like experience

-- Set leader keys before loading plugins
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load basic options
require("config.options")

-- Load lazy.nvim plugin manager
require("config.lazy")

-- Load keymaps
require("config.keymaps")
