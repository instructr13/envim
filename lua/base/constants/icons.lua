local M = {}

M.kinds = {
  Array = "\u{ea8a}",
  Boolean = "\u{f0a19}",
  Class = "\u{f0bf3}",
  Color = "\u{eb5c}",
  Collapsed = ">",
  Constant = "\u{f0bf1}",
  Control = "\u{ea68}",
  Constructor = "\u{f423}",
  Enum = "\u{f0bf9}",
  EnumMember = "\u{eb5e}",
  Event = "\u{ea86}",
  Field = "\u{eb5f}",
  File = "\u{eb60}",
  Folder = "\u{ea83}",
  Function = "\u{ea8c}",
  Interface = "\u{f0c05}",
  Key = "\u{eb11}",
  Keyword = "\u{eb62}",
  Method = "\u{f0c11}",
  Module = "\u{ea8b}",
  Namespace = "\u{f0c14}",
  Null = "\u{e299}",
  Number = "\u{ea90}",
  Object = "\u{f0c9f}",
  Operator = "\u{eb64}",
  Package = "\u{f0c1a}",
  Property = "\u{f0cbd}",
  Reference = "\u{f0c20}",
  Snippet = "\u{f4fb}",
  String = "\u{eb8d}",
  Struct = "\u{f0c23}",
  Text = "\u{ea93}",
  TypeParameter = "\u{f0c26}",
  Unit = "\u{ea96}",
  Value = "\u{eb8d}",
  Copilot = "\u{f4b8}",
}

M.diagnostics = {
  Error = "\u{ea87}",
  Warn = "\u{ea6c}",
  Info = "\u{ea74}",
  Hint = "\u{ea61}",
  Ok = "\u{ebb1}",
}

-- Statuscolumn sign: a code action is available on the cursor line
M.code_action = "\u{f140b}"

-- Statusline toggle area (see base.editor.toggles): the few toggles worth a
-- permanent spot, one fixed icon each; on/off is shown by color
M.toggles = {
  w = "\u{f05b6}", -- wrap
  d = "\u{f05d6}", -- diagnostics
  f = "\u{f18eb}", -- format on save
  i = "\u{f0674}", -- inline completion
}

return M
