local api, fs, uv = vim.api, vim.fs, vim.uv

local M = {}

-- cd to the project root (or the file's directory when started from $HOME)
-- once, for the first real file opened
function M.cd()
  local augroup = api.nvim_create_augroup("CdToRoot", { clear = true })

  api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    callback = function(e)
      local name = api.nvim_buf_get_name(e.buf)

      if name == "" or vim.bo[e.buf].buftype ~= "" then
        return
      end

      local file = fs.abspath(name)
      local stat = uv.fs_stat(file)

      if stat == nil or stat.type ~= "file" then
        return
      end

      api.nvim_del_augroup_by_id(augroup)

      local root = fs.root(file, ".git")

      if root then
        vim.cmd.cd(root)

        return
      end

      local cwd = uv.cwd()

      if cwd and fs.normalize(cwd) == vim.env.HOME then
        vim.cmd.cd(fs.dirname(file))
      end
    end,
  })
end

---Set the fold method of every window showing `bufnr`.
---@param bufnr integer
---@param expr? string 'foldexpr'; nil falls back to manual folds
function M.set_foldexpr(bufnr, expr)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.wo[win][0].foldmethod = expr and "expr" or "manual"
    vim.wo[win][0].foldexpr = expr or "0"
  end
end

return M
