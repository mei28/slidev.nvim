-- init.lua: slidev.nvim main module

local config = require('slidev.config')
local server = require('slidev.server')
local utils = require('slidev.utils')

local M = {}

-- Plugin setup
-- @param user_config table|nil User configuration
function M.setup(user_config)
  config.setup(user_config)
end

-- Start Slidev dev server (preview)
-- @param opts table|nil Options
function M.preview(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()

  -- File type check (optional)
  local filetype = vim.bo.filetype
  if filetype ~= 'markdown' and filetype ~= 'md' then
    vim.notify('[slidev.nvim] Please run this command on a Markdown file', vim.log.levels.WARN)
    return
  end

  server.start_server(bufnr, opts)
end

-- Stop Slidev dev server
function M.stop()
  local bufnr = vim.api.nvim_get_current_buf()
  server.stop_server(bufnr)
end

-- Stop all Slidev dev servers
function M.stop_all()
  server.stop_all_servers()
end

-- Check server status
-- @return boolean true if server is running
function M.is_running()
  local bufnr = vim.api.nvim_get_current_buf()
  return server.is_server_running(bufnr)
end

-- Display detailed server status
function M.status()
  server.show_status()
end

-- Export functionality
-- @param format string Export format ('pdf', 'png', 'pptx', 'md')
-- @param opts table|nil Options
function M.export(format, opts)
  local export_module = require('slidev.export')
  export_module.export(format, opts)
end

-- Build functionality
-- @param opts table|nil Options
function M.build(opts)
  local build_module = require('slidev.build')
  build_module.build(opts)
end

-- Format functionality
-- @param opts table|nil Options
function M.format(opts)
  opts = opts or {}

  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local slidev_cmd = utils.find_slidev_command()
  local cmd = slidev_cmd .. ' format ' .. vim.fn.shellescape(filepath)

  config.debug_log('Format command: ' .. cmd)
  -- Show format progress in command line instead of notification
  vim.api.nvim_echo({{'[slidev.nvim] Formatting...', 'Normal'}}, false, {})

  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        vim.notify('[slidev.nvim] Format complete', vim.log.levels.INFO)
        -- Reload file
        vim.cmd('edit!')
      else
        vim.notify('[slidev.nvim] Format failed: exit_code=' .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

return M
