local M = {}

local namespace = vim.api.nvim_create_namespace('mdx-callouts')

local callouts = {
  note = { group = 'MdxCalloutNote', link = 'DiagnosticInfo' },
  tip = { group = 'MdxCalloutTip', link = 'DiagnosticOk' },
  caution = { group = 'MdxCalloutCaution', link = 'DiagnosticWarn' },
  danger = { group = 'MdxCalloutDanger', link = 'DiagnosticError' },
}

local function find_open_callout(bufnr, row)
  local depth = 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)

  for index = #lines, 1, -1 do
    local line = lines[index]
    if line:match('^%s*:::%s*$') then
      depth = depth + 1
    else
      local kind = line:match('^%s*:::([%a][%w_-]*)')
      local callout = callouts[kind]
      if callout then
        depth = depth - 1
        if depth == 0 then
          return callout
        end
      end
    end
  end
end

local function set_callout_highlights()
  for _, callout in pairs(callouts) do
    local highlight = vim.api.nvim_get_hl(0, {
      name = callout.link,
      link = false,
    })
    highlight.nocombine = true
    vim.api.nvim_set_hl(0, callout.group, highlight)
  end

  local delimiter = vim.api.nvim_get_hl(0, {
    name = 'Comment',
    link = false,
  })
  delimiter.nocombine = true
  vim.api.nvim_set_hl(0, 'MdxCalloutDelimiter', delimiter)
end

function M.setup()
  set_callout_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('dotfiles-mdx-callouts', { clear = true }),
    callback = set_callout_highlights,
  })

  vim.api.nvim_set_decoration_provider(namespace, {
    on_win = function(_, _, bufnr)
      local filetype = vim.bo[bufnr].filetype
      return filetype == 'markdown' or filetype == 'mdx'
    end,

    on_line = function(_, _, bufnr, row)
      local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
      local indent, kind = line:match('^(%s*):::([%a][%w_-]*)')
      local callout = callouts[kind]

      if callout then
        vim.api.nvim_buf_set_extmark(bufnr, namespace, row, #indent, {
          end_col = #line,
          ephemeral = true,
          hl_group = callout.group,
          priority = 200,
        })
        return
      end

      indent = line:match('^(%s*):::%s*$')
      if indent then
        local open_callout = find_open_callout(bufnr, row)
        vim.api.nvim_buf_set_extmark(bufnr, namespace, row, #indent, {
          end_col = #indent + 3,
          ephemeral = true,
          hl_group = open_callout and open_callout.group or 'MdxCalloutDelimiter',
          priority = 200,
        })
      end
    end,
  })
end

return M
