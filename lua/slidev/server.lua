-- server.lua: Slidev dev server process management

local config = require('slidev.config')
local utils = require('slidev.utils')

local M = {}

-- Mapping: buffer number -> job_id
M.jobs = {}

-- Flag to prevent duplicate ready notifications
M.server_ready_notified = false

-- Start Slidev dev server
-- @param bufnr number Buffer number
-- @param opts table|nil Options (port, open, remote, theme, etc.)
function M.start_server(bufnr, opts)
  opts = opts or {}

  -- Stop if server is already running
  if M.jobs[bufnr] then
    vim.notify('[slidev.nvim] Server already running. Restarting...', vim.log.levels.INFO)
    M.stop_server(bufnr)
  end

  local cfg = config.get()
  local slidev_cmd = utils.find_slidev_command()

  -- Get current file
  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local dir = vim.fn.fnamemodify(filepath, ':h')

  -- Determine port number
  local port = opts.port or cfg.port

  -- Build command-line arguments (as list)
  local cmd_parts = {}

  -- Split slidev command (handle npx slidev@latest case)
  for part in slidev_cmd:gmatch('%S+') do
    table.insert(cmd_parts, part)
  end

  -- Entry file
  table.insert(cmd_parts, filepath)

  -- Port specification
  table.insert(cmd_parts, '--port')
  table.insert(cmd_parts, tostring(port))

  -- Auto-open browser
  if opts.open or cfg.auto_open_browser then
    table.insert(cmd_parts, '--open')
  end

  -- Remote access
  if opts.remote or cfg.remote then
    table.insert(cmd_parts, '--remote')
    if opts.remote and opts.remote ~= true then
      table.insert(cmd_parts, opts.remote)
    elseif cfg.remote and cfg.remote ~= true then
      table.insert(cmd_parts, cfg.remote)
    end
  end

  -- Theme specification
  if opts.theme or cfg.theme then
    table.insert(cmd_parts, '--theme')
    table.insert(cmd_parts, opts.theme or cfg.theme)
  end

  -- For debugging: build command string
  local full_cmd = table.concat(cmd_parts, ' ')

  config.debug_log('Server start command: ' .. full_cmd)

  -- Collect error messages
  local output_lines = {}

  -- Start process (pass as list)
  local job_id = vim.fn.jobstart(cmd_parts, {
    cwd = dir,
    pty = true,
    width = 120,
    height = 30,
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            local clean_line = utils.strip_ansi_codes(line)
            table.insert(output_lines, clean_line)
            config.debug_log('STDOUT: ' .. clean_line)

            -- Detect server startup completion
            if clean_line:match('Local:') or clean_line:match('localhost:' .. port) then
              -- Only notify once when server is ready
              if not M.server_ready_notified then
                vim.notify('[slidev.nvim] Server ready at http://localhost:' .. port, vim.log.levels.INFO)
                M.server_ready_notified = true

                -- Reset flag after a short delay for next server start
                vim.defer_fn(function()
                  M.server_ready_notified = false
                end, 1000)
              end

              -- Open browser (if --open option is not set)
              if not (opts.open or cfg.auto_open_browser) then
                vim.schedule(function()
                  utils.open_browser('http://localhost:' .. port)
                end)
              end
            end
          end
        end
      end
    end,

    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            local clean_line = utils.strip_ansi_codes(line)
            table.insert(output_lines, clean_line)
            config.debug_log('STDERR: ' .. clean_line)

            -- Notify on error messages
            if clean_line:match('[Ee]rror') or clean_line:match('[Ee]xception') then
              vim.notify('[slidev.nvim] Error: ' .. clean_line, vim.log.levels.ERROR)
            end
          end
        end
      end
    end,

    on_exit = function(_, exit_code, _)
      config.debug_log('Process exited: exit_code=' .. exit_code)
      M.jobs[bufnr] = nil

      if exit_code ~= 0 and exit_code ~= 143 then  -- 143 = SIGTERM
        -- Display error output
        local error_msg = '[slidev.nvim] Server exited abnormally: exit_code=' .. exit_code
        if #output_lines > 0 then
          error_msg = error_msg .. '\n\nCommand: ' .. full_cmd .. '\nOutput:\n' .. table.concat(output_lines, '\n')
        end
        vim.notify(error_msg, vim.log.levels.ERROR)
      end
      -- Don't notify on normal exit (user explicitly stopped or closed buffer)
    end,
  })

  if job_id <= 0 then
    vim.notify('[slidev.nvim] Failed to start server', vim.log.levels.ERROR)
    return
  end

  M.jobs[bufnr] = job_id
  config.debug_log('Registered job_id=' .. job_id .. ' for buffer ' .. bufnr)

  -- Auto-stop on buffer close (multiple events for reliability)
  local augroup = vim.api.nvim_create_augroup('SlidevServer_' .. bufnr, { clear = true })

  -- Also stop on VimLeave
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout', 'BufUnload', 'VimLeavePre' }, {
    group = augroup,
    buffer = bufnr,
    callback = function(ev)
      config.debug_log('Buffer event: ' .. ev.event .. ' (bufnr=' .. bufnr .. ')')
      if M.jobs[bufnr] then
        config.debug_log('Stopping server on buffer close: bufnr=' .. bufnr)
        vim.fn.jobstop(M.jobs[bufnr])
        M.jobs[bufnr] = nil
        -- Don't notify when stopped from autocmd (debug log only)
        config.debug_log('Server auto-stopped: bufnr=' .. bufnr)
      end
    end,
  })
end

-- Stop Slidev dev server
-- @param bufnr number Buffer number
function M.stop_server(bufnr)
  local job_id = M.jobs[bufnr]

  if not job_id then
    config.debug_log('No server to stop: bufnr=' .. bufnr)
    vim.notify('[slidev.nvim] No running server found (bufnr=' .. bufnr .. ')', vim.log.levels.WARN)

    -- Debug: display all current jobs
    if config.get().debug then
      local jobs_info = {}
      for buf, jid in pairs(M.jobs) do
        table.insert(jobs_info, 'buf=' .. buf .. ' -> job=' .. jid)
      end
      if #jobs_info > 0 then
        config.debug_log('Currently registered jobs: ' .. table.concat(jobs_info, ', '))
      else
        config.debug_log('No jobs currently registered')
      end
    end
    return
  end

  config.debug_log('Stopping server: bufnr=' .. bufnr .. ', job_id=' .. job_id)
  vim.fn.jobstop(job_id)
  M.jobs[bufnr] = nil

  -- Only notify in debug mode or when explicitly stopping
  if config.get().debug then
    vim.notify('[slidev.nvim] Server stopped (bufnr=' .. bufnr .. ', job_id=' .. job_id .. ')', vim.log.levels.INFO)
  end
end

-- Stop all Slidev dev servers
function M.stop_all_servers()
  local count = 0
  for bufnr, job_id in pairs(M.jobs) do
    config.debug_log('Stopping server: bufnr=' .. bufnr .. ', job_id=' .. job_id)
    vim.fn.jobstop(job_id)
    count = count + 1
  end

  M.jobs = {}

  if count > 0 then
    vim.notify('[slidev.nvim] Stopped ' .. count .. ' server(s)', vim.log.levels.INFO)
  else
    vim.notify('[slidev.nvim] No running servers', vim.log.levels.INFO)
  end
end

-- Check if server is running for current buffer
-- @param bufnr number|nil Buffer number (nil for current buffer)
-- @return boolean true if server is running
function M.is_server_running(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return M.jobs[bufnr] ~= nil
end

-- Get server status information
-- @return table Status information
function M.get_status()
  local current_bufnr = vim.api.nvim_get_current_buf()
  local status = {
    current_buffer = current_bufnr,
    current_has_server = M.jobs[current_bufnr] ~= nil,
    current_job_id = M.jobs[current_bufnr],
    total_servers = 0,
    servers = {},
  }

  for bufnr, job_id in pairs(M.jobs) do
    status.total_servers = status.total_servers + 1
    local buf_name = vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) or '<invalid buffer>'
    table.insert(status.servers, {
      bufnr = bufnr,
      job_id = job_id,
      name = buf_name,
    })
  end

  return status
end

-- Display server status
function M.show_status()
  local status = M.get_status()

  local msg = '[slidev.nvim] Server Status\n\n'

  if status.current_has_server then
    msg = msg .. '✓ Server running for current buffer (bufnr=' .. status.current_buffer .. ')\n'
    msg = msg .. '  job_id: ' .. status.current_job_id .. '\n'
  else
    msg = msg .. '✗ No server running for current buffer (bufnr=' .. status.current_buffer .. ')\n'
  end

  msg = msg .. '\nTotal running servers: ' .. status.total_servers

  if status.total_servers > 0 then
    msg = msg .. '\n\nDetails:'
    for _, server in ipairs(status.servers) do
      msg = msg .. '\n  • bufnr=' .. server.bufnr .. ', job_id=' .. server.job_id
      msg = msg .. '\n    ' .. vim.fn.fnamemodify(server.name, ':~')
    end
  end

  vim.notify(msg, vim.log.levels.INFO)
end

return M
