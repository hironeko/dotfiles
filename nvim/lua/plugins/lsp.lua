-- LSP Configuration
-- Use vim.lsp.config on Neovim 0.11+, fall back to lspconfig on older versions.
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local keymap = vim.keymap.set

    local opts = { noremap = true, silent = true }
    local on_attach = function(client, bufnr)
      opts.buffer = bufnr

      -- VSCode-like keybindings
      opts.desc = "Show LSP references"
      keymap("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
      keymap("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

      opts.desc = "Go to declaration"
      keymap("n", "gD", vim.lsp.buf.declaration, opts)

      opts.desc = "Show LSP definitions"
      keymap("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

      opts.desc = "Show LSP implementations"
      keymap("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

      opts.desc = "Show LSP type definitions"
      keymap("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

      opts.desc = "See available code actions"
      keymap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

      opts.desc = "Smart rename"
      keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)

      opts.desc = "Show buffer diagnostics"
      keymap("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

      opts.desc = "Show line diagnostics"
      keymap("n", "<leader>d", vim.diagnostic.open_float, opts)

      opts.desc = "Go to previous diagnostic"
      keymap("n", "[d", vim.diagnostic.goto_prev, opts)

      opts.desc = "Go to next diagnostic"
      keymap("n", "]d", vim.diagnostic.goto_next, opts)

      opts.desc = "Show documentation for what is under cursor"
      keymap("n", "K", vim.lsp.buf.hover, opts)

      opts.desc = "Restart LSP"
      keymap("n", "<leader>rs", ":LspRestart<CR>", opts)
    end

    -- Enhanced capabilities
    local capabilities = cmp_nvim_lsp.default_capabilities()

    local use_native = vim.lsp and vim.lsp.config and vim.lsp.enable
    local function setup_server(name, config)
      if use_native then
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      else
        local lspconfig = require("lspconfig")
        lspconfig[name].setup(config)
      end
    end

    -- Diagnostic configuration
    vim.diagnostic.config({
      virtual_text = {
        prefix = "●",
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- Change diagnostic symbols in the sign column
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Configure language servers
    -- TypeScript/JavaScript (updated from tsserver to ts_ls)
    setup_server("ts_ls", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- HTML
    setup_server("html", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- CSS
    setup_server("cssls", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Tailwind CSS
    setup_server("tailwindcss", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Lua
    setup_server("lua_ls", {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
          },
        },
      },
    })

    -- Python
    setup_server("pyright", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Go
    setup_server("gopls", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- Rust
    setup_server("rust_analyzer", {
      capabilities = capabilities,
      on_attach = on_attach,
    })

    -- PHP
    setup_server("intelephense", {
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "php", "blade" },
    })
  end,
}
