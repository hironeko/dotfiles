-- Which Key - shows available keybindings
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 1000
  end,
  opts = {
    -- Your configuration comes here
    -- or leave it empty to use the default settings
  },
}
