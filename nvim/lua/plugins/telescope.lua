-- Fuzzy Finder (VSCode-like Cmd+P)
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  cmd = "Telescope",
  keys = {
    { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files (VSCode-like)" },
    { "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Find text (VSCode-like)" },
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Find recent files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find text in files" },
    { "<leader>fc", "<cmd>Telescope grep_string<cr>", desc = "Find string under cursor" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Find help" },
    { "<leader>fd", "<cmd>Telescope file_browser<cr>", desc = "File browser" },
    { "<leader>fD", "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>", desc = "File browser (current dir)" },
    { "<leader>gl", function() require("config.git_log").repo() end, desc = "Git log (repo)" },
    { "<leader>gL", function() require("config.git_log").file() end, desc = "Git log (file)" },
    { "<leader>hb", function() require("config.git_log").file() end, desc = "Git history (buffer)" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    { "nvim-telescope/telescope-file-browser.nvim" },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- Neovim 0.11 removed ft_to_lang; keep telescope previewer compatible.
    if vim.treesitter
      and vim.treesitter.language
      and vim.treesitter.language.get_lang
      and not vim.treesitter.language.ft_to_lang then
      vim.treesitter.language.ft_to_lang = vim.treesitter.language.get_lang
    end

    local ok_parsers, ts_parsers = pcall(require, "nvim-treesitter.parsers")
    if ok_parsers then
      if not ts_parsers.ft_to_lang then
        ts_parsers.ft_to_lang = function(ft)
          if vim.treesitter and vim.treesitter.language and vim.treesitter.language.get_lang then
            return vim.treesitter.language.get_lang(ft)
          end
          return ft
        end
      end
      if not ts_parsers.get_parser then
        ts_parsers.get_parser = function(bufnr, lang)
          return vim.treesitter.get_parser(bufnr, lang)
        end
      end
    end

    local ok_configs = pcall(require, "nvim-treesitter.configs")
    if not ok_configs then
      local function has_parser(lang)
        if not lang or lang == "" then
          return false
        end
        local matches = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", false)
        return matches and #matches > 0
      end

      package.loaded["nvim-treesitter.configs"] = {
        is_enabled = function(module, lang, _)
          if module ~= "highlight" then
            return false
          end
          return has_parser(lang)
        end,
        get_module = function(_)
          return { additional_vim_regex_highlighting = false }
        end,
      }
    end

    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        path_display = { "truncate" },
        -- Case-insensitive search by default
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          -- Search in hidden files and directories
          hidden = true,
          -- Follow symbolic links
          follow = true,
          -- Only ignore .git directory
          find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
        },
        live_grep = {
          -- Search in hidden files
          additional_args = function()
            return { "--hidden", "--glob", "!.git/*" }
          end,
        },
      },
      extensions = {
        file_browser = {
          theme = "ivy",
          -- Respect .gitignore
          respect_gitignore = true,
          -- Show hidden files
          hidden = true,
          -- Show parent directory
          grouped = true,
        },
      },
    })

    -- Load extensions
    telescope.load_extension("fzf")
    telescope.load_extension("file_browser")
  end,
}
