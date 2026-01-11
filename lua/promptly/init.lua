local M = {}

local defaults = {
  direction = "right", -- right, left, up, down
  submit = false, -- auto-press Enter after sending
  return_focus = false, -- return focus to nvim after sending (default: stay on target pane)
  keys = false, -- set to true to enable default keymaps
  prompts = {
    ["Explain"] = "Explain the following code:\n\n{selection}",
    ["Refactor"] = "Refactor the following code to be more readable and idiomatic:\n\n{selection}",
    ["Fix Bug"] = "Find and fix any bugs in the following code:\n\n{selection}",
    ["Optimize"] = "Optimize the following code for performance:\n\n{selection}",
    ["Add Types"] = "Add type annotations to the following code:\n\n{selection}",
    ["Review"] = "Review the following code and suggest improvements:\n\n{selection}",
    ["Document"] = "Add documentation comments to the following code:\n\n{selection}",
    ["Tests"] = "Write unit tests for the following code:\n\n{selection}",
    ["Summarize File"] = "Summarize the purpose and logic of this file:\n\n{file}",
  },
}

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  if M.config.keys then
    local map = vim.keymap.set
    map("v", "<leader>ps", function() M.selection() end, { desc = "Send selection to Zellij pane" })
    map("v", "<leader>pp", function() M.prompt() end, { desc = "Pick prompt and send to Zellij pane" })
    map("v", "<leader>pf", function() M.context() end, { desc = "Send file + selection to Zellij pane" })
    map("n", "<leader>pf", function() M.position() end, { desc = "Send file position to Zellij pane" })
    map("n", "<leader>pF", function() M.file() end, { desc = "Send file path to Zellij pane" })
    map("n", "<leader>pd", function() M.diagnostics() end, { desc = "Send diagnostics to Zellij pane" })
    map("n", "<leader>pt", function() M.this() end, { desc = "Send smart context to Zellij pane" })
    map("n", "<leader>py", function() M.line() end, { desc = "Send current line to Zellij pane" })
  end
end

--- Send raw text to adjacent Zellij pane
---@param text string
---@param opts? { direction?: string, submit?: boolean, return_focus?: boolean }
function M.send_raw(text, opts)
  opts = vim.tbl_extend("force", M.config, opts or {})

  if not vim.env.ZELLIJ then
    vim.notify("promptly.nvim: Not running inside Zellij", vim.log.levels.ERROR)
    return false
  end

  if not text or text == "" then
    vim.notify("promptly.nvim: Nothing to send", vim.log.levels.WARN)
    return false
  end

  local direction = opts.direction or "right"

  -- Focus the target pane
  vim.fn.system({ "zellij", "action", "move-focus", direction })

  -- Write the text
  vim.fn.system({ "zellij", "action", "write-chars", text })

  -- Submit if requested
  if opts.submit then
    vim.fn.system({ "zellij", "action", "write", "13" }) -- Enter key
  end

  -- Return focus to original pane
  if opts.return_focus then
    local opposite = { right = "left", left = "right", up = "down", down = "up" }
    vim.fn.system({ "zellij", "action", "move-focus", opposite[direction] })
  end

  return true
end

-- Helper: get visual selection text
local function get_visual_selection()
  local mode = vim.fn.mode()
  -- If currently in visual mode, use current positions
  if mode == "v" or mode == "V" or mode == "\22" then
    local s_start = vim.fn.getpos("v")
    local s_end = vim.fn.getpos(".")
    local lines = vim.fn.getregion(s_start, s_end, { type = mode })
    vim.cmd("silent! normal! \27") -- Exit visual mode (escape)
    return table.concat(lines, "\n")
  end

  -- Not in visual mode - use last visual selection marks
  local last_mode = vim.fn.visualmode()
  if last_mode == "" then
    return nil
  end

  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local ok, lines = pcall(vim.fn.getregion, s_start, s_end, { type = last_mode })
  if not ok or #lines == 0 then
    return nil
  end
  return table.concat(lines, "\n")
end

-- Helper: get current file (relative path)
local function get_file(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    return "[No Name]"
  end
  local rel = vim.fn.fnamemodify(name, ":.")
  return rel ~= "" and rel or name
end

-- Helper: get current line content
local function get_line()
  return vim.api.nvim_get_current_line()
end

-- Helper: get position string
local function get_position()
  local file = get_file()
  local pos = vim.fn.getpos('.')
  local line = pos[2] > 0 and pos[2] or 1
  local col = pos[3] > 0 and pos[3] or 1
  return string.format("@%s L:%d C:%d", file, line, col)
end

-- Helper: get buffer diagnostics
local function get_diagnostics(all)
  local buf = vim.api.nvim_get_current_buf()
  local diags = vim.diagnostic.get(all and nil or buf)
  if #diags == 0 then
    return nil
  end

  -- Sort by file, line, col
  table.sort(diags, function(a, b)
    if a.bufnr ~= b.bufnr then
      return (a.bufnr or 0) < (b.bufnr or 0)
    end
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    return a.col < b.col
  end)

  local severity_names = { "ERROR", "WARN", "INFO", "HINT" }
  local lines = {}
  for _, d in ipairs(diags) do
    local file = get_file(d.bufnr)
    local sev = severity_names[d.severity] or "?"
    table.insert(lines, string.format("[%s] %s:%d:%d %s", sev, file, d.lnum + 1, d.col + 1, d.message))
  end
  return table.concat(lines, "\n")
end

-- Helper: get quickfix list
local function get_quickfix()
  local qf = vim.fn.getqflist()
  if #qf == 0 then
    return nil
  end
  local lines = {}
  for _, item in ipairs(qf) do
    local file = item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ""
    file = vim.fn.fnamemodify(file, ":.")
    local line = string.format("%s:%d:%d %s", file, item.lnum, item.col, item.text)
    table.insert(lines, line)
  end
  return table.concat(lines, "\n")
end

-- Helper: get open buffers
local function get_buffers()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= "" then
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
      table.insert(bufs, "- " .. name)
    end
  end
  return #bufs > 0 and table.concat(bufs, "\n") or nil
end

-- Helper: get treesitter node text by type
-- Helper: try nvim-treesitter-textobjects first, fallback to simple tree walking
local function get_ts_node(textobject_type)
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  -- Try nvim-treesitter-textobjects if available (more accurate)
  local ok, shared = pcall(require, "nvim-treesitter-textobjects.shared")
  if ok then
    local query = ("@%s.outer"):format(textobject_type)
    local range_ok, range = pcall(shared.textobject_at_point, query, "textobjects", buf, { row, col })
    if range_ok and range then
      local start_row, start_col, _, end_row, end_col = unpack(range)
      local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)
      if #lines > 0 then
        lines[#lines] = lines[#lines]:sub(1, end_col)
        local file = get_file()
        local header = string.format("@%s L:%d C:%d\n", file, start_row + 1, start_col + 1)
        return header .. table.concat(lines, "\n")
      end
    end
  end

  -- Fallback: simple tree walking
  local node_ok, node = pcall(vim.treesitter.get_node)
  if not node_ok or not node then
    return nil
  end

  local patterns = {
    ["function"] = { "function", "method", "function_definition", "method_definition" },
    ["class"] = { "class", "struct", "impl", "class_definition", "struct_definition" },
  }
  local types = patterns[textobject_type] or { textobject_type }

  while node do
    local node_type = node:type()
    for _, t in ipairs(types) do
      if node_type:match(t) then
        local start_row, start_col, end_row, end_col = node:range()
        local lines = vim.api.nvim_buf_get_lines(buf, start_row, end_row + 1, false)
        if #lines > 0 then
          lines[#lines] = lines[#lines]:sub(1, end_col)
          local file = get_file()
          local header = string.format("@%s L:%d C:%d\n", file, start_row + 1, start_col + 1)
          return header .. table.concat(lines, "\n")
        end
      end
    end
    node = node:parent()
  end
  return nil
end

-- Helper: render template string
-- @param template string
-- @param context? table Pre-captured values (e.g., { selection = "..." })
local function render_template(template, context)
  context = context or {}
  local replacements = {
    ["{selection}"] = function() return context.selection or get_visual_selection() end,
    ["{file}"] = get_file,
    ["{line}"] = get_line,
    ["{position}"] = get_position,
    ["{diagnostics}"] = function() return get_diagnostics(false) end,
    ["{diagnostics_all}"] = function() return get_diagnostics(true) end,
    ["{quickfix}"] = get_quickfix,
    ["{buffers}"] = get_buffers,
    ["{function}"] = function() return get_ts_node("function") end,
    ["{class}"] = function() return get_ts_node("class") end,
    ["{this}"] = function()
      local sel = context.selection or get_visual_selection()
      return sel or get_position()
    end,
  }

  local result = template
  for pattern, fn in pairs(replacements) do
    if result:find(pattern, 1, true) then
      local value = fn()
      if not value then
        return nil -- Template variable couldn't be resolved
      end
      -- Use function replacement to avoid special character issues
      result = result:gsub(vim.pesc(pattern), function() return value end)
    end
  end
  return result
end

--- Send a message with template variables
---@param msg string Template string with {variables}
---@param opts? table
---@param context? table Pre-captured context values
function M.send(msg, opts, context)
  local rendered = render_template(msg, context)
  if not rendered then
    vim.notify("promptly.nvim: Failed to render template (missing context?)", vim.log.levels.WARN)
    return false
  end
  return M.send_raw(rendered, opts)
end

--- Open prompt picker and send selected prompt
---@param opts? table
function M.prompt(opts)
  -- Capture selection before vim.ui.select exits visual mode
  local selection = get_visual_selection()

  local prompts = M.config.prompts or {}

  -- Order by usage frequency (custom prompts go to end)
  local order = {
    ["Explain"] = 1,
    ["Fix Bug"] = 2,
    ["Refactor"] = 3,
    ["Review"] = 4,
    ["Document"] = 5,
    ["Optimize"] = 6,
    ["Summarize File"] = 7,
    ["Tests"] = 8,
    ["Add Types"] = 9,
  }

  local items = {}
  for name, template in pairs(prompts) do
    table.insert(items, { name = name, template = template })
  end
  table.sort(items, function(a, b)
    local oa = order[a.name] or 100
    local ob = order[b.name] or 100
    if oa == ob then
      return a.name < b.name
    end
    return oa < ob
  end)

  vim.ui.select(items, {
    prompt = "Select prompt:",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      local send_opts = vim.tbl_extend("force", { submit = false }, opts or {})
      M.send(choice.template, send_opts, { selection = selection })
    end
  end)
end

--- Send current visual selection
---@param opts? table
function M.selection(opts)
  local text = get_visual_selection()
  return M.send_raw(text, opts)
end

--- Send current file path
---@param opts? table
function M.file(opts)
  local text = get_file()
  return M.send_raw(text, opts)
end

--- Send current line
---@param opts? table
function M.line(opts)
  local text = get_line()
  return M.send_raw(text, opts)
end

--- Send file position context
---@param opts? table
function M.position(opts)
  local text = get_position()
  return M.send_raw(text, opts)
end

--- Send file position + visual selection
---@param opts? table
function M.context(opts)
  -- Build position string inline (simple, proven)
  local file = vim.fn.expand("%:.")
  if file == "" then file = "[No Name]" end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local pos = string.format("@%s L:%d C:%d", file, cursor[1], cursor[2] + 1)

  -- Get selection same way as M.selection()
  local sel = get_visual_selection()
  local text = sel and (pos .. "\n" .. sel) or pos
  return M.send_raw(text, opts)
end

--- Send buffer diagnostics
---@param opts? table
function M.diagnostics(opts)
  local text = get_diagnostics(false)
  return M.send_raw(text, opts)
end

--- Send all workspace diagnostics
---@param opts? table
function M.diagnostics_all(opts)
  local text = get_diagnostics(true)
  return M.send_raw(text, opts)
end

--- Send current function context (requires treesitter)
---@param opts? table
function M.func(opts)
  local text = get_ts_node("function")
  return M.send_raw(text, opts)
end

--- Send current class context (requires treesitter)
---@param opts? table
function M.class(opts)
  local text = get_ts_node("class")
  return M.send_raw(text, opts)
end

--- Send quickfix list
---@param opts? table
function M.quickfix(opts)
  local text = get_quickfix()
  return M.send_raw(text, opts)
end

--- Send smart context (selection in visual, position otherwise)
---@param opts? table
function M.this(opts)
  local text = get_visual_selection() or get_position()
  return M.send_raw(text, opts)
end

--- Send list of open buffers
---@param opts? table
function M.buffers(opts)
  local text = get_buffers()
  return M.send_raw(text, opts)
end

return M
