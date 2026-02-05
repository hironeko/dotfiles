-- Custom git log pickers using vim.system to avoid oneshot job issues
local M = {}

local function open_git_log(opts)
  opts = opts or {}

  local ok_pickers, pickers = pcall(require, "telescope.pickers")
  if not ok_pickers then
    vim.notify("telescope not available", vim.log.levels.WARN)
    return
  end

  local finders = require("telescope.finders")
  local make_entry = require("telescope.make_entry")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values

  local args = { "git", "log", "--pretty=format:%h %ad %an %s", "--date=short" }
  if opts.current_file and opts.current_file ~= "" then
    table.insert(args, "--follow")
    table.insert(args, "--")
    table.insert(args, opts.current_file)
  else
    table.insert(args, "--")
    table.insert(args, ".")
  end

  vim.system(args, { text = true, cwd = opts.cwd }, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        local msg = (res.stderr and res.stderr ~= "") and res.stderr or "git log failed"
        vim.notify(msg, vim.log.levels.ERROR)
      end)
      return
    end

    local results = vim.split(res.stdout or "", "\n", { trimempty = true })
    vim.schedule(function()
      opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_git_commits(opts))
      pickers
        .new(opts, {
          prompt_title = opts.prompt_title or "Git Log",
          finder = finders.new_table({ results = results, entry_maker = opts.entry_maker }),
          previewer = {
            previewers.git_commit_diff_to_parent.new(opts),
            previewers.git_commit_diff_to_head.new(opts),
            previewers.git_commit_diff_as_was.new(opts),
            previewers.git_commit_message.new(opts),
          },
          sorter = conf.file_sorter(opts),
        })
        :find()
    end)
  end)
end

function M.repo()
  open_git_log({ prompt_title = "Git Commits" })
end

function M.file()
  local file = vim.api.nvim_buf_get_name(0)
  open_git_log({ prompt_title = "Git BCommits", current_file = file })
end

return M
