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
