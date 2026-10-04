-- A gray bolt in the statuscolumn on the cursor line when an LSP code action
-- is available there. The statuscolumn segment (plugins.normal.ui) shows the
-- namespace's signs and opens tiny-code-action on a click.

local M = {}

local ns = vim.api.nvim_create_namespace("code_action_sign")

-- Re-ask only when the line or the text changed
---@type table<integer, { lnum: integer, tick: integer }>
local asked = {}

---@param buf integer
local function clear(buf)
  asked[buf] = nil

  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

---@param buf integer
local function update(buf)
  if buf ~= vim.api.nvim_get_current_buf() then
    return
  end

  local win = vim.api.nvim_get_current_win()
  local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1
  local tick = vim.b[buf].changedtick
  local last = asked[buf]

  if last and last.lnum == lnum and last.tick == tick then
    return
  end

  asked[buf] = { lnum = lnum, tick = tick }

  local diagnostics = vim.tbl_filter(
    function(d)
      return d ~= nil
    end,
    vim.tbl_map(function(d)
      return d.user_data and d.user_data.lsp
    end, vim.diagnostic.get(buf, { lnum = lnum }))
  )

  vim.lsp.buf_request_all(buf, "textDocument/codeAction", function(client)
    local params = vim.lsp.util.make_range_params(win, client.offset_encoding)

    -- Automatic trigger: the user did not ask for the list
    params.context = { diagnostics = diagnostics, triggerKind = 2 }

    return params
  end, function(results)
    -- The cursor has moved on since the request
    local stale = not vim.api.nvim_buf_is_valid(buf)
      or buf ~= vim.api.nvim_get_current_buf()
      or vim.api.nvim_win_get_cursor(0)[1] - 1 ~= lnum

    if stale then
      return
    end

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    for _, response in pairs(results) do
      if response.result and not vim.tbl_isempty(response.result) then
        vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
          sign_text = require("base.constants.icons").code_action,
          sign_hl_group = "CodeActionSign",
          priority = 1000,
        })

        return
      end
    end
  end)
end

-- While the cursor keeps moving, ask once it has paused for this long (ms).
-- The first move after a pause is asked at once.
local delay = 60

---@type table<integer, uv.uv_timer_t>
local timers = {}

---@type table<integer, boolean>
local pending = {}

---@param buf integer
local function request(buf)
  local timer = timers[buf]

  if not timer then
    timer = vim.uv.new_timer()
    timers[buf] = timer
  end

  if timer:is_active() then
    pending[buf] = true
  else
    pending[buf] = false
    update(buf)
  end

  -- Every event restarts the wait; the last one gets the trailing request
  timer:stop()
  timer:start(
    delay,
    0,
    vim.schedule_wrap(function()
      if pending[buf] then
        pending[buf] = false

        if vim.api.nvim_buf_is_valid(buf) then
          update(buf)
        end
      end
    end)
  )
end

---Start showing the sign in a buffer; safe to call again for every client
---@param buf integer
function M.attach(buf)
  if vim.b[buf].code_action_sign then
    return
  end

  vim.b[buf].code_action_sign = true

  local group = vim.api.nvim_create_augroup("code_action_sign_" .. buf, {
    clear = true,
  })

  -- The sign belongs to the line it was asked for
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    group = group,
    buffer = buf,
    callback = function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

      if not asked[buf] or asked[buf].lnum ~= lnum then
        clear(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = buf,
    callback = function()
      clear(buf)
    end,
  })

  -- No waiting for 'updatetime': ask as soon as the cursor lands on a line
  vim.api.nvim_create_autocmd({ "CursorMoved", "InsertLeave", "TextChanged" }, {
    group = group,
    buffer = buf,
    callback = function()
      request(buf)
    end,
  })

  request(buf)

  vim.api.nvim_create_autocmd("BufUnload", {
    group = group,
    buffer = buf,
    callback = function()
      asked[buf] = nil
      pending[buf] = nil

      if timers[buf] then
        timers[buf]:stop()
        timers[buf]:close()
        timers[buf] = nil
      end
    end,
  })
end

-- Gray, like the other inactive indicators
require("base.colors").on_change("code_action_hl", function()
  vim.api.nvim_set_hl(0, "CodeActionSign", {
    fg = require("base.colors").palette().muted,
  })
end, { run = true })

return M
