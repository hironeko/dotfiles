return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "sindrets/diffview.nvim",
  },
  config = function()
    local neogit = require("neogit")

    neogit.setup({
      disable_line_numbers = false,
      disable_signs = false,
      disable_hint = false,
      disable_context_highlighting = false,
      disable_commit_confirmation = false,
      auto_refresh = true,
      auto_show_console = true,
      status = {
        recent_commit_count = 10,
      },
      commit_popup = {
        kind = "split",
      },
    })

    -- Keymaps
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    keymap("n", "<leader>go", ":Neogit<CR>", { desc = "Open Neogit" })
    keymap("n", "<leader>gc", ":Neogit commit<CR>", { desc = "Neogit commit" })
    keymap("n", "<leader>gp", ":Neogit push<CR>", { desc = "Neogit push" })
    keymap("n", "<leader>gl", ":Neogit log<CR>", { desc = "Neogit log" })
    keymap("n", "<leader>gb", ":Neogit branch<CR>", { desc = "Neogit branch" })
  end,
}
