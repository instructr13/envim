local fn, fs, uv = vim.fn, vim.fs, vim.uv

local keymap = require("base.utils.keymap").keymap

local data_dir = fn.stdpath("data")

local plugin_manager_repo = "folke/lazy.nvim"
local plugin_manager_name = "lazy"
local plugin_manager_identifier = "lazy.nvim"
local plugin_manager_path =
  fs.joinpath(data_dir, plugin_manager_name, plugin_manager_identifier)

local M = {}

local function disable_builtin_plugins()
  vim.g.loaded_tutor_mode_plugin = 1
  vim.g.loaded_spellfile_plugin = 1

  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwSettings = 1
  vim.g.loaded_netrwFileHandlers = 1

  vim.g.loaded_python3_provider = 0
  vim.g.loaded_ruby_provider = 0
  vim.g.loaded_node_provider = 0
  vim.g.loaded_perl_provider = 0
end

local function bootstrap_plugin_manager()
  if uv.fs_stat(plugin_manager_path) then
    return
  end

  local out = fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    string.format("https://github.com/%s", plugin_manager_repo),
    "--branch=stable",
    plugin_manager_path,
  })

  if vim.v.shell_error ~= 0 then
    -- Without a UI nobody can press a key, so getchar() would block forever
    if #vim.api.nvim_list_uis() == 0 then
      io.stderr:write("Failed to bootstrap plugin manager:\n", out, "\n")

      os.exit(1)
    end

    vim.api.nvim_echo({
      { "Failed to bootstrap plugin manager:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})

    vim.fn.getchar()
    os.exit(1)
  end
end

local function configure_plugin_manager()
  local spec = {
    { import = "plugins.core" },
  }

  if not vim.g.vscode then
    table.insert(spec, { import = "plugins.normal" })
  end

  require("lazy").setup({
    spec = spec,
    defaults = {
      lazy = false,
      version = false,
    },
    diff = {
      cmd = "diffview.nvim",
    },
    install = {
      colorscheme = { require("base.colors").colorscheme, "default" },
    },
    rocks = { enabled = false },
    checker = { enabled = false },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip",
          "matchit",
          "matchparen",
          "netrwPlugin",
          "tarPlugin",
          "tutor",
          "zipPlugin",
        },
      },
    },
  })

  keymap("n", "<leader>pl", "<cmd>Lazy<cr>", "Plugin manager (Lazy)")
end

function M.setup()
  disable_builtin_plugins()

  bootstrap_plugin_manager()

  vim.opt.rtp:prepend(plugin_manager_path)

  configure_plugin_manager()
end

return M
