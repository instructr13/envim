local M = {}

-- Formatters and linters are derived from Mason's registry (categories and
-- languages) for every tool whose executable is on $PATH, so installing a
-- tool (from Mason or elsewhere) is enough to use it.

-- Formatters shipped with language toolchains, which Mason doesn't package
local toolchain_formatters = {
  rust = { "rustfmt" },
  go = { "gofmt" },
  zig = { "zigfmt" },
  dart = { "dart_format" },
  swift = { "swift" },
  fish = { "fish_indent" },
  elixir = { "mix" },
}

-- Registry entries that rewrite code beyond formatting, or only fit special
-- files (e.g. pyproject-fmt for any TOML)
local formatter_deny = {
  ["ast-grep"] = true,
  autoflake = true,
  doctoc = true,
  docformatter = true,
  json_repair = true,
  ["markdown-toc"] = true,
  markdownlint = true,
  ["markdownlint-cli2"] = true,
  ["pyproject-fmt"] = true,
  pyupgrade = true,
}

-- Lower is preferred when several formatters for a filetype are installed;
-- multi-language formatters go last
local formatter_priority = {
  biome = 1,
  oxfmt = 2,
  prettierd = 3,
  prettier = 4,
  clang_format = 90,
  jq = 91,
}

local function sort_by_priority(names)
  table.sort(names, function(a, b)
    local pa, pb = formatter_priority[a] or 50, formatter_priority[b] or 50

    if pa == pb then
      return a < b
    end

    return pa < pb
  end)

  return names
end

---@return table<string, string[]>
function M.formatters_by_ft()
  local by_ft = require("base.tools").tools_by_filetype({
    category = "Formatter",
    module_glob = "lua/conform/formatters/*.lua",
    deny = formatter_deny,
  })

  for _, names in pairs(by_ft) do
    sort_by_priority(names)
  end

  for ft, names in pairs(toolchain_formatters) do
    by_ft[ft] = vim.list_extend(by_ft[ft] or {}, names)
  end

  return by_ft
end

-- Prefer dedicated formatting servers over general language servers when
-- several attached clients can format
local lsp_format_priority = { "biome", "ruff", "tombi", "stylua" }

---@param bufnr? integer Buffer being formatted (default: current)
---@return fun(client: vim.lsp.Client): boolean
function M.lsp_format_filter(bufnr)
  local names = {}

  for _, c in
    ipairs(vim.lsp.get_clients({
      bufnr = bufnr or vim.api.nvim_get_current_buf(),
      method = "textDocument/formatting",
    }))
  do
    names[c.name] = true
  end

  local preferred = vim.iter(lsp_format_priority):find(function(name)
    return names[name]
  end)

  return function(client)
    return preferred == nil or client.name == preferred
  end
end

-- Linters that also ship a language server are left to the LSP
local function linters_by_ft()
  return require("base.tools").tools_by_filetype({
    category = "Linter",
    module_glob = "lua/lint/linters/*.lua",
    exclude_categories = { "LSP" },
  })
end

function M.lint_setup()
  local lint = require("lint")

  lint.linters_by_ft = linters_by_ft()

  require("base.tools").on_install(function()
    lint.linters_by_ft = linters_by_ft()
  end)

  local function executable(linter)
    local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd

    return type(cmd) == "string" and vim.fn.executable(cmd) == 1
  end

  local function try_lint()
    local names = vim
      .iter(lint.linters_by_ft[vim.bo.filetype] or {})
      :filter(function(name)
        local linter = lint.linters[name]

        return linter ~= nil and executable(linter)
      end)
      :totable()

    if #names > 0 then
      lint.try_lint(names, { ignore_errors = true })
    end
  end

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("lint", { clear = true }),
    callback = try_lint,
  })

  try_lint()
end

function M.conform_init()
  local keymap = require("base.utils.keymap").keymap

  vim.opt.formatexpr = [[v:lua.require("conform").formatexpr()]]

  vim.api.nvim_create_user_command("Format", function(args)
    local range = nil

    if args.count ~= -1 then
      local end_line =
        vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]

      range = {
        start = { args.line1, 0 },
        ["end"] = { args.line2, end_line:len() },
      }
    end

    require("conform").format({
      async = true,
      range = range,
      filter = M.lsp_format_filter(),
    })
  end, { range = true })

  keymap({ "n", "x" }, "<leader>cf", function()
    require("conform").format({
      async = true,
      filter = M.lsp_format_filter(),
    }, function(err)
      if not err then
        local mode = vim.api.nvim_get_mode().mode

        if vim.startswith(string.lower(mode), "v") then
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
            "n",
            true
          )
        end
      end
    end)
  end, "Format range")

  vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
      -- FormatDisable! will disable formatting just for this buffer
      vim.b.disable_autoformat = true
    else
      vim.g.disable_autoformat = true
    end
  end, {
    desc = "Disable format-on-save",
    bang = true,
  })

  vim.api.nvim_create_user_command("FormatEnable", function()
    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
  end, {
    desc = "Re-enable format-on-save",
  })
end

function M.conform_format_on_save(bufnr)
  -- Skip formatter when saved with w!
  if vim.v.cmdbang == 1 then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  local basename = vim.fs.basename(name)

  if basename:match("%.lock$") or basename:match("%plock%p") then
    -- do not format lock files
    return nil
  end

  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return
  end

  return { timeout_ms = 500, filter = M.lsp_format_filter(bufnr) }
end

return M
