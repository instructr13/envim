-- Machine-local configuration, kept out of version control:
--
--   lua/vendor/init.lua     Local settings (loaded last)
--   lua/vendor/plugins.lua  Local plugins, managed by vim.pack so they get
--                           their own lockfile (nvim-pack-lock.json) instead
--                           of lazy-lock.json:
--
--     return {
--       "veryl-lang/veryl.vim",
--       {
--         src = "owner/repo",
--         version = "main",  -- branch, tag, commit or vim.version.range()
--         config = function() end,
--       },
--     }

local M = {}

local function has_module(path)
  return vim.api.nvim_get_runtime_file(path, false)[1] ~= nil
end

local function normalize(spec)
  spec = type(spec) == "string" and { src = spec } or vim.deepcopy(spec)

  if not spec.src:find("://", 1, true) then
    spec.src = "https://github.com/" .. spec.src
  end

  spec.name = spec.name or spec.src:match("([^/]+)$"):gsub("%.git$", "")

  return spec
end

local function setup_plugins()
  if not has_module("lua/vendor/plugins.lua") then
    return
  end

  local specs = vim.iter(require("vendor.plugins")):map(normalize):totable()

  if #specs == 0 then
    return
  end

  -- lazy.nvim resets 'packpath'; vim.pack installs under data/site
  vim.opt.packpath:append(vim.fs.joinpath(vim.fn.stdpath("data"), "site"))

  local configs = {}

  for _, spec in ipairs(specs) do
    configs[spec.name] = spec.config
    spec.config = nil
  end

  vim.pack.add(specs, {
    confirm = false,
    -- lazy.nvim turns off 'loadplugins', so source plugin/ files right away
    load = function(plugin)
      vim.cmd.packadd(plugin.spec.name)

      if configs[plugin.spec.name] then
        configs[plugin.spec.name]()
      end
    end,
  })

  local names = vim
    .iter(specs)
    :map(function(spec)
      return spec.name
    end)
    :totable()

  vim.api.nvim_create_user_command("VendorUpdate", function()
    vim.pack.update(names)
  end, { desc = "Update vendor plugins" })
end

function M.setup()
  setup_plugins()

  if has_module("lua/vendor/init.lua") then
    require("vendor")
  end
end

return M
