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
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- Register additional language mappings
    vim.treesitter.language.register('bash', 'sh')

    local ok_ts, ts = pcall(require, "nvim-treesitter")
    if not ok_ts then
      vim.notify("nvim-treesitter not installed. Run :Lazy sync", vim.log.levels.WARN)
      return
    end

    -- Blade parser (not bundled by default in nvim-treesitter)
    local ok_parsers, parsers_conf = pcall(require, "nvim-treesitter.parsers")
    local function register_blade_parser()
      if not ok_parsers then
        return
      end
      parsers_conf.blade = {
        install_info = {
          url = "https://github.com/EmranMR/tree-sitter-blade",
          files = { "src/parser.c" },
          branch = "main",
          queries = "queries",
        },
        filetype = "blade",
      }
    end
    register_blade_parser()
    vim.api.nvim_create_autocmd("User", {
      pattern = "TSUpdate",
      callback = register_blade_parser,
    })

    -- Install parsers (no-op if already installed)
    pcall(function()
      ts.install(parsers)
    end)

    -- Setup Treesitter configuration
    local ok_configs, configs = pcall(require, "nvim-treesitter.configs")
    if ok_configs then
      configs.setup({
        ensure_installed = parsers,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
          disable = function(lang, bufnr)
            if lang == "php" or lang == "blade" then
              return false
            end
            return false
          end,
        },
        indent = {
          enable = true,
        },
      })
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

    -- Ensure treesitter starts for specific filetypes
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "blade", "php", "javascript", "typescript", "tsx", "html", "css", "json", "lua", "python", "go", "rust" },
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    -- Enable vim syntax highlighting as fallback
    vim.cmd("syntax enable")
  end,
}
