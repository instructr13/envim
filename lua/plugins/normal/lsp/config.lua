local M = {}

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
      lsp_format = "fallback",
      range = range,
    })
  end, { range = true })

  keymap({ "n", "v" }, "<leader>f", function()
    require("conform").format({ async = true }, function(err)
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

  return { timeout_ms = 500, lsp_format = "fallback" }
end

return M
