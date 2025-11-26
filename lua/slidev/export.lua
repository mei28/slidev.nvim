-- export.lua: Slidevエクスポート機能

local config = require('slidev.config')
local utils = require('slidev.utils')

local M = {}

-- エクスポート機能
-- @param format string エクスポート形式（'pdf', 'png', 'pptx', 'md'）
-- @param opts table|nil オプション
function M.export(format, opts)
  opts = opts or {}
  format = format or 'pdf'

  -- フォーマットのバリデーション
  local valid_formats = { pdf = true, png = true, pptx = true, md = true }
  if not valid_formats[format] then
    vim.notify('[slidev.nvim] 無効なフォーマット: ' .. format .. '（pdf, png, pptx, md のみサポート）', vim.log.levels.ERROR)
    return
  end

  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local slidev_cmd = utils.find_slidev_command()
  local dir = vim.fn.fnamemodify(filepath, ':h')

  -- コマンドライン引数の構築
  local args = { 'export', filepath }

  -- フォーマット指定
  table.insert(args, '--format')
  table.insert(args, format)

  -- with-clicks オプション（クリックアニメーション込み）
  if opts.with_clicks then
    table.insert(args, '--with-clicks')
  end

  -- dark モード
  if opts.dark then
    table.insert(args, '--dark')
  end

  -- range オプション（ページ範囲指定）
  if opts.range then
    table.insert(args, '--range')
    table.insert(args, opts.range)
  end

  -- output オプション（出力先）
  if opts.output then
    table.insert(args, '--output')
    table.insert(args, opts.output)
  end

  -- timeout オプション
  if opts.timeout then
    table.insert(args, '--timeout')
    table.insert(args, tostring(opts.timeout))
  end

  local cmd = slidev_cmd .. ' ' .. table.concat(args, ' ')

  config.debug_log('エクスポートコマンド: ' .. cmd)
  vim.notify('[slidev.nvim] ' .. format:upper() .. ' 形式でエクスポート中...', vim.log.levels.INFO)

  -- プロセス起動
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
        vim.notify('[slidev.nvim] エクスポート完了: ' .. format:upper(), vim.log.levels.INFO)
      else
        vim.notify(
          '[slidev.nvim] エクスポート失敗: exit_code=' .. exit_code .. '\n' .. table.concat(output_lines, '\n'),
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

return M
