-- Enable every language server whose executable is on $PATH (Mason or any
-- other package manager). Server configs come from nvim-lspconfig's lsp/*.lua.

local tools = require("base.tools")

local M = {}

-- Within each group only the first available server is enabled.
local exclusive_groups = {
  { "vtsls", "ts_ls", "tsgo" },
  {
    "basedpyright",
    "pyright",
    "pyrefly",
    "zuban",
    "ty",
    "jedi_language_server",
    "pylsp",
    "pyre",
  },
  { "clangd", "ccls" },
  { "lua_ls", "emmylua_ls" },
  { "emmet_language_server", "emmet_ls" },
  { "ruff", "ruff_ls" },
  { "marksman", "markdown_oxide" },
  { "tombi", "taplo" },
}

-- Noisy or attach-to-everything servers; enable them by hand if wanted.
local deny = {
  ast_grep = true,
  codebook = true,
  gitlab_duo = true,
  harper_ls = true,
  htmx = true,
  ltex = true,
  ltex_plus = true,
  snyk_ls = true,
  typos_lsp = true,
  unocss = true,
}

-- Executables too generic to prove that a language server is installed.
local generic_bins = {
  R = true,
  bash = true,
  bun = true,
  dotnet = true,
  java = true,
  julia = true,
  lua = true,
  nc = true,
  node = true,
  npx = true,
  perl = true,
  php = true,
  pnpm = true,
  python = true,
  python3 = true,
  racket = true,
  ruby = true,
  sh = true,
  uv = true,
  uvx = true,
}

-- Per-server overrides applied before enabling.
local overrides = {
  -- macOS always ships /usr/bin/sourcekit-lsp; keep it away from C/C++
  sourcekit = { filetypes = { "swift" } },
}

---@return string[]
local function server_bins(name, config)
  if type(config.cmd) == "table" then
    return { config.cmd[1] }
  end

  -- `cmd` is a function (it usually prefers node_modules/.bin): ask Mason's
  -- registry which executables the server's package provides
  return tools.server_bins(name)
end

-- Evaluating a config is the costly part (400+ servers): do it once each
---@type table<string, string[]|false>
local resolved = {}

---@return string[]|false
local function resolve(name)
  local bins = resolved[name]

  if bins == nil then
    bins = false

    local ok, config = pcall(function()
      return vim.lsp.config[name]
    end)

    if ok and config and config.filetypes and #config.filetypes > 0 then
      bins = server_bins(name, config)
    end

    resolved[name] = bins
  end

  return bins
end

---@return string[]
local function candidates()
  return vim
    .iter(tools.runtime_names("lsp/*.lua"))
    :filter(function(name)
      return not deny[name]
    end)
    :totable()
end

---@return string[]
function M.available_servers()
  local executables = tools.path_executables()
  local found = {}

  for _, name in ipairs(candidates()) do
    for _, bin in ipairs(resolve(name) or {}) do
      if
        type(bin) == "string"
        and not generic_bins[bin]
        and tools.is_executable(bin, executables)
      then
        found[name] = true

        break
      end
    end
  end

  tools.apply_exclusive_groups(found, exclusive_groups)

  local servers = vim.tbl_keys(found)

  table.sort(servers)

  return servers
end

local function enable_available()
  local servers = vim
    .iter(M.available_servers())
    :filter(function(name)
      return not vim.lsp.is_enabled(name)
    end)
    :totable()

  for _, name in ipairs(servers) do
    -- mason-lspconfig ships fixes for some servers
    local ok, fix = pcall(require, "mason-lspconfig.lsp." .. name)

    if ok and type(fix) == "table" then
      vim.lsp.config(name, fix)
    end

    if overrides[name] then
      vim.lsp.config(name, overrides[name])
    end
  end

  if #servers > 0 then
    vim.lsp.enable(servers)
  end
end

-- Sliced so that the first scan does not freeze the editor after startup
---@param done fun()
local function resolve_all(done)
  local names = candidates()
  local i = 0

  local function step()
    local deadline = vim.uv.hrtime() + 5e6

    while i < #names do
      i = i + 1

      resolve(names[i])

      if vim.uv.hrtime() > deadline then
        return vim.defer_fn(step, 1)
      end
    end

    done()
  end

  step()
end

local running = false

function M.enable()
  if running then
    return
  end

  running = true

  resolve_all(function()
    running = false

    enable_available()
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("lsp_auto_enable", { clear = true }),
    pattern = "VeryLazy",
    once = true,
    callback = function()
      M.enable()

      -- Pick up servers installed from Mason during the session
      tools.on_install(M.enable)
    end,
  })

  vim.api.nvim_create_user_command("LspAutoEnabled", function()
    vim.print(M.available_servers())
  end, { desc = "List language servers enabled automatically" })
end

return M
