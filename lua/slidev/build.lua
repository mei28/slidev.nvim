-- build.lua: Slidevビルド機能

local config = require('slidev.config')
local utils = require('slidev.utils')

local M = {}

-- ビルド機能（本番用SPAを生成）
-- @param opts table|nil オプション
function M.build(opts)
  opts = opts or {}

  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local slidev_cmd = utils.find_slidev_command()
  local dir = vim.fn.fnamemodify(filepath, ':h')

  -- コマンドライン引数の構築
  local args = { 'build', filepath }

  -- 出力ディレクトリ指定
  if opts.out or opts.output then
    table.insert(args, '--out')
    table.insert(args, opts.out or opts.output)
  end

  -- download オプション（PDF機能を有効化）
  if opts.download then
    table.insert(args, '--download')
  end

  -- base オプション（ベースパス）
  if opts.base then
    table.insert(args, '--base')
    table.insert(args, opts.base)
  end

  local cmd = slidev_cmd .. ' ' .. table.concat(args, ' ')

  config.debug_log('ビルドコマンド: ' .. cmd)
  vim.notify('[slidev.nvim] ビルド中...', vim.log.levels.INFO)

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
        local output_dir = opts.out or opts.output or 'dist'
        vim.notify('[slidev.nvim] ビルド完了: ' .. output_dir, vim.log.levels.INFO)
      else
        vim.notify(
          '[slidev.nvim] ビルド失敗: exit_code=' .. exit_code .. '\n' .. table.concat(output_lines, '\n'),
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

return M
