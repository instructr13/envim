local M = {}

local api, fn = vim.api, vim.fn

local function round(v)
  if tostring(v):find("%.") == nil then
    return math.floor(v)
  else
    local dec = tonumber(tostring(v):match("%.%d+"))
    if dec >= 0.5 then
      return math.ceil(v)
    else
      return math.floor(v)
    end
  end
end

local function bi_fsize(size)
  size = size > 0 and size or 0

  -- bytes
  if size < 1024 then
    return { size = size, postfix = "B" }
    -- kibibytes
  elseif size >= 1024 and size <= 1024 * 1024 then
    return { size = round(size * 2 ^ -10 * 100) / 100, postfix = "KiB" }
  end

  -- mebibytes
  return { size = round(size * 2 ^ -20 * 100) / 100, postfix = "MiB" }
end

-- First diagnostic line per severity, and counts
local function diagnostic_summary(buf)
  local counts = vim.diagnostic.count(buf)
  local first = {}

  for _, d in ipairs(vim.diagnostic.get(buf)) do
    if not first[d.severity] or d.lnum < first[d.severity] then
      first[d.severity] = d.lnum
    end
  end

  return counts, first
end

local function create_arrow(win, lnum)
  local row = api.nvim_win_get_cursor(win)[1]

  if row > lnum then
    return ""
  elseif row == lnum then
    return ""
  end

  return ""
end

-- Floating diagnostics summary under the winbar (dropbar.nvim)
function M.incline()
  local severity = vim.diagnostic.severity
  local icons = vim.diagnostic.config().signs.text

  local function to_hex(number)
    if number == nil then
      return "NONE"
    end

    return ("#%06x"):format(number)
  end

  local colors

  local function update_colors()
    local palette = require("base.colors").palette()

    local function hl(name, attr)
      return to_hex(require("base.colors").hl(name)[attr])
    end

    colors = {
      inactive = palette.faint,
      ok = palette.green,
      [severity.ERROR] = {
        hl("DiagnosticError", "fg"),
        hl("DiagnosticVirtualTextError", "bg"),
      },
      [severity.WARN] = {
        hl("DiagnosticWarn", "fg"),
        hl("DiagnosticVirtualTextWarn", "bg"),
      },
      [severity.INFO] = {
        hl("DiagnosticInfo", "fg"),
        hl("DiagnosticVirtualTextInfo", "bg"),
      },
      [severity.HINT] = {
        hl("DiagnosticHint", "fg"),
        hl("DiagnosticVirtualTextHint", "bg"),
      },
    }
  end

  require("base.colors").on_change(
    "incline_colors",
    update_colors,
    { run = true }
  )

  require("incline").setup({
    window = {
      placement = { horizontal = "right", vertical = "top" },
      margin = { horizontal = 1, vertical = 0 },
      padding = 1,
      zindex = 40,
    },
    hide = {
      cursorline = true,
    },
    ignore = {
      buftypes = function(_, buftype)
        return buftype ~= ""
      end,
      unlisted_buffers = true,
    },
    render = function(props)
      local counts, first = diagnostic_summary(props.buf)
      local label = {}

      for _, s in ipairs({
        severity.ERROR,
        severity.WARN,
        severity.INFO,
        severity.HINT,
      }) do
        local count = counts[s] or 0

        -- Errors and warnings are always shown, info and hints only if any
        if count > 0 or s <= severity.WARN then
          table.insert(label, {
            icons[s] .. count,
            guifg = count > 0 and colors[s][1] or colors.inactive,
          })

          if count > 0 then
            local lnum = first[s] + 1

            table.insert(label, {
              create_arrow(props.win, lnum),
              guifg = colors[s][2],
            })
            table.insert(label, { tostring(lnum), guifg = colors[s][1] })
          end

          table.insert(label, { " " })
        end
      end

      local ok = next(counts) == nil

      table.insert(label, {
        require("base.constants.icons").diagnostics.Ok .. " ",
        guifg = ok and colors.ok or colors.inactive,
      })

      return label
    end,
  })
end

-- Winbar on nvim-treesitter-context's background, with symbol names colored
-- like their kind icons
function M.set_dropbar_hl()
  local hl = require("base.colors").hl

  local bg = hl("TreesitterContext").bg or hl("NormalFloat").bg

  api.nvim_set_hl(0, "WinBar", { fg = hl("Normal").fg, bg = bg })
  api.nvim_set_hl(0, "WinBarNC", { fg = hl("Comment").fg, bg = bg })
  api.nvim_set_hl(0, "DropBarFileName", { bold = true })
  api.nvim_set_hl(0, "DropBarFileNameModified", {
    fg = hl("DiagnosticWarn").fg,
    bold = true,
    italic = true,
  })

  for name in pairs(api.nvim_get_hl(0, {})) do
    local kind = name:match("^DropBarIconKind(.+)$")

    if kind and not kind:match("NC$") then
      api.nvim_set_hl(0, "DropBarKind" .. kind, { link = name })
    end
  end
end

function M.dropbar()
  local sources = require("dropbar.sources")
  local utils = require("dropbar.utils")

  -- Highlight the file name, and mark modified buffers
  local path = {
    get_symbols = function(buf, win, cursor)
      local symbols = sources.path.get_symbols(buf, win, cursor)
      local file = symbols[#symbols]

      if file and vim.bo[buf].buftype == "" then
        file.name_hl = "DropBarFileName"

        if vim.bo[buf].modified then
          file.name = file.name .. " [+]"
          file.name_hl = "DropBarFileNameModified"
        end
      end

      return symbols
    end,
  }

  local symbols = {}

  for kind, icon in pairs(require("base.constants.icons").kinds) do
    -- Keep dropbar's own folder icon for paths
    if kind ~= "Folder" then
      symbols[kind] = icon .. " "
    end
  end

  return {
    icons = {
      kinds = { symbols = symbols },
    },
    bar = {
      enable = function(buf, win, _)
        buf = vim._resolve_bufnr(buf)

        if
          not api.nvim_buf_is_valid(buf)
          or not api.nvim_win_is_valid(win)
          or fn.win_gettype(win) ~= ""
          or vim.wo[win].winbar ~= ""
          or vim.bo[buf].filetype == "help"
        then
          return false
        end

        if
          api.nvim_buf_get_offset(buf, api.nvim_buf_line_count(buf))
          > 1024 * 1024
        then
          return false
        end

        return vim.bo[buf].filetype == "oil"
          or vim.bo[buf].buftype == "terminal"
          or vim.bo[buf].filetype == "markdown"
          or vim.treesitter.get_parser(buf, nil, { error = false }) ~= nil
          or not vim.tbl_isempty(vim.lsp.get_clients({
            bufnr = buf,
            method = "textDocument/documentSymbol",
          }))
      end,
      sources = function(buf, _)
        if vim.bo[buf].buftype == "terminal" then
          return { sources.terminal }
        end

        if vim.bo[buf].filetype == "oil" then
          return { path }
        end

        if vim.bo[buf].filetype == "markdown" then
          return { path, sources.markdown }
        end

        return {
          path,
          utils.source.fallback({ sources.lsp, sources.treesitter }),
        }
      end,
    },
    sources = {
      path = {
        relative_to = function(buf, win)
          local name = api.nvim_buf_get_name(buf)

          local ok, cwd = pcall(fn.getcwd, win)

          cwd = ok and cwd or fn.getcwd()

          -- oil:// buffers: relative to cwd when inside it, else the full path
          if vim.startswith(name, "oil://") then
            local dir = name:gsub("^%S+://", "", 1)

            if vim.fs.relpath(cwd, dir) then
              return cwd
            end

            while dir ~= vim.fs.dirname(dir) do
              dir = vim.fs.dirname(dir)
            end

            return dir
          end

          return cwd
        end,
      },
    },
  }
end

local function setup_colors()
  local lib = require("heirline-components.all")
  local utils = require("heirline.utils")

  local colors = vim.tbl_extend("error", require("base.colors").palette(), {
    dark_red = utils.get_highlight("DiffDelete").bg,
  })

  return vim.tbl_extend(
    "force",
    colors,
    lib.hl.get_colors(),
    require("base.colors").mode_colors()
  )
end

function M.statusline()
  local heirline = require("heirline")
  local lib = require("heirline-components.all")
  local utils = require("heirline.utils")
  local conditions = require("heirline.conditions")

  lib.init.subscribe_to_events()
  heirline.load_colors(setup_colors())

  require("base.colors").on_change("Heirline", function()
    utils.on_colorscheme(setup_colors)
  end)

  local statusline = {
    hl = {
      fg = "subtle",
      bg = "bar_bg",
    },
  }

  -- Utilities
  local Align = { provider = "%=" }
  local Space = { provider = " " }
  local Separator = { provider = " │ ", hl = { fg = "border" } }

  local Left = {}

  table.insert(Left, lib.component.mode())

  local FileFlags = {
    condition = function(self)
      return self.filetype ~= "" and vim.bo.buftype == ""
    end,

    {
      update = "BufModifiedSet",

      provider = " ",
      hl = function()
        local fg = vim.bo.modified and "green" or "faint"

        return { fg = fg }
      end,
    },
    {
      update = { "BufReadPost", "BufNewFile" },

      provider = "",
      hl = function()
        local fg = (not vim.bo.modifiable or vim.bo.readonly) and "orange"
          or "faint"

        return { fg = fg }
      end,
    },
    { provider = " " },
  }

  local LeftSeparator = {
    condition = function(self)
      return self.filetype ~= "" and vim.bo.buftype ~= "terminal"
    end,

    Separator,
  }

  Left = utils.insert(
    Left,
    lib.component.file_info({
      file_icon = false,
      filetype = {
        padding = { right = 1 },
      },
      surround = false,
      file_read_only = false,
    }),
    FileFlags,
    LeftSeparator
  )

  local QuickFixBlock = {
    condition = function()
      return vim.bo.buftype == "quickfix"
    end,

    init = function(self)
      self.qflist = fn.getqflist() or {}

      local idx = 1

      for _, i in ipairs(self.qflist) do
        if i.valid == 1 then
          i["_idx"] = idx
          idx = idx + 1
        end
      end
    end,
  }

  local QuickFixIcon = {
    provider = "  ",

    hl = { fg = "green" },
  }

  local QuickFixText = {
    {
      provider = "QF",
    },
    {
      provider = "  ",

      hl = { fg = "muted" },
    },
    {
      provider = function(self)
        local idx = fn.getqflist({ idx = 0 }).idx

        if
          #self.qflist > 0
          and idx ~= nil
          and self.qflist[idx]["_idx"] ~= nil
        then
          return self.qflist[idx]["_idx"]
        else
          return 0
        end
      end,

      hl = { bold = true },
    },
    {
      provider = " of ",

      hl = { fg = "muted" },
    },
    {
      provider = function(self)
        local count = 0

        if #self.qflist > 0 then
          for _, i in ipairs(self.qflist) do
            if i.valid == 1 then
              count = count + 1
            end
          end
        end

        return count
      end,

      hl = { bold = true },
    },
    {
      condition = function(self)
        self.buffers = {}

        if #self.qflist > 0 then
          for _, t in ipairs(self.qflist) do
            if
              t.valid == 1 and #self.buffers == 0
              or t.valid == 1 and self.buffers[#self.buffers] ~= t.bufnr
            then
              table.insert(self.buffers, t.bufnr)
            end
          end
        end

        return #self.buffers ~= 0
      end,

      {
        provider = " in ",

        hl = { fg = "muted" },
      },
      {
        provider = function(self)
          return #self.buffers .. " "
        end,
      },
      {
        provider = function(self)
          return "file" .. (#self.buffers > 1 and "s" or "")
        end,

        hl = { fg = "muted" },
      },
    },
  }

  QuickFixBlock =
    utils.insert(QuickFixBlock, QuickFixIcon, QuickFixText, Separator)
  Left = utils.insert(Left, QuickFixBlock)

  local GitBranch = {
    condition = conditions.is_git_repo,

    provider = " ",

    hl = { fg = "orange" },

    {
      provider = function()
        return vim.b.gitsigns_status_dict.head
      end,

      hl = { fg = "text" },
    },
  }

  Left = utils.insert(Left, GitBranch)

  local TerminalBlock = {
    condition = function()
      return vim.bo.buftype == "terminal"
    end,

    update = "TermOpen",
  }

  local TerminalIcon = {
    provider = " ",
    hl = { fg = "green" },
  }

  local TerminalName = {
    provider = function()
      local tname, _ = api.nvim_buf_get_name(0):gsub(".*:", "")

      return tname
    end,
  }

  TerminalBlock = utils.insert(TerminalBlock, TerminalIcon, TerminalName, Space)
  Left = utils.insert(Left, TerminalBlock)

  local HelpBlock = {
    condition = function()
      return vim.bo.filetype == "help"
    end,
  }

  local HelpIcon = {
    provider = " ",
    hl = { fg = "blue" },
  }

  local HelpFileName = {
    provider = function()
      local filename = api.nvim_buf_get_name(0)

      return fn.fnamemodify(filename, ":t")
    end,
  }

  HelpBlock = utils.insert(HelpBlock, HelpIcon, HelpFileName)
  Left = utils.insert(Left, HelpBlock)

  statusline = utils.insert(statusline, Left, Align)

  local Center = {}

  -- The search count is shown at the match by nvim-hlslens
  Center = utils.insert(
    Center,
    lib.component.cmd_info({
      search_count = false,
      surround = {
        condition = function()
          local condition = require("heirline-components.core.condition")

          return condition.is_macro_recording()
            or condition.is_statusline_showcmd()
        end,
      },
    })
  )

  local WorkDirIcon = {
    provider = " ",

    hl = { fg = "blue" },
  }

  local WorkDir = {
    init = function(self)
      self.indicator = (fn.haslocaldir(0) == 1 and " (L)" or "") .. " "
      self.cwd = fn.fnamemodify(fn.getcwd(0), ":~")
    end,
    hl = { fg = "subtle", bold = false },

    flexible = 1,

    {
      -- evaluates to the full-length path
      provider = function(self)
        local trail = self.cwd:sub(-1) == "/" and "" or "/"

        return self.indicator .. self.cwd .. trail .. " "
      end,
    },
    {
      -- evaluates to the shortened path
      provider = function(self)
        local cwd = fn.pathshorten(self.cwd)
        local trail = self.cwd:sub(-1) == "/" and "" or "/"

        return self.indicator .. cwd .. trail .. " "
      end,
    },
    {
      -- evaluates to "", hiding the component
      provider = "",
    },
  }

  Center = utils.insert(Center, WorkDirIcon, WorkDir)

  Center = utils.insert(Center, lib.component.virtual_env())

  statusline = utils.insert(statusline, Center, Align)

  local Right = {}

  local IndentBlock = {
    init = function(self)
      self.use_spaces = vim.bo.expandtab
      self.indent_size = vim.bo.expandtab and fn.shiftwidth() or vim.bo.tabstop
    end,

    update = "OptionSet",

    condition = function()
      return vim.bo.buftype == ""
    end,
  }

  local IndentIcon = {
    provider = "󰉶 ",

    hl = { fg = "green" },
  }

  local IndentIndicator = {
    {
      provider = function(self)
        return self.indent_size .. " "
      end,
    },
    {
      provider = function(self)
        return self.use_spaces and "SPC" or "TAB"
      end,

      hl = function(self)
        return {
          fg = self.use_spaces and "green" or "red",
        }
      end,
    },
  }

  IndentBlock =
    utils.insert(IndentBlock, Separator, IndentIcon, IndentIndicator)
  Right = utils.insert(Right, IndentBlock)

  api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = api.nvim_create_augroup("heirline_filesize", { clear = true }),
    callback = function(e)
      vim.b[e.buf].file_size = fn.getfsize(api.nvim_buf_get_name(e.buf))
    end,
  })

  local FileSize = {
    init = function(self)
      if vim.b.file_size == nil then
        vim.b.file_size = fn.getfsize(api.nvim_buf_get_name(0))
      end

      self.fsize = bi_fsize(vim.b.file_size)
    end,

    condition = function()
      return vim.bo.buftype == ""
    end,

    Separator,
    {
      provider = function(self)
        return self.fsize.size
      end,
    },
    {
      provider = function(self)
        return self.fsize.postfix
      end,

      hl = { fg = "faint" },
    },
  }

  local default_fileformat = fn.has("win32") == 1 and "dos" or "unix"
  local line_endings = { unix = "LF", dos = "CRLF", mac = "CR" }

  -- Shown only when it differs from the platform's usual UTF-8 / line ending
  local FileEncoding = {
    condition = function()
      return vim.bo.buftype == ""
    end,

    init = function(self)
      local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding
        or vim.o.encoding
      local labels = {}

      if enc ~= "utf-8" then
        table.insert(labels, enc:upper())
      end

      if vim.bo.bomb then
        table.insert(labels, "BOM")
      end

      if vim.bo.fileformat ~= default_fileformat then
        table.insert(labels, line_endings[vim.bo.fileformat])
      end

      self.label = table.concat(labels, " ")
    end,

    {
      provider = function(self)
        return self.label ~= "" and " " .. self.label or ""
      end,

      hl = { fg = "yellow" },
    },
  }

  Right = utils.insert(Right, FileSize, FileEncoding)

  local Ruler = {
    update = { "CursorMoved", "TextChanged" },

    {
      provider = " ",

      hl = { fg = "faint" },
    },
    {
      provider = "%2c",
    },
    {
      provider = ", ",

      hl = { fg = "faint" },
    },
    {
      provider = "%3L",
    },
    {
      provider = "LOC",

      hl = { fg = "faint" },
    },
    {
      provider = ", ",

      hl = { fg = "faint" },
    },
    {
      provider = "%3p",
    },
    {
      provider = "%%",

      hl = { fg = "faint" },
    },
  }

  Right = utils.insert(Right, Separator, Ruler)

  local ScrollBar = {
    static = {
      segments = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
    },

    update = "CursorMoved",

    provider = function(self)
      local current_lnum = api.nvim_win_get_cursor(0)[1]
      local total_lines = api.nvim_buf_line_count(0)
      local i = math.floor((current_lnum - 1) / total_lines * #self.segments)
        + 1

      return self.segments[i]:rep(2)
    end,

    hl = { fg = "green", bg = "bright_bg" },
  }

  statusline = utils.insert(statusline, Right, Space, ScrollBar)

  heirline.setup({
    statusline = statusline,
  })
end

-- Search count at the match as a rounded pill: accent text on a faint tint of
-- the accent, like noice's popups
---@return table # nvim-hlslens options
function M.hlslens()
  local colors = require("base.colors")

  colors.on_change("hlslens_hl", function()
    local p = colors.palette()
    local base = colors.hl("Normal").bg or p.bar_bg

    local function pill(name, accent, bold)
      local bg = colors.blend(base, accent, 0.2)

      api.nvim_set_hl(0, name, { fg = accent, bg = bg, bold = bold })
      api.nvim_set_hl(0, name .. "Edge", { fg = bg })
    end

    pill("HlSearchLensNear", p.blue, true)
    pill("HlSearchLens", p.muted, false)
  end, { run = true })

  return {
    override_lens = function(render, posList, nearest, idx)
      local lnum, col = unpack(posList[idx])
      local group = nearest and "HlSearchLensNear" or "HlSearchLens"
      local count = nearest and ("%d/%d"):format(idx, #posList) or idx

      render.setVirt(0, lnum - 1, col - 1, {
        { " " },
        { "\u{e0b6}", group .. "Edge" },
        { (" \u{ea6d} %s "):format(count), group },
        { "\u{e0b4}", group .. "Edge" },
      }, nearest)
    end,
  }
end

return M
