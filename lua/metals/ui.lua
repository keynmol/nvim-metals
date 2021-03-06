local api = vim.api
local fn = vim.fn

-- {{{ The following is extracted and modified from nvim-lspconfig...
-- which itself is extranted and modifed by plenary.nvim.
--
-- Thanks TJ
--
local function apply_defaults(original, defaults)
  if original == nil then
    original = {}
  end

  original = vim.deepcopy(original)

  for k, v in pairs(defaults) do
    if original[k] == nil then
      original[k] = v
    end
  end

  return original
end

local M = {}

M.default_options = {winblend = 10, percentage = 0.9}

function M.default_opts(options)
  options = apply_defaults(options, M.default_options)

  local width = math.floor(vim.o.columns * options.percentage)
  local height = math.floor(vim.o.lines * options.percentage)

  local top = math.floor(((vim.o.lines - height) / 2) - 1)
  local left = math.floor((vim.o.columns - width) / 2)

  local opts = {
    relative = 'editor',
    row = top,
    col = left,
    width = width,
    height = height,
    style = 'minimal'
  }

  return opts
end

--- Create window that takes up certain percentags of the current screen.
---
--- Works regardless of current buffers, tabs, splits, etc.
-- @param col_range number | Table:
--                  If number, then center the window taking up this percentage of the screen.
--                  If table, first index should be start, second_index should be end
-- @param row_range number | Table:
--                  If number, then center the window taking up this percentage of the screen.
--                  If table, first index should be start, second_index should be end
function M.percentage_range_window(col_range, row_range, options)
  options = apply_defaults(options, M.default_options)

  local win_opts = M.default_opts(options)
  win_opts.relative = 'editor'

  local height_percentage, row_start_percentage
  if type(row_range) == 'number' then
    assert(row_range <= 1)
    assert(row_range > 0)
    height_percentage = row_range
    row_start_percentage = (1 - height_percentage) / 2
  elseif type(row_range) == 'table' then
    height_percentage = row_range[2] - row_range[1]
    row_start_percentage = row_range[1]
  else
    error(string.format('Invalid type for \'row_range\': %p', row_range))
  end

  win_opts.height = math.ceil(vim.o.lines * height_percentage)
  win_opts.row = math.ceil(vim.o.lines * row_start_percentage)

  local width_percentage, col_start_percentage
  if type(col_range) == 'number' then
    assert(col_range <= 1)
    assert(col_range > 0)
    width_percentage = col_range
    col_start_percentage = (1 - width_percentage) / 2
  elseif type(col_range) == 'table' then
    width_percentage = col_range[2] - col_range[1]
    col_start_percentage = col_range[1]
  else
    error(string.format('Invalid type for \'col_range\': %p', col_range))
  end

  win_opts.col = math.floor(vim.o.columns * col_start_percentage)
  win_opts.width = math.floor(vim.o.columns * width_percentage)

  local bufnr = options.bufnr or fn.nvim_create_buf(false, true)
  local win_id = fn.nvim_open_win(bufnr, true, win_opts)
  api.nvim_win_set_buf(win_id, bufnr)

  vim.cmd('setlocal nocursorcolumn')
  fn.nvim_win_set_option(win_id, 'winblend', options.winblend)

  return {bufnr = bufnr, win_id = win_id}
end

-- }}} End stuff taken from lspconfig

M.wrap_hover = function(bufnr, winnr)
  local hover_len = #api.nvim_buf_get_lines(bufnr, 0, -1, false)[1]
  local win_width = api.nvim_win_get_width(0)
  if hover_len > win_width then
    api.nvim_win_set_width(winnr, math.min(hover_len, win_width))
    api.nvim_win_set_height(winnr, math.ceil(hover_len / win_width))
    vim.wo[winnr].wrap = true -- luacheck: ignore 122
  end
end

return M
