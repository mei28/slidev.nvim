-- utils.lua: Utility functions

local config = require('slidev.config')

local M = {}

-- Detect Slidev CLI command
-- Priority: config > global > local > npx
-- @return string Path to Slidev CLI command
function M.find_slidev_command()
  -- Use explicitly specified command from config
  local cfg = config.get()
  if cfg.slidev_command then
    config.debug_log('Using Slidev command from config: ' .. cfg.slidev_command)
    return cfg.slidev_command
  end

  -- Search for globally installed slidev (from PATH)
  local global_slidev = vim.fn.exepath('slidev')
  if global_slidev ~= '' then
    config.debug_log('Detected global Slidev: ' .. global_slidev)
    return global_slidev
  end

  -- Search for local node_modules/.bin/slidev
  local local_slidev = vim.fn.findfile('node_modules/.bin/slidev', '.;')
  if local_slidev ~= '' then
    local full_path = vim.fn.fnamemodify(local_slidev, ':p')
    config.debug_log('Detected local Slidev: ' .. full_path)
    return full_path
  end

  -- Fallback: use npx (correct package name @slidev/cli)
  config.debug_log('Using npx @slidev/cli@latest')
  return 'npx @slidev/cli@latest'
end

-- Open URL in browser (cross-platform)
-- @param url string URL to open
function M.open_browser(url)
  local cfg = config.get()

  if not cfg.auto_open_browser then
    config.debug_log('auto_open_browser is disabled, not opening browser')
    return
  end

  local cmd
  local browser = cfg.browser

  -- Use specified browser if configured
  if browser then
    cmd = browser .. ' ' .. vim.fn.shellescape(url)
  else
    -- Use system default browser
    if vim.fn.has('mac') == 1 then
      cmd = 'open ' .. vim.fn.shellescape(url)
    elseif vim.fn.has('unix') == 1 then
      cmd = 'xdg-open ' .. vim.fn.shellescape(url)
    elseif vim.fn.has('win32') == 1 then
      cmd = 'start ' .. vim.fn.shellescape(url)
    else
      vim.notify('[slidev.nvim] Unsupported platform', vim.log.levels.WARN)
      return
    end
  end

  config.debug_log('Launching browser: ' .. cmd)
  vim.fn.system(cmd)
end

-- Get current buffer's file path
-- @return string|nil File path (nil if not available)
function M.get_current_file()
  local filepath = vim.fn.expand('%:p')
  if filepath == '' then
    vim.notify('[slidev.nvim] No file is open', vim.log.levels.ERROR)
    return nil
  end
  return filepath
end

-- Get current buffer's directory path
-- @return string|nil Directory path (nil if not available)
function M.get_current_dir()
  local filepath = M.get_current_file()
  if not filepath then
    return nil
  end
  return vim.fn.fnamemodify(filepath, ':h')
end

-- Remove ANSI escape sequences
-- @param str string Input string
-- @return string String with escape sequences removed
function M.strip_ansi_codes(str)
  -- Match and remove ANSI escape sequence patterns
  return str:gsub('\27%[[0-9;]*m', '')
end

-- Check if port is available
-- @param port number Port number
-- @return boolean true if port is available
function M.is_port_available(port)
  local handle = io.popen('lsof -i:' .. port .. ' 2>/dev/null')
  if not handle then
    return true
  end
  local result = handle:read('*a')
  handle:close()
  return result == ''
end

return M
