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

local function get_diagnostic_object(severity)
  local diagnostics = vim.diagnostic.get(0, { severity = severity })
  local count = #diagnostics
  local first_lnum = count > 0 and diagnostics[1].lnum + 1 or 0

  return count, first_lnum
end

local function create_arrow(lnum)
  local row = api.nvim_win_get_cursor(fn.win_getid())[1]

  local arrow = ""

  if row > lnum then
    arrow = ""
  elseif row == lnum then
    arrow = ""
  end

  return arrow
end

function M.incline()
  local devicons = require("nvim-web-devicons")
  local utils = require("heirline.utils")

  local diagnostic_icons = {
    error = " ",
    warn = " ",
    info = " ",
    hint = " ",
    ok = " ",
  }

  local function to_hex(number)
    if number == nil then
      return "#ffffff"
    end

    return ("#%06x"):format(number)
  end

  require("incline").setup({
    render = function(props)
      local palette = require("catppuccin.palettes").get_palette()

      local colors = vim.tbl_extend("error", palette, {
        diag_error = to_hex(utils.get_highlight("DiagnosticError").fg),
        diag_dark_error = to_hex(
          utils.get_highlight("DiagnosticVirtualTextError").bg
        ),
        diag_warn = to_hex(utils.get_highlight("DiagnosticWarn").fg),
        diag_dark_warn = to_hex(
          utils.get_highlight("DiagnosticVirtualTextWarn").bg
        ),
        diag_info = to_hex(utils.get_highlight("DiagnosticInfo").fg),
        diag_dark_info = to_hex(
          utils.get_highlight("DiagnosticVirtualTextInfo").bg
        ),
        diag_hint = to_hex(utils.get_highlight("DiagnosticHint").fg),
        diag_dark_hint = to_hex(
          utils.get_highlight("DiagnosticVirtualTextHint").bg
        ),
      })

      local filename =
        vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
      if filename == "" then
        filename = "[No Name]"
      end
      local ft_icon, ft_color = devicons.get_icon_color(filename)

      local function get_diagnostic_label()
        local errors, error_lnum =
          get_diagnostic_object(vim.diagnostic.severity.ERROR)
        local warnings, warn_lnum =
          get_diagnostic_object(vim.diagnostic.severity.WARN)
        local info, info_lnum =
          get_diagnostic_object(vim.diagnostic.severity.INFO)
        local hints, hint_lnum =
          get_diagnostic_object(vim.diagnostic.severity.HINT)

        local ok = errors + warnings + info + hints == 0

        local label = {}

        table.insert(label, {
          diagnostic_icons.error .. errors,
          guifg = errors > 0 and colors.diag_error or colors.surface1,
        })

        if errors > 0 then
          table.insert(label, {
            create_arrow(error_lnum),
            guifg = colors.diag_dark_error,
          })

          table.insert(label, {
            error_lnum,
            guifg = colors.diag_error,
          })
        end

        table.insert(label, { " " })

        table.insert(label, {
          diagnostic_icons.warn .. warnings,
          guifg = errors > 0 and colors.diag_warn or colors.surface1,
        })

        if warnings > 0 then
          table.insert(label, {
            create_arrow(warn_lnum),
            guifg = colors.diag_dark_warn,
          })

          table.insert(label, {
            warn_lnum,
            guifg = colors.diag_warn,
          })
        end

        table.insert(label, { " " })

        if info > 0 then
          table.insert(label, {
            diagnostic_icons.info .. info,
            guifg = colors.diag_info,
          })

          table.insert(label, {
            create_arrow(info_lnum),
            guifg = colors.diag_dark_info,
          })

          table.insert(label, {
            info_lnum,
            guifg = colors.diag_info,
          })

          table.insert(label, { " " })
        end

        if hints > 0 then
          table.insert(label, {
            diagnostic_icons.error .. hints,
            guifg = colors.diag_hint,
          })

          table.insert(label, {
            create_arrow(hint_lnum),
            guifg = colors.diag_dark_hint,
          })

          table.insert(label, {
            hint_lnum,
            guifg = colors.diag_hint,
          })

          table.insert(label, { " " })
        end

        table.insert(label, {
          diagnostic_icons.ok,
          guifg = (ok and vim.bo.buftype == "") and colors.green
            or colors.surface1,
        })

        table.insert(label, { " │ ", guifg = colors.surface0 })

        return label
      end

      return {
        { get_diagnostic_label() },
        { (ft_icon or "") .. " ", guifg = ft_color, guibg = "none" },
        {
          filename .. " ",
          gui = vim.bo[props.buf].modified and "italic" or "normal",
        },
      }
    end,
  })
end

local function setup_colors()
  local lib = require("heirline-components.all")
  local utils = require("heirline.utils")
  local palette = require("catppuccin.palettes").get_palette()

  local colors = vim.tbl_extend("error", palette, {
    bright_bg = palette.surface0,
    bright_fg = palette.text,
    dark_red = utils.get_highlight("DiffDelete").bg,
    gray = palette.subtext1,
    orange = palette.peach,
    purple = palette.mauve,
    cyan = palette.sapphire,
  })

  colors = vim.tbl_extend("force", colors, lib.hl.get_colors())

  return colors
end

function M.statusline()
  local heirline = require("heirline")
  local lib = require("heirline-components.all")
  local utils = require("heirline.utils")
  local conditions = require("heirline.conditions")

  lib.init.subscribe_to_events()
  heirline.load_colors(setup_colors())

  api.nvim_create_autocmd("ColorScheme", {
    group = api.nvim_create_augroup("Heirline", { clear = true }),
    callback = function()
      utils.on_colorscheme(setup_colors)
    end,
  })

  local statusline = {
    hl = {
      fg = "gray",
      bg = "mantle",
    },
  }

  -- Utilities
  local Align = { provider = "%=" }
  local Space = { provider = " " }
  local Separator = { provider = " │ ", hl = { fg = "surface0" } }

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
        local fg = vim.bo.modified and "green" or "surface1"

        return { fg = fg }
      end,
    },
    {
      update = { "BufReadPost", "BufNewFile" },

      provider = "",
      hl = function()
        local fg = (not vim.bo.modifiable or vim.bo.readonly) and "orange"
          or "surface1"

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

      hl = { fg = "overlay0" },
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

      hl = { fg = "overlay0" },
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

        hl = { fg = "overlay0" },
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

        hl = { fg = "overlay0" },
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

  Center = utils.insert(Center, lib.component.cmd_info())

  local WorkDirIcon = {
    provider = " ",

    hl = { fg = "blue" },
  }

  local WorkDir = {
    init = function(self)
      self.indicator = (fn.haslocaldir(0) == 1 and " (L)" or "") .. " "
      self.cwd = fn.fnamemodify(fn.getcwd(0), ":~")
    end,
    hl = { fg = "gray", bold = false },

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
      self.indent_size = vim.bo.tabstop
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

  local FileSize = {
    init = function(self)
      local size = fn.getfsize(api.nvim_buf_get_name(0))

      self.fsize = bi_fsize(size)
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

      hl = { fg = "surface1" },
    },
  }

  Right = utils.insert(
    Right,
    FileSize,
    lib.component.file_encoding({
      file_format = false,
    })
  )

  local Ruler = {
    update = { "CursorMoved", "TextChanged" },

    {
      provider = " ",

      hl = { fg = "surface1" },
    },
    {
      provider = "%2c",
    },
    {
      provider = ", ",

      hl = { fg = "surface1" },
    },
    {
      provider = "%3L",
    },
    {
      provider = "LOC",

      hl = { fg = "surface1" },
    },
    {
      provider = ", ",

      hl = { fg = "surface1" },
    },
    {
      provider = "%3p",
    },
    {
      provider = "%%",

      hl = { fg = "surface1" },
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

return M
