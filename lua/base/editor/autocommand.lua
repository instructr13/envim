local fn, api = vim.fn, vim.api

api.nvim_create_autocmd({ "BufWritePre" }, {
  group = api.nvim_create_augroup("mkdirp", { clear = true }),
  pattern = "*",
  callback = function()
    local dir = fn.expand("<afile>:p:h")

    if dir:find("[%w-]+:/") == 1 then
      return
    end

    if fn.isdirectory(dir) == 0 then
      fn.mkdir(dir, "p")
    end
  end,
})

-- Restore the last cursor position
api.nvim_create_autocmd("BufReadPost", {
  group = api.nvim_create_augroup("lastplace", { clear = true }),
  callback = function(e)
    -- Buffers can be loaded in the background (LSP edits, previews); the
    -- cursor and `zv` below act on the current window
    if
      e.buf ~= api.nvim_get_current_buf()
      or vim.bo[e.buf].buftype ~= ""
      or vim.list_contains({ "gitcommit", "gitrebase" }, vim.bo[e.buf].filetype)
    then
      return
    end

    local mark = api.nvim_buf_get_mark(e.buf, '"')

    if mark[1] > 0 and mark[1] <= api.nvim_buf_line_count(e.buf) then
      pcall(api.nvim_win_set_cursor, 0, mark)
      vim.cmd("normal! zv")
    end
  end,
})

-- Relative line numbers everywhere but Insert mode; <leader>tl turns them off
vim.g.relative_numbers = true

api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
  group = api.nvim_create_augroup("relative_numbers", { clear = true }),
  callback = function(e)
    if vim.wo.number then
      vim.wo.relativenumber = vim.g.relative_numbers
        and e.event == "InsertLeave"
    end
  end,
})
