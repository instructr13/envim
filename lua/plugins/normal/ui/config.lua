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

-- Diagnostics summary in a floating window at the top right of each window,
-- level with the winbar (dropbar.nvim)
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

  -- Highlight the file name (the modified flag is in the statusline)
  local path = {
    get_symbols = function(buf, win, cursor)
      local symbols = sources.path.get_symbols(buf, win, cursor)
      local file = symbols[#symbols]

      if file and vim.bo[buf].buftype == "" then
        file.name_hl = "DropBarFileName"
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
  local icons = require("base.constants.icons")
  local toggles = require("base.editor.toggles")

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

  -- Heirline calls the callback as (self, minwid, nclicks, button, mods).
  -- `name` becomes a global function, so it must be unique per component.
  ---@param name string
  ---@param handlers table<"l"|"r"|"m", fun()>
  local function click(name, handlers)
    return {
      name = "sl_" .. name,
      callback = function(_, _, _, button)
        local handler = handlers[button]

        if handler then
          vim.schedule(function()
            handler()

            -- The options and state a handler changes fire no redraw
            vim.cmd.redrawstatus()
          end)
        end
      end,
    }
  end

  local picker = require("base.utils.mouse").picker

  -- Components about the file itself make no sense in terminals, help, oil...
  local function is_file()
    return vim.bo.buftype == ""
  end

  local Left = {}

  table.insert(Left, lib.component.mode())

  local FileType = utils.insert(
    {
      on_click = click("filetype", {
        l = picker(function()
          require("fzf-lua").filetypes()
        end),
      }),
    },
    lib.component.file_info({
      file_icon = false,
      filetype = {
        padding = { right = 1 },
      },
      surround = false,
      file_read_only = false,
    })
  )

  -- The name is in dropbar's winbar; show it here only where dropbar is not
  local FileName = {
    condition = function()
      return vim.wo.winbar == ""
        and vim.bo.buftype == ""
        and api.nvim_buf_get_name(0) ~= ""
    end,

    provider = function()
      return fn.fnamemodify(api.nvim_buf_get_name(0), ":~:.") .. " "
    end,

    hl = { fg = "text" },
  }

  local FileFlags = {
    condition = is_file,

    {
      on_click = click("write", {
        l = function()
          vim.cmd.update()
        end,
      }),

      update = "BufModifiedSet",

      provider = "\u{ebb4}",
      hl = function()
        local fg = vim.bo.modified and "green" or "faint"

        return { fg = fg }
      end,
    },
    {
      condition = function()
        return not vim.bo.modifiable or vim.bo.readonly
      end,

      provider = " \u{ea75}",
      hl = { fg = "orange" },
    },
  }

  local LeftSeparator = {
    condition = function()
      return vim.bo.buftype ~= "terminal"
    end,

    Separator,
  }

  Left = utils.insert(Left, FileType, FileName, FileFlags, LeftSeparator)

  local QuickFixBlock = {
    condition = function()
      return vim.bo.buftype == "quickfix"
    end,

    on_click = click("quickfix", {
      l = function()
        require("quicker").toggle()
      end,
    }),

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

  -- gitsigns updates its status asynchronously, without a redraw
  api.nvim_create_autocmd("User", {
    group = api.nvim_create_augroup("heirline_gitsigns", { clear = true }),
    pattern = { "GitSignsUpdate", "GitSignsChanged" },
    callback = vim.schedule_wrap(function()
      vim.cmd.redrawstatus()
    end),
  })

  local GitBranch = {
    on_click = click("git_branch", {
      l = picker(function()
        require("fzf-lua").git_branches()
      end),
      r = function()
        vim.cmd.Neogit()
      end,
    }),

    {
      provider = "\u{f418} ",

      hl = { fg = "orange" },
    },
    {
      provider = function()
        local status = vim.b.gitsigns_status_dict

        return status and status.head or vim.b.gitsigns_head or ""
      end,

      hl = { fg = "text" },
    },
  }

  -- Added / changed / removed lines, each shown only when non-zero
  local function diff_part(key, sign, color)
    return {
      condition = function()
        local status = vim.b.gitsigns_status_dict

        return status ~= nil and (status[key] or 0) > 0
      end,

      provider = function()
        return " " .. sign .. " " .. vim.b.gitsigns_status_dict[key]
      end,

      hl = { fg = color },
    }
  end

  local GitDiff = {
    condition = is_file,

    on_click = click("git_diff", {
      l = function()
        require("gitsigns").setqflist("all")
      end,
    }),

    diff_part("added", "\u{eadc}", "green"),
    diff_part("changed", "\u{eade}", "yellow"),
    diff_part("removed", "\u{eadf}", "red"),
  }

  local Git = {
    condition = conditions.is_git_repo,

    Space,
    GitBranch,
    GitDiff,
    Space,
    Separator,
  }

  Left = utils.insert(Left, Git)

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

  HelpBlock = utils.insert(HelpBlock, HelpIcon, HelpFileName, Space)
  Left = utils.insert(Left, HelpBlock)
  local Center = {}

  local WorkDirIcon = {
    provider = "\u{ea83} ",

    hl = { fg = "blue" },
  }

  local WorkDir = {
    init = function(self)
      self.indicator = (fn.haslocaldir(0) == 1 and "(L) " or "")
      self.cwd = fn.fnamemodify(fn.getcwd(0), ":~")
    end,

    on_click = click("cwd", {
      l = function()
        require("oil").open(fn.getcwd(0))
      end,
    }),

    hl = { fg = "subtle", bold = false },

    -- Shrinks first: full path, shortened path, hidden
    flexible = 1,

    {
      WorkDirIcon,
      {
        -- evaluates to the full-length path
        provider = function(self)
          local trail = self.cwd:sub(-1) == "/" and "" or "/"

          return self.indicator .. self.cwd .. trail .. "  "
        end,
      },
    },
    {
      WorkDirIcon,
      {
        -- evaluates to the shortened path
        provider = function(self)
          local cwd = fn.pathshorten(self.cwd)
          local trail = self.cwd:sub(-1) == "/" and "" or "/"

          return self.indicator .. cwd .. trail .. "  "
        end,
      },
    },
    {
      -- evaluates to "", hiding the component
      provider = "",
    },
  }

  Center = utils.insert(Center, WorkDir)

  Center = utils.insert(Center, lib.component.virtual_env())

  local Ssh = {
    condition = function()
      return vim.env.SSH_CONNECTION ~= nil
    end,

    init = function(self)
      self.host = self.host or vim.uv.os_gethostname()
    end,

    {
      provider = " \u{f048b} ",

      hl = { fg = "purple" },
    },
    {
      provider = function(self)
        return self.host .. " "
      end,
    },
  }

  Center = utils.insert(Center, Ssh)

  local Right = {}

  -- Transient state starts the Right group: it grows into the Align gap and
  -- moves nothing else
  api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = api.nvim_create_augroup("heirline_recording", { clear = true }),
    callback = vim.schedule_wrap(function()
      vim.cmd.redrawstatus()
    end),
  })

  local Recording = {
    condition = function()
      return fn.reg_recording() ~= ""
    end,

    on_click = click("recording", {
      l = function()
        -- Through nvim-recorder's `q` mapping
        api.nvim_feedkeys("q", "m", false)
      end,
    }),

    provider = function()
      return "● @" .. fn.reg_recording() .. " "
    end,

    hl = { fg = "red" },
  }

  -- Size of the Visual selection: lines, or characters within one line
  local function visual_size()
    local mode = fn.mode()
    local lines = math.abs(fn.line("v") - fn.line(".")) + 1

    if mode == "\22" then
      return lines .. "x" .. math.abs(fn.virtcol("v") - fn.virtcol(".")) + 1
    elseif mode == "V" or lines > 1 then
      return tostring(lines)
    end

    return tostring(fn.wordcount().visual_chars or 1)
  end

  -- Redraws of the statusline from other plugins (dropbar's :redrawstatus!)
  -- clear 'showcmd' until the next command, so the Visual selection size is
  -- computed here instead of taken from it
  api.nvim_create_autocmd("CursorMoved", {
    group = api.nvim_create_augroup("heirline_visual", { clear = true }),
    callback = function()
      if vim.list_contains({ "v", "V", "\22" }, fn.mode()) then
        vim.cmd.redrawstatus()
      end
    end,
  })

  -- Pending keys ('showcmdloc') and the Visual selection size
  local ShowCmd = {
    provider = function()
      if vim.list_contains({ "v", "V", "\22" }, fn.mode()) then
        return visual_size() .. " "
      end

      return "%0.10(%S%)"
    end,

    hl = { fg = "yellow" },
  }

  Right = utils.insert(Right, Recording, ShowCmd)

  -- Names of the LSP clients attached to the buffer
  api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = api.nvim_create_augroup("heirline_lsp", { clear = true }),
    callback = function(e)
      -- LspDetach fires before the client is removed from the buffer
      vim.schedule(function()
        if not api.nvim_buf_is_valid(e.buf) then
          return
        end

        local names = vim.tbl_map(function(client)
          return client.name
        end, vim.lsp.get_clients({ bufnr = e.buf }))

        vim.b[e.buf].lsp_names = table.concat(names, " ")
        vim.b[e.buf].lsp_count = #names

        vim.cmd.redrawstatus()
      end)
    end,
  })

  local LspIcon = {
    provider = "\u{f140c} ",

    hl = { fg = "green" },
  }

  local Lsp = {
    condition = function()
      return is_file() and (vim.b.lsp_count or 0) > 0
    end,

    on_click = click("lsp", {
      l = function()
        vim.cmd("checkhealth vim.lsp")
      end,
      r = function()
        vim.cmd.lsp("restart")
      end,
      m = function()
        vim.cmd.ConformInfo()
      end,
    }),

    -- Shrinks after the working directory: names, count, hidden
    flexible = 2,

    {
      Separator,
      LspIcon,
      {
        provider = function()
          return vim.b.lsp_names
        end,
      },
    },
    {
      Separator,
      LspIcon,
      {
        provider = function()
          return tostring(vim.b.lsp_count)
        end,
      },
    },
    {
      provider = "",
    },
  }

  Right = utils.insert(Right, Lsp)

  -- The <leader>t toggles that have an icon: lit when on, dim when off
  local toggle_keys = vim.tbl_filter(
    function(key)
      return icons.toggles[key] ~= nil
    end,
    vim.tbl_map(function(t)
      return t.key
    end, toggles.list())
  )

  local ToggleIcons = { { provider = " │", hl = { fg = "border" } } }

  for _, key in ipairs(toggle_keys) do
    table.insert(ToggleIcons, {
      on_click = click("toggle_" .. key, {
        l = function()
          toggles.toggle(key)
        end,
        -- Leaves <leader>t pending, so which-key lists all the toggles
        r = function()
          api.nvim_feedkeys(vim.keycode("<leader>t"), "m", false)
        end,
      }),

      provider = "  " .. icons.toggles[key],

      hl = function()
        return { fg = toggles.get(key) and "green" or "faint" }
      end,
    })
  end

  table.insert(ToggleIcons, Space)

  local ToggleArea = {
    condition = is_file,

    -- Shrinks last: shown or hidden as a whole
    flexible = 3,

    ToggleIcons,
    {
      provider = "",
    },
  }

  Right = utils.insert(Right, ToggleArea)

  local IndentBlock = {
    init = function(self)
      self.use_spaces = vim.bo.expandtab
      self.indent_size = vim.bo.expandtab and fn.shiftwidth() or vim.bo.tabstop
    end,

    update = "OptionSet",

    condition = is_file,

    on_click = click("indent", {
      -- Next size: 2, 4, 8
      l = function()
        local sizes = { 2, 4, 8 }
        local current = vim.bo.expandtab and fn.shiftwidth() or vim.bo.tabstop
        local size = sizes[1]

        for i, s in ipairs(sizes) do
          if s == current then
            size = sizes[i % #sizes + 1]
          end
        end

        if vim.bo.expandtab then
          vim.bo.shiftwidth = size
        else
          vim.bo.tabstop = size
        end
      end,
      r = function()
        vim.bo.expandtab = not vim.bo.expandtab
      end,
    }),
  }

  local IndentIcon = {
    provider = "\u{f0276} ",

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

  -- Character count for prose; Japanese has no word boundaries to count
  local prose = { "markdown", "text", "gitcommit", "typst", "tex", "org" }

  local CharCount = {
    condition = function()
      return vim.list_contains(prose, vim.bo.filetype)
    end,

    update = { "TextChanged", "TextChangedI", "BufEnter" },

    Separator,
    {
      provider = function()
        return fn.wordcount().chars
      end,
    },
    {
      provider = "chars",

      hl = { fg = "faint" },
    },
  }

  Right = utils.insert(Right, CharCount)

  api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = api.nvim_create_augroup("heirline_filesize", { clear = true }),
    callback = function(e)
      vim.b[e.buf].file_size = fn.getfsize(api.nvim_buf_get_name(e.buf))
    end,
  })

  -- Treesitter is not attached above this size (see CLAUDE.md)
  local large_file = 100 * 1024

  local FileSize = {
    init = function(self)
      if vim.b.file_size == nil then
        vim.b.file_size = fn.getfsize(api.nvim_buf_get_name(0))
      end

      self.large = vim.b.file_size > large_file
      self.fsize = bi_fsize(vim.b.file_size)
    end,

    condition = is_file,

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

      hl = function(self)
        return { fg = self.large and "yellow" or "faint" }
      end,
    },
  }

  local default_fileformat = fn.has("win32") == 1 and "dos" or "unix"
  local line_endings = { unix = "LF", dos = "CRLF", mac = "CR" }

  -- Shown only when it differs from the platform's usual UTF-8 / line ending
  local FileEncoding = {
    condition = is_file,

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
      on_click = click("fileformat", {
        l = picker(function()
          vim.ui.select(
            { "unix", "dos", "mac" },
            { prompt = "File format" },
            function(choice)
              if choice then
                vim.bo.fileformat = choice
              end
            end
          )
        end),
      }),

      provider = function(self)
        return self.label ~= "" and " " .. self.label or ""
      end,

      hl = { fg = "yellow" },
    },
  }

  Right = utils.insert(Right, FileSize, FileEncoding)

  -- %v is the screen column: %c counts bytes, which is off for CJK text
  local Ruler = {
    update = { "CursorMoved", "TextChanged" },

    {
      provider = "\u{ea9c} ",

      hl = { fg = "faint" },
    },
    {
      provider = "%2v",
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

  local RulerBlock = {
    condition = function()
      return is_file() or vim.bo.buftype == "help"
    end,

    Separator,
    Ruler,
  }

  Right = utils.insert(Right, RulerBlock)

  statusline = utils.insert(statusline, Left, Center, Align, Right, Space)

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
