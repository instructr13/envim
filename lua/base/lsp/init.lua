local M = {}

local function setup_dianostic()
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
    signs = false,
    -- virtual_text = {
    --   spacing = 4,
    --   source = "if_many",
    --   virt_text_pos = "eol_right_align",
    --   prefix = function(diagnostic)
    --     for severity, icon in pairs(icons) do
    --       if
    --         diagnostic.severity == vim.diagnostic.severity[severity:upper()]
    --       then
    --         return icon .. " "
    --       end
    --     end
    --   end,
    -- },
  })
end

---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  local keymap =
    require("base.utils.keymap").omit("append", "n", "", { buffer = bufnr })

  local cap = client.server_capabilities

  if cap["renameProvider"] then
    keymap("grn", function()
      require("live-rename").rename({ insert = true, cursorpos = -1 })
    end, "Rename")
  end

  if cap["inlayHintProvider"] then
    vim.lsp.inlay_hint.enable(true, { bufnr })
  end

  if cap["definitionProvider"] or cap["referencesProvider"] then
    keymap("gd", function()
      require("definition-or-references").definition_or_references()
    end, "Go To Definition")

    keymap("<C-LeftMouse>", function()
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<LeftMouse>", false, false, true),
        "in",
        false
      )

      -- defer to let nvim refresh to get correct position
      vim.defer_fn(function()
        require("definition-or-references").definition_or_references()
      end, 0)
    end)
  end

  if cap["referencesProvider"] then
    keymap("<a-n>", function()
      require("illuminate").next_reference({ wrap = true })
    end, "Next Reference")

    keymap("<a-p>", function()
      require("illuminate").next_reference({ wrap = true, reverse = true })
    end, "Previous Reference")
  end

  if cap["declarationProvider"] then
    keymap("gD", function()
      vim.lsp.buf.declaration()
    end, "Go To Declaration")
  end

  if cap["typeDefinitionProvider"] then
    local function type_definition()
      local ok, trouble = pcall(require, "trouble")

      if not ok then
        vim.lsp.buf.type_definition()

        return
      end

      trouble.toggle("lsp_type_definitions")
    end

    keymap("go", function()
      type_definition()
    end, "Go To Type Definition")
  end

  if cap["implementationProvider"] then
    keymap("gI", function()
      vim.lsp.buf.implementation()
    end, "Go To Implementation")
  end
end

M.dianostic_icons = {
  Error = "",
  Warn = "",
  Info = "",
  Hint = "",
}

function M.setup()
  setup_dianostic()

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(e)
      local client = vim.lsp.get_client_by_id(e.data.client_id)

      if client == nil then
        return
      end

      local bufnr = e.buf

      on_attach(client, bufnr)
    end,
  })
end

return M
