-- config.lua: Configuration management module

local M = {}

-- Default configuration
M.defaults = {
  -- Path to Slidev CLI command (nil for auto-detect)
  slidev_command = nil,

  -- Default port for dev server
  port = 3030,

  -- Enable automatic browser opening
  auto_open_browser = true,

  -- Browser to use (nil for system default)
  browser = nil,

  -- Enable debug logging
  debug = false,

  -- Remote access configuration
  remote = nil,  -- nil or password string

  -- Theme specification
  theme = nil,
}

-- Current configuration (can be overridden by user config)
M.options = vim.deepcopy(M.defaults)

-- Setup configuration
-- @param user_config table|nil User-provided configuration
function M.setup(user_config)
  M.options = vim.tbl_deep_extend('force', M.defaults, user_config or {})

  if M.options.debug then
    vim.notify('[slidev.nvim] Configuration loaded: ' .. vim.inspect(M.options), vim.log.levels.DEBUG)
  end
end

-- Get current configuration
-- @return table Current configuration
function M.get()
  return M.options
end

-- Output debug log
-- @param message string Log message
function M.debug_log(message)
  if M.options.debug then
    vim.notify('[slidev.nvim] ' .. message, vim.log.levels.DEBUG)
  end
end

return M
