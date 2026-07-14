-- Floating terminal window
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<C-\>]],
      direction = "float",
      start_in_insert = true,
      float_opts = {
        border = "curved",
        width = 120,
        height = 30,
      },
      on_create = function(t)
        local opts = { noremap = true, silent = true, buffer = t.bufnr }
        vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", opts)
        vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", opts)
        vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", opts)
        vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", opts)
      end,
    })

    local Terminal = require("toggleterm.terminal").Terminal
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- Floating terminal
    keymap("n", "<leader>tf", ":ToggleTerm direction=float<CR>", opts)

    -- Tig (terminal UI for git)
    local tig = Terminal:new({ cmd = "tig", direction = "float" })
    keymap("n", "<leader>tt", function()
      tig:toggle()
    end, opts)

    -- Lazygit
    local lazygit = Terminal:new({ cmd = "lazygit", direction = "float" })
    keymap("n", "<leader>lg", function()
      lazygit:toggle()
    end, opts)
  end,
}
