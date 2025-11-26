-- export.lua: Slidev export functionality

local config = require('slidev.config')
local utils = require('slidev.utils')

local M = {}

-- Export functionality
-- @param format string Export format ('pdf', 'png', 'pptx', 'md')
-- @param opts table|nil Options
function M.export(format, opts)
  opts = opts or {}
  format = format or 'pdf'

  -- Format validation
  local valid_formats = { pdf = true, png = true, pptx = true, md = true }
  if not valid_formats[format] then
    vim.notify('[slidev.nvim] Invalid format: ' .. format .. ' (only pdf, png, pptx, md supported)', vim.log.levels.ERROR)
    return
  end

  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local slidev_cmd = utils.find_slidev_command()
  local dir = vim.fn.fnamemodify(filepath, ':h')

  -- Determine default output filename
  local filename_base = vim.fn.fnamemodify(filepath, ':t:r')  -- filename without extension
  local default_output = filename_base .. '-export.' .. format
  local output_file = opts.output or default_output

  -- Convert to absolute path (if relative)
  if not output_file:match('^/') then
    output_file = dir .. '/' .. output_file
  end

  -- Build command-line arguments
  local args = { 'export', filepath }

  -- Format specification
  table.insert(args, '--format')
  table.insert(args, format)

  -- Output specification
  table.insert(args, '--output')
  table.insert(args, output_file)

  -- with-clicks option (include click animations)
  if opts.with_clicks then
    table.insert(args, '--with-clicks')
  end

  -- dark mode
  if opts.dark then
    table.insert(args, '--dark')
  end

  -- range option (page range specification)
  if opts.range then
    table.insert(args, '--range')
    table.insert(args, opts.range)
  end

  -- timeout option
  if opts.timeout then
    table.insert(args, '--timeout')
    table.insert(args, tostring(opts.timeout))
  end

  local cmd = slidev_cmd .. ' ' .. table.concat(args, ' ')

  config.debug_log('Export command: ' .. cmd)
  vim.notify('[slidev.nvim] Exporting to ' .. format:upper() .. '...', vim.log.levels.INFO)

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
            table.insert(output_lines, line)
            config.debug_log('STDOUT: ' .. line)
          end
        end
      end
    end,

    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(output_lines, line)
            config.debug_log('STDERR: ' .. line)
          end
        end
      end
    end,

    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        -- Check file existence
        if vim.fn.filereadable(output_file) == 1 then
          local filesize = vim.fn.getfsize(output_file)
          local size_kb = math.floor(filesize / 1024)
          vim.notify(
            '[slidev.nvim] Export complete: ' .. format:upper() .. '\n\n' ..
            'Output: ' .. output_file .. '\n' ..
            'Size: ' .. size_kb .. ' KB',
            vim.log.levels.INFO
          )
        else
          vim.notify('[slidev.nvim] Export completed but file not found: ' .. output_file, vim.log.levels.WARN)
        end
      else
        -- Detect Playwright-related errors
        local output_text = table.concat(output_lines, '\n')
        local is_playwright_error = output_text:match('playwright') or output_text:match('Playwright')

        if is_playwright_error then
          vim.notify(
            '[slidev.nvim] Playwright required for export\n\n' ..
            'Installation:\n' ..
            '  Global: npm install -g playwright-chromium\n' ..
            '  Local:  npm install -D playwright-chromium\n\n' ..
            'Or use browser export:\n' ..
            '  1. Start server with :SlidevPreview\n' ..
            '  2. Navigate to http://localhost:3030/export',
            vim.log.levels.WARN
          )
        else
          vim.notify(
            '[slidev.nvim] Export failed: exit_code=' .. exit_code .. '\n\n' .. output_text,
            vim.log.levels.ERROR
          )
        end
      end
    end,
  })
end

return M
