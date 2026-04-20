return {
  'cormacrelf/dark-notify',
  lazy = false,
  priority = 900,
  cond = function()
    local uv = vim.uv or vim.loop
    return uv.os_uname().sysname == 'Darwin'
  end,
  config = function()
    if vim.fn.executable('dark-notify') == 0 then
      return
    end

    require('dark_notify').run({
      schemes = {
        dark = 'github_dark',
        light = 'github_light',
      },
    })
  end,
}
