-- File Explorer (VSCode-like sidebar)
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local nvimtree = require("nvim-tree")

    -- Disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvimtree.setup({
      view = {
        width = 35,
        relativenumber = true,
      },
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
            },
          },
        },
      },
      actions = {
        open_file = {
          -- Keep tree open when opening files
          quit_on_open = false,
          window_picker = {
            enable = false,
          },
        },
      },
      filters = {
        custom = { ".DS_Store" },
      },
      git = {
        ignore = false,
      },
      -- Custom keybindings inside nvim-tree
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- Default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- VSCode-like navigation
        vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open: Edit or Expand"))
        vim.keymap.set("n", "o", api.node.open.edit, opts("Open: Edit or Expand"))
        vim.keymap.set("n", "l", api.node.open.edit, opts("Open: Expand folder or open file"))
        vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close: Collapse folder"))

        -- Directory navigation - Change root directory
        vim.keymap.set("n", "]", api.tree.change_root_to_node, opts("CD: Enter directory (make it root)"))
        vim.keymap.set("n", "}", api.tree.change_root_to_node, opts("CD: Enter directory (make it root)"))
        vim.keymap.set("n", "[", api.tree.change_root_to_parent, opts("CD: Go up to parent directory"))
        vim.keymap.set("n", "{", api.tree.change_root_to_parent, opts("CD: Go up to parent directory"))
        vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts("CD: Go up to parent directory"))
        vim.keymap.set("n", "<BS>", api.tree.change_root_to_parent, opts("CD: Go up to parent directory"))

        -- Split and tab operations
        vim.keymap.set("n", "s", api.node.open.vertical, opts("Open: Vertical Split"))
        vim.keymap.set("n", "i", api.node.open.horizontal, opts("Open: Horizontal Split"))
        vim.keymap.set("n", "t", api.node.open.tab, opts("Open: New Tab"))

        -- Help
        vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help: Show keymaps"))
      end,
    })

    -- Auto-open nvim-tree when starting nvim without file arguments
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Only open if no file arguments were provided
        if vim.fn.argc() == 0 then
          require("nvim-tree.api").tree.open()
        end
      end,
    })

    -- Keymaps
    local keymap = vim.keymap.set
    keymap("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    keymap("n", "<leader>ef", ":NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" })
    keymap("n", "<leader>ec", ":NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })
    keymap("n", "<leader>er", ":NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })
  end,
}
