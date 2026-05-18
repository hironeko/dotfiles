return {
  "sindrets/diffview.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local diffview = require("diffview")
    local actions = require("diffview.actions")

    diffview.setup({
      diff_binaries = false,
      enhanced_diff_hl = false,
      use_icons = true,
      icons = {
        folder_closed = "",
        folder_open = "",
      },
      signs = {
        fold_closed = "",
        fold_open = "",
        done = "✓",
      },
      view = {
        default = {
          layout = "diff2_horizontal",
        },
        file_history = {
          layout = "diff2_horizontal",
        },
      },
      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
          folder_statuses = "only_folded",
        },
        win_config = function()
          return {
            position = "left",
            width = 35,
          }
        end,
      },
      file_history_panel = {
        log_options = {
          git = {
            single_file = {
              diff_merges = "combined",
            },
            multi_file = {
              diff_merges = "first-parent",
            },
          },
        },
        win_config = function()
          return {
            position = "bottom",
            height = 16,
          }
        end,
      },
      default_args = {
        DiffviewOpen = {},
        DiffviewFileHistory = {},
      },
      hooks = {},
      keymaps = {
        disable_defaults = false,
        view = {
          ["<tab>"] = actions.select_next_entry,
          ["<s-tab>"] = actions.select_prev_entry,
          ["gf"] = actions.goto_file,
          ["<C-w><C-f>"] = actions.goto_file_split,
          ["<C-w>gf"] = actions.goto_file_tab,
          ["<leader>e"] = actions.focus_files,
          ["<leader>b"] = actions.toggle_files,
        },
        file_panel = {
          ["j"] = actions.next_entry,
          ["k"] = actions.prev_entry,
          ["<cr>"] = actions.select_entry,
          ["o"] = actions.select_entry,
          ["<2-LeftMouse>"] = actions.select_entry,
          ["-"] = actions.prev_entry,
          ["_"] = actions.prev_entry,
          ["<c-k>"] = actions.prev_entry,
          ["]t"] = actions.next_entry,
          ["[t"] = actions.prev_entry,
          ["<down>"] = actions.next_entry,
          ["<up>"] = actions.prev_entry,
          ["gf"] = actions.goto_file,
          ["<C-w><C-f>"] = actions.goto_file_split,
          ["<C-w>gf"] = actions.goto_file_tab,
          ["i"] = actions.listing_style,
          ["h"] = actions.toggle_flatten_dirs,
          ["E"] = actions.focus_files,
          ["<leader>b"] = actions.toggle_files,
          ["<leader>e"] = actions.focus_files,
        },
        file_history_panel = {
          ["g!"] = actions.options,
          ["<C-A>"] = actions.open_all_folds,
          ["<C-R>"] = actions.close_all_folds,
          ["j"] = actions.next_entry,
          ["k"] = actions.prev_entry,
          ["<cr>"] = actions.select_entry,
          ["o"] = actions.select_entry,
          ["O"] = actions.open_all_folds,
          ["h"] = actions.close_all_folds,
          ["<2-LeftMouse>"] = actions.select_entry,
          ["-"] = actions.prev_entry,
          ["_"] = actions.prev_entry,
          ["<c-k>"] = actions.prev_entry,
          ["]t"] = actions.next_entry,
          ["[t"] = actions.prev_entry,
          ["<down>"] = actions.next_entry,
          ["<up>"] = actions.prev_entry,
          ["gf"] = actions.goto_file,
          ["<C-w><C-f>"] = actions.goto_file_split,
          ["<C-w>gf"] = actions.goto_file_tab,
          ["<leader>b"] = actions.toggle_files,
          ["<leader>e"] = actions.focus_files,
        },
      },
    })

    -- Keymaps
    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true }

    keymap("n", "<leader>gd", ":DiffviewOpen<CR>", { desc = "Diffview: Open diff" })
    keymap("n", "<leader>gh", ":DiffviewFileHistory<CR>", { desc = "Diffview: File history" })
    keymap("n", "<leader>gH", ":DiffviewFileHistory %<CR>", { desc = "Diffview: Current file history" })
    keymap("n", "<leader>gq", ":DiffviewClose<CR>", { desc = "Diffview: Close" })
  end,
}
