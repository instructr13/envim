local M = {}

local quit_with_q = {
  filetypes = {
    -- Code from LazyVim
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "query",
    "startuptime",
    "checkhealth",
    "grug-far",

    -- vim-dadbod
    "dbout",

    -- quickfix
    "qf",
  },
}

local ignore_buf_change_filetypes =
  vim.list_extend(vim.deepcopy(quit_with_q.filetypes), {
    "oil",
  })

M.window = {
  quit_with_q = quit_with_q,
  ignore_buf_change_filetypes = ignore_buf_change_filetypes,
}

return M
