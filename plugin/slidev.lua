-- plugin/slidev.lua: Vim command registration

-- Prevent duplicate plugin loading
if vim.g.loaded_slidev then
  return
end
vim.g.loaded_slidev = true

-- Start Slidev dev server (preview)
vim.api.nvim_create_user_command('SlidevPreview', function(opts)
  require('slidev').preview()
end, {
  desc = 'Start Slidev dev server and preview',
})

-- Alias: SlidevWatch
vim.api.nvim_create_user_command('SlidevWatch', function(opts)
  require('slidev').preview()
end, {
  desc = 'Start Slidev dev server and preview (alias for SlidevPreview)',
})

-- Stop Slidev dev server
vim.api.nvim_create_user_command('SlidevStop', function(opts)
  require('slidev').stop()
end, {
  desc = 'Stop Slidev dev server for current buffer',
})

-- Stop all Slidev dev servers
vim.api.nvim_create_user_command('SlidevStopAll', function(opts)
  require('slidev').stop_all()
end, {
  desc = 'Stop all Slidev dev servers',
})

-- Export functionality
vim.api.nvim_create_user_command('SlidevExport', function(opts)
  local format = opts.args ~= '' and opts.args or 'pdf'
  require('slidev').export(format)
end, {
  nargs = '?',
  complete = function()
    return { 'pdf', 'png', 'pptx', 'md' }
  end,
  desc = 'Export Slidev presentation (default: pdf)',
})

-- Build functionality
vim.api.nvim_create_user_command('SlidevBuild', function(opts)
  require('slidev').build()
end, {
  desc = 'Build Slidev for production',
})

-- Format functionality
vim.api.nvim_create_user_command('SlidevFormat', function(opts)
  require('slidev').format()
end, {
  desc = 'Format Slidev markdown',
})

-- Check server status
vim.api.nvim_create_user_command('SlidevStatus', function(opts)
  require('slidev').status()
end, {
  desc = 'Show detailed Slidev server status',
})
