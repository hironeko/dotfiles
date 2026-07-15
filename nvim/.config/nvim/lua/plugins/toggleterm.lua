-- Floating terminal window
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = {
        border = "curved",
        width = 120,
        height = 30,
      }
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
