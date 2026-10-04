local M = {}

local function setup_diagnostic()
  local icons = require("base.constants.icons").diagnostics

  local virt_lines_ns = vim.api.nvim_create_namespace("on_diagnostic_jump")

  local function on_jump(diagnostic, bufnr)
    if not diagnostic then
      return
    end

    vim.diagnostic.show(virt_lines_ns, bufnr, { diagnostic }, {
      virtual_lines = { current_line = true },
      virtual_text = false,
    })
  end

  vim.diagnostic.config({
    severity_sort = true,
    jump = { on_jump = on_jump },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = icons.Error .. " ",
        [vim.diagnostic.severity.WARN] = icons.Warn .. " ",
        [vim.diagnostic.severity.INFO] = icons.Info .. " ",
        [vim.diagnostic.severity.HINT] = icons.Hint .. " ",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticError",
        [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
        [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
        [vim.diagnostic.severity.HINT] = "DiagnosticHint",
      },
    },
  })
end

local function enable_features()
  vim.lsp.inlay_hint.enable()
  vim.lsp.linked_editing_range.enable()
  vim.lsp.on_type_formatting.enable()
  vim.lsp.inline_completion.enable()
end

---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  local set = require("base.utils.keymap").keymap
  local keymap =
    require("base.utils.keymap").omit("append", "n", "", { buffer = bufnr })

  -- Prefer LSP folding over Treesitter folding when available
  if client:supports_method("textDocument/foldingRange", bufnr) then
    vim.b[bufnr].lsp_folding = true

    require("base.editor").set_foldexpr(bufnr, "v:lua.vim.lsp.foldexpr()")
  end

  if client:supports_method("textDocument/hover", bufnr) then
    keymap("K", function()
      require("pretty_hover").hover()
    end, "Hover")
  end

  if client:supports_method("textDocument/rename", bufnr) then
    keymap("grn", function()
      require("live-rename").rename({ insert = true, cursorpos = -1 })
    end, "Rename")
  end

  if client:supports_method("textDocument/codeAction", bufnr) then
    set({ "n", "x" }, "gra", function()
      require("tiny-code-action").code_action({})
    end, "Code Action", { buffer = bufnr })
  end

  if client:supports_method("textDocument/references", bufnr) then
    keymap("grr", "<cmd>Glance references<cr>", "Peek References")
  end

  if client:supports_method("textDocument/implementation", bufnr) then
    keymap("gri", "<cmd>Glance implementations<cr>", "Peek Implementations")
  end

  if client:supports_method("textDocument/typeDefinition", bufnr) then
    keymap("grt", "<cmd>Glance type_definitions<cr>", "Peek Type Definition")
  end

  if
    client:supports_method("textDocument/definition", bufnr)
    or client:supports_method("textDocument/references", bufnr)
  then
    keymap("gd", function()
      require("definition-or-references").definition_or_references()
    end, "Go To Definition")

    keymap("<C-LeftMouse>", function()
      local pos = vim.fn.getmousepos()

      -- Clicks outside of a window (or past its text) have no position
      if pos.winid == 0 or pos.line == 0 then
        return
      end

      vim.api.nvim_set_current_win(pos.winid)
      pcall(
        vim.api.nvim_win_set_cursor,
        pos.winid,
        { pos.line, math.max(pos.column - 1, 0) }
      )

      require("definition-or-references").definition_or_references()
    end, "Go To Definition (click)")
  end

  if client:supports_method("textDocument/declaration", bufnr) then
    keymap("gD", vim.lsp.buf.declaration, "Go To Declaration")
  end

  if client:supports_method("textDocument/documentHighlight", bufnr) then
    keymap("<a-n>", function()
      require("illuminate").next_reference({ wrap = true })
    end, "Next Reference")

    keymap("<a-p>", function()
      require("illuminate").next_reference({ wrap = true, reverse = true })
    end, "Previous Reference")
  end

  if client:supports_method("textDocument/inlineCompletion", bufnr) then
    set("i", "<M-l>", function()
      if not vim.lsp.inline_completion.get() then
        return "<M-l>"
      end
    end, "Accept inline completion", { buffer = bufnr, expr = true })
  end
end

-- Without a folding server, `vim.lsp.foldexpr()` would leave the window with
-- no folds at all: hand folding back to Treesitter
---@param bufnr integer
---@param client_id integer
local function restore_folding(bufnr, client_id)
  if not vim.b[bufnr].lsp_folding then
    return
  end

  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if
      c.id ~= client_id
      and c:supports_method("textDocument/foldingRange", bufnr)
    then
      return
    end
  end

  vim.b[bufnr].lsp_folding = nil

  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
  local ok, folds = pcall(vim.treesitter.query.get, lang or "", "folds")
  local expr = ok and folds and "v:lua.vim.treesitter.foldexpr()"

  require("base.editor").set_foldexpr(bufnr, expr or nil)
end

function M.setup()
  setup_diagnostic()
  enable_features()

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
    callback = function(e)
      local client = vim.lsp.get_client_by_id(e.data.client_id)

      if client then
        on_attach(client, e.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("UserLspFolding", { clear = true }),
    callback = function(e)
      -- Detach also fires when a buffer is wiped out
      if vim.api.nvim_buf_is_valid(e.buf) then
        restore_folding(e.buf, e.data.client_id)
      end
    end,
  })

  require("base.lsp.auto_enable").setup()
end

return M
