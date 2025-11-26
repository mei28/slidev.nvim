-- build.lua: Slidev build functionality

local config = require('slidev.config')
local utils = require('slidev.utils')

local M = {}

-- Build functionality (generate production SPA)
-- @param opts table|nil Options
function M.build(opts)
  opts = opts or {}

  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local slidev_cmd = utils.find_slidev_command()
  local dir = vim.fn.fnamemodify(filepath, ':h')

  -- Default output directory
  local output_dir = opts.out or opts.output or 'dist'

  -- Convert to absolute path (if relative)
  if not output_dir:match('^/') then
    output_dir = dir .. '/' .. output_dir
  end

  -- Build command-line arguments
  local args = { 'build', filepath }

  -- Output directory specification
  table.insert(args, '--out')
  table.insert(args, output_dir)

  -- download option (enable PDF functionality)
  if opts.download then
    table.insert(args, '--download')
  end

  -- base option (base path)
  if opts.base then
    table.insert(args, '--base')
    table.insert(args, opts.base)
  end

  local cmd = slidev_cmd .. ' ' .. table.concat(args, ' ')

  config.debug_log('Build command: ' .. cmd)
  vim.notify('[slidev.nvim] Building...', vim.log.levels.INFO)

  -- Start process
  local output_lines = {}
  vim.fn.jobstart(cmd, {
    cwd = dir,
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            local clean_line = utils.strip_ansi_codes(line)
            table.insert(output_lines, clean_line)
            config.debug_log('STDOUT: ' .. clean_line)
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
          end
        end
      end
    end,

    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        -- Check directory existence
        if vim.fn.isdirectory(output_dir) == 1 then
          -- Check for index.html
          local index_file = output_dir .. '/index.html'
          local file_exists = vim.fn.filereadable(index_file) == 1

          vim.notify(
            '[slidev.nvim] Build complete\n\n' ..
            'Output: ' .. output_dir .. '\n' ..
            (file_exists and '✓ index.html generated' or ''),
            vim.log.levels.INFO
          )
        else
          vim.notify('[slidev.nvim] Build completed but output directory not found: ' .. output_dir, vim.log.levels.WARN)
        end
      else
        vim.notify(
          '[slidev.nvim] Build failed: exit_code=' .. exit_code .. '\n\n' .. table.concat(output_lines, '\n'),
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

return M
