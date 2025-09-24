local api, fs, uv = vim.api, vim.fs, vim.uv

local M = {}

function M.cd()
  local augroup = api.nvim_create_augroup("CdToRoot", { clear = true })

  api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    callback = function(e)
      -- Find git repo first
      local root = fs.root(e.buf, ".git")

      if root then
        vim.cmd.lcd(root)

        vim.schedule(function()
          api.nvim_del_augroup_by_id(augroup)
        end)

        return
      end

      -- If no root and cwd is $HOME (e.g. opened from GUIs), cd to basename
      local file = fs.abspath(api.nvim_buf_get_name(e.buf))
      local cwd = uv.cwd()

      if not cwd or fs.normalize(cwd) ~= vim.env.HOME then
        return
      end

      local stat = uv.fs_stat(file)

      if stat == nil or stat.type ~= "file" then
        return
      end

      vim.cmd.lcd(fs.dirname(file))

      vim.schedule(function()
        api.nvim_del_augroup_by_id(augroup)
      end)
    end,
  })
end

return M
