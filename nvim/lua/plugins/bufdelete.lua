-- Smart buffer deletion (fixes nvim-tree issue)
return {
  "famiu/bufdelete.nvim",
  event = "VeryLazy",
  config = function()
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }
    keymap("n", "<leader>x", "<cmd>Bdelete<cr>", { desc = "Close buffer", noremap = true, silent = true })
    keymap("n", "<leader>bd", "<cmd>Bdelete<cr>", { desc = "Close buffer", noremap = true, silent = true })
    keymap("n", "<leader>bx", "<cmd>Bdelete!<cr>", { desc = "Force close buffer", noremap = true, silent = true })
    keymap("n", "<C-q>", "<cmd>Bdelete<cr>", { desc = "Close buffer", noremap = true, silent = true })
  end,
}
