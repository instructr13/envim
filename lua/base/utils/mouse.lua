local M = {}

---Wrap a function that opens an fzf-lua picker so it works from a click.
---fzf-lua's own startinsert is undone by the mouse release that follows the
---press, which would leave the picker in terminal-Normal mode.
---@param open fun()
---@return fun()
function M.picker(open)
  return function()
    local ns = vim.api.nvim_create_namespace("mouse_picker")

    local function insert()
      if vim.bo.filetype == "fzf" and vim.fn.mode() ~= "t" then
        vim.cmd.startinsert()
      end
    end

    open()

    -- Released before the picker opened, or after
    vim.defer_fn(insert, 50)
    vim.on_key(function(key)
      if vim.fn.keytrans(key):find("Release", 1, true) then
        vim.on_key(nil, ns)
        vim.schedule(insert)
      end
    end, ns)
    vim.defer_fn(function()
      vim.on_key(nil, ns)
    end, 2000)
  end
end

return M
