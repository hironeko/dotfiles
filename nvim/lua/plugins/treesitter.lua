-- Syntax highlighting and parsing
-- Parsers will be automatically installed when you open files
local parsers = {
  "lua", "vim", "vimdoc", "bash",
  "json", "javascript", "typescript", "tsx",
  "yaml", "html", "css", "php", "blade",
  "markdown", "markdown_inline",
  "python", "go", "rust", "dockerfile", "gitignore",
}

return {
  "nvim-treesitter/nvim-treesitter",
  build = function()
    -- Auto-install parsers on first setup
    local install = require("nvim-treesitter.install")

    for _, parser in ipairs(parsers) do
      pcall(function()
        install.update({ with_sync = false })(parser)
      end)
    end
  end,
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- Treesitter highlighting is enabled by default in Neovim 0.9+
    -- Register additional language mappings
    vim.treesitter.language.register('bash', 'sh')

    local ok_configs, ts_configs = pcall(require, "nvim-treesitter.configs")
    if ok_configs then
      ts_configs.setup({
        ensure_installed = parsers,
        auto_install = true,
        highlight = { enable = true },
      })
    else
      vim.notify("nvim-treesitter not installed. Run :Lazy sync", vim.log.levels.WARN)
    end

    -- Enable ts-autotag for HTML/JSX auto-closing
    local ok_autotag, autotag = pcall(require, "nvim-ts-autotag")
    if ok_autotag then
      autotag.setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        }
      })
    end
  end,
}
