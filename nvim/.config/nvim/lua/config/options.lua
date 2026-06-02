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

-- Host paste support (SSH/remote sessions)
-- Enable system clipboard provider detection
if vim.fn.exists("$SSH_TTY") == 1 then
  -- SSH session: use OSC 52 for clipboard
  vim.g.clipboard = {
    name = "osc52",
    copy = { "+", "y" },
    paste = { "+", "p" },
  }
end

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

-- PHP/Blade indentation (PSR-style)
local php_indent_group = vim.api.nvim_create_augroup("PhpIndent", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = php_indent_group,
  pattern = { "php", "blade" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
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

-- Auto-reload files changed outside of Neovim
opt.autoread = true
local autoread_group = vim.api.nvim_create_augroup("AutoRead", { clear = true })

local function safe_checktime()
  if vim.fn.getcmdwintype() == "" then
    vim.cmd("checktime")
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = autoread_group,
  callback = function()
    vim.opt_local.autoread = true
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "VimResume", "TermLeave" }, {
  group = autoread_group,
  callback = safe_checktime,
})

local uv = vim.uv or vim.loop
if uv and _G.__autoread_timer == nil then
  local timer = uv.new_timer()
  _G.__autoread_timer = timer
  timer:start(2000, 2000, vim.schedule_wrap(function()
    safe_checktime()
  end))

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = autoread_group,
    callback = function()
      if _G.__autoread_timer then
        _G.__autoread_timer:stop()
        _G.__autoread_timer:close()
        _G.__autoread_timer = nil
      end
    end,
  })
end

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
  end,
})

-- Scroll offset
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Folding
opt.foldmethod = "indent"
opt.foldlevel = 99
