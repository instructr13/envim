# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a personal Neovim configuration (Lua, lazy.nvim). There is no build or test suite.

## Philosophy

Apply these when adding or changing anything.

- **An editor, not an IDE.** Do not add heavy IDE features (debuggers, project/session managers, big side panels, task runners). Do actively add anything that improves editing efficiency or UI. Prefer the latest Neovim features and built-ins (`vim.lsp.*`, `vim.pack`, `vim.uv`, `vim.fs`, `vim.keymap`, built-in `gc`/`grr`/`gra` defaults, ...) over plugins or hand-rolled code, and adopt new ones as they land.
- **Just works.** If a tool is usable, it must work with zero configuration. Detect, don't declare: LSP servers are enabled automatically when their executable is on `$PATH` (`base/lsp/auto_enable.lua`), formatters and linters are derived from what is installed (`plugins/normal/lsp/config.lua`), Treesitter parsers are installed on first `FileType`. Do not add per-language/per-server manual enable lists; use `exclusive_groups` / `deny` / `overrides` to tune the detection instead.
- **Frustration-free.** Nothing should get in the user's way or make them stop and fix the editor. Make full use of everything Neovim itself offers (built-in commands, options, text objects, marks, registers, quickfix, `:lsp`, `:checkhealth`, ...) to raise productivity and working efficiency, and design defaults so common operations are smooth, predictable, and recoverable (e.g. no silent failures, sensible fallbacks).
- **Performance first.** Startup time and responsiveness win over features. Lazy-load by default (`event` / `cmd` / `keys` / `ft`), `vim.loader.enable()` is on, and `require()` of plugin modules belongs inside callbacks, not at file top level (see `on_attach` in `base/lsp/init.lua`). Large files (>100 KB) skip Treesitter attach; `faster.nvim` handles the rest. Measure with `:StartupTime`.

## Commands

Dev tools (`lua-language-server`, `stylua`, `selene`) come from the Nix flake (`.envrc` → `use flake`, direnv).

```bash
stylua .                            # format (stylua.toml: 80 cols, 2 spaces, prefer double quotes)
stylua --check .                    # format check only
selene lua after init.lua           # lint (selene.toml + vim.yml → std "vim")
nvim --headless "+qa"               # smoke test: startup must not print errors
nvim --startuptime /tmp/st.log +qa  # startup profile
```

Plugins are pinned in `lazy-lock.json` (commit it when updating). `<leader>pl` opens `:Lazy`.

## Plugin tiers (core / normal / vendor)

Plugins are split by **what environment they can run in**, not by topic. Putting a plugin in the wrong tier is the most common way to break this config.

| Tier | Path | Loaded | Rule |
| --- | --- | --- | --- |
| **core** | `lua/plugins/core/` | always | Must work in a **headless / embedded** Neovim (e.g. `vim.g.vscode`, no TUI attached). Editing features only: text objects, motions, surround, comment handling, buffer ops, the parts of Treesitter that need no UI (parser install/attach, textobjects). |
| **normal** | `lua/plugins/normal/` | only when `not vim.g.vscode` | Needs a real **TUI/GUI** (the full environment). LSP, Treesitter highlighting extras (rainbow-delimiters, hlargs), all UI elements (statusline, bufferline, dropbar, cmdline, which-key, animations), completion, git UI, file explorer, search UI, colorscheme. |
| **vendor** | `lua/vendor/` (git-ignored) | after everything, via `base/vendor.lua` | Machine-local settings (`vendor/init.lua`) and extra plugins (`vendor/plugins.lua`) managed by **`vim.pack`**, not lazy.nvim. Own lockfile `nvim-pack-lock.json`; update with `:VendorUpdate`. Never commit anything under `lua/vendor/` except `.gitkeep`. |

Wiring is in `base/core/bootstrap.lua` (`configure_plugin_manager`): `{ import = "plugins.core" }` always, `{ import = "plugins.normal" }` unless `vim.g.vscode`. lazy.nvim's defaults here are `lazy = false, version = false`, so every spec that should be deferred must say so explicitly.

Decision rule for a new plugin: *"Does it still do something useful with no UI attached?"* Yes → `core`. No (or it draws anything) → `normal`. Needed on one machine only → `vendor`. If a core plugin's feature needs a normal-only piece, split the spec so the core part stays UI-free.

## Architecture

### Startup sequence

`init.lua` → `vim.loader.enable()` → `require("base")` → `base.core.setup()` (order matters, do not reorder):

1. `base.core.options` – options (also Neovide/GUI settings)
2. `base.editor.autocommand`, `base.editor.keymap` – global autocmds and keymaps
3. `base.core.bootstrap` – disable builtin plugins/providers, clone lazy.nvim if missing, `lazy.setup` with the tier imports above
4. `base.colors.set_colorscheme()` – the *only* module that knows the colorscheme name; everything else asks `base.colors.palette()` for semantic colors
5. `base.editor.column` – statuscolumn/column setup
6. `base.lsp.setup()` – diagnostics, built-in LSP features, `LspAttach`, auto-enable
7. `base.editor.cd()` – one-shot `cd` to the git root of the first real file

then `init.lua` calls `base.vendor.setup()`.

### `lua/base/` – plugin-independent foundation

Runs in every environment, so it must not hard-depend on plugins at startup. Plugin calls inside callbacks (`on_attach`, keymap handlers) are fine because they only fire once the feature exists. (Known exception: `set_colorscheme` uses `catppuccin`, which lives in `plugins/normal/ui`.)

- `utils/keymap`: `keymap(mode, lhs, rhs, desc)` and `omit(behavior, mode, prefix, opts)` which returns a keymap function with a shared prefix/options. Use these instead of raw `vim.keymap.set`, and always give a `desc`.
- `lsp/init.lua`: `vim.diagnostic.config`, enabling inlay hints / linked editing / on-type formatting / inline completion, and `LspAttach` keymaps. Every keymap is guarded by `client:supports_method(...)` so nothing is bound that the server cannot do. LSP folding sets `vim.b.lsp_folding`, which tells the Treesitter attach code (`plugins/core/treesitter/config.lua`) not to override foldexpr.
- `lsp/auto_enable.lua` + `tools.lua`: scans `lsp/*.lua` from nvim-lspconfig, resolves each server's executable (from `cmd`, or via Mason's registry when `cmd` is a function), and enables servers found on `$PATH`. Tuning tables: `exclusive_groups` (only the first available server of a group is enabled, e.g. `vtsls`/`ts_ls`/`tsgo`), `deny` (noisy servers), `generic_bins` (executables like `node`/`python` that don't prove a server is installed), `overrides`. Per-server settings go in `after/lsp/<server>.lua`.
- `constants/`: shared icons and buffer constants. `colors/`: palette abstraction.
- `vendor.lua`: see the vendor tier above.

### `lua/plugins/<tier>/<domain>/` – lazy.nvim specs

Each domain (`editor`, `lsp`, `ui`, `treesitter`, `fold`, `git`, `search`, `file`, `buffer`, `lang`) is a directory whose `init.lua` returns the spec list. Non-trivial setup is moved into a sibling `config.lua` that exposes functions (`C.dial_init()`, `C.conform_init()`, ...) which the spec calls from `init` / `config` / `opts`, with a local `local C = require("plugins.<tier>.<domain>.config")`. Keep specs declarative and put logic in `config.lua`. Specs follow the style: plugin string, blank line, `lazy`/`event`/`cmd`/`keys`, then `init`/`opts`/`config`.

Cross-file couplings to be aware of:

- **Treesitter** is split across tiers: `core/treesitter` installs parsers and attaches per buffer (and defines textobject move/swap keymaps); `normal/treesitter` adds visual-only plugins on top. `mini.ai` (core/editor) consumes the textobject queries; `flash.nvim` and `ts-comments` also depend on Treesitter.
- **Folding**: LSP `foldingRange` > Treesitter `folds` query > default; `nvim-origami` (normal/fold) and `foldtext.nvim` (normal/ui) render it.
- **Keymap ownership** is deliberately partitioned (comments in specs record it): `s` → flash, `S` visual → mini.surround, `]c`/`[c` → gitsigns hunks, `an`/`in` → built-in incremental selection (mini.ai uses `aN`/`iN`), `K`/`gr*` → set per buffer in `LspAttach`. Check for collisions before adding a mapping.
- **`<leader>` layout** is split by concern and labelled in which-key's `spec` (`normal/ui/init.lua`): `b` buffer, `c` code (format, swap args), `f` find (fzf), `g` git, `l` LSP, `m` markdown, `p` plugins, `s` search & replace, `t` toggles, `u` undo history, `w` window, `x` lists, `<tab>` tabs. A new `<leader>` mapping goes under its group; a new group needs a `spec` entry.
- **Formatting/linting** (`normal/lsp/config.lua`): conform builds `formatters_by_ft` from installed tools with priority tables, falling back to LSP formatting; linters are likewise derived.

## Conventions

- Style: `.editorconfig` / `stylua.toml` (2 spaces, 80 cols). Comments are sparse and explain *why* (a coupling, a workaround), not what.
- Commits follow Conventional Commits with a scope: `feat(editor): ...`, `chore!: ...`.
- Do not commit `lua/vendor/*` (except `.gitkeep`) or `nvim-pack-lock.json`.
