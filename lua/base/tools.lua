-- Helpers to detect installed tools using Mason's registry as metadata.
-- mason.nvim prepends its bin directory to $PATH, so scanning $PATH covers
-- both Mason packages and tools installed by other package managers.

local M = {}

local executables_cache

---Scanning $PATH is costly, so the result is kept until a Mason install.
---@return table<string, true> # Executable names found on $PATH
function M.path_executables()
  if executables_cache then
    return executables_cache
  end

  local found = {}

  for dir in
    vim.gsplit(vim.env.PATH or "", ":", { plain = true, trimempty = true })
  do
    local handle = vim.uv.fs_scandir(dir)

    while handle do
      local name = vim.uv.fs_scandir_next(handle)

      if not name then
        break
      end

      found[name] = true
    end
  end

  executables_cache = found

  return found
end

---@param bin string
---@param executables table<string, true>
function M.is_executable(bin, executables)
  if bin:find("/", 1, true) then
    return vim.fn.executable(bin) == 1
  end

  return executables[bin] == true
end

local function registry()
  local ok, reg = pcall(require, "mason-registry")

  return ok and reg or nil
end

local install_callbacks = {}

---Run `callback` after a Mason package was installed (new executables).
---@param callback fun()
function M.on_install(callback)
  local reg = registry()

  if not reg then
    return
  end

  if #install_callbacks == 0 then
    reg:on(
      "package:install:success",
      vim.schedule_wrap(function()
        executables_cache = nil

        for _, cb in ipairs(install_callbacks) do
          cb()
        end
      end)
    )
  end

  table.insert(install_callbacks, callback)
end

---Names (file basename without extension) of the runtime files matching `glob`.
---@param glob string
---@return string[]
function M.runtime_names(glob)
  local names, seen = {}, {}

  for _, file in ipairs(vim.api.nvim_get_runtime_file(glob, true)) do
    local name = vim.fs.basename(file):gsub("%.[^.]*$", "")

    if not seen[name] then
      seen[name] = true

      table.insert(names, name)
    end
  end

  return names
end

---@param spec table Mason package spec
---@return string[]
function M.package_bins(spec)
  return vim.tbl_keys(spec.bin or {})
end

---Executables provided by the Mason package of an lspconfig server.
---@param server string
---@return string[]
function M.server_bins(server)
  local reg = registry()
  local ok, mappings = pcall(function()
    return require("mason-lspconfig").get_mappings().lspconfig_to_package
  end)

  if not reg or not ok then
    return {}
  end

  local has_pkg, pkg = pcall(reg.get_package, mappings[server] or "")

  return has_pkg and M.package_bins(pkg.spec) or {}
end

-- Mason language names that differ from Nvim filetypes
local language_filetypes = {
  ["c#"] = "cs",
  ["c++"] = "cpp",
  ["f#"] = "fsharp",
  jsx = "javascriptreact",
  latex = "tex",
  ["objective-c"] = "objc",
  protobuf = "proto",
  shell = "sh",
  tsx = "typescriptreact",
}

local known_filetypes

local function language_to_filetype(language)
  if not known_filetypes then
    known_filetypes = {}

    for _, ft in ipairs(vim.fn.getcompletion("", "filetype")) do
      known_filetypes[ft] = true
    end
  end

  local ft = language_filetypes[language:lower()] or language:lower()

  return known_filetypes[ft] and ft or nil
end

---Build a filetype -> tool names map from Mason's registry.
---Only tools whose executable is on $PATH and which `module_glob` provides a
---definition for (e.g. conform's formatters) are included.
---@param opts { category: string, module_glob: string, exclude_categories?: string[], deny?: table<string, true> }
---@return table<string, string[]>
function M.tools_by_filetype(opts)
  local reg = registry()

  if not reg then
    return {}
  end

  local modules = {}

  for _, name in ipairs(M.runtime_names(opts.module_glob)) do
    modules[name] = true
  end

  local executables = M.path_executables()
  local by_ft = {}

  for _, spec in ipairs(reg.get_all_package_specs()) do
    local excluded = vim.iter(opts.exclude_categories or {}):any(function(c)
      return vim.list_contains(spec.categories, c)
    end)

    local name = modules[spec.name] and spec.name
      or modules[(spec.name:gsub("-", "_"))] and spec.name:gsub("-", "_")

    if
      name
      and not excluded
      and not (opts.deny or {})[name]
      and vim.list_contains(spec.categories, opts.category)
      and vim.iter(M.package_bins(spec)):any(function(bin)
        return executables[bin]
      end)
    then
      for _, language in ipairs(spec.languages or {}) do
        local ft = language_to_filetype(language)

        if ft then
          by_ft[ft] = by_ft[ft] or {}

          if not vim.list_contains(by_ft[ft], name) then
            table.insert(by_ft[ft], name)
          end
        end
      end
    end
  end

  return by_ft
end

---Keep only the first available member of each group, in group order.
---@param set table<string, true> Modified in place
---@param groups string[][]
function M.apply_exclusive_groups(set, groups)
  for _, group in ipairs(groups) do
    local winner

    for _, name in ipairs(group) do
      if set[name] then
        if winner then
          set[name] = nil
        else
          winner = name
        end
      end
    end
  end
end

return M
