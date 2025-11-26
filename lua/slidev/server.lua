-- server.lua: Slidev開発サーバーのプロセス管理

local config = require('slidev.config')
local utils = require('slidev.utils')

local M = {}

-- バッファ番号 -> job_id のマッピング
M.jobs = {}

-- Slidev開発サーバーを起動
-- @param bufnr number バッファ番号
-- @param opts table|nil オプション（port, open, remote, themeなど）
function M.start_server(bufnr, opts)
  opts = opts or {}

  -- 既にサーバーが起動している場合は停止
  if M.jobs[bufnr] then
    vim.notify('[slidev.nvim] 既にサーバーが起動しています。停止してから再起動します', vim.log.levels.INFO)
    M.stop_server(bufnr)
  end

  local cfg = config.get()
  local slidev_cmd = utils.find_slidev_command()

  -- 現在のファイルを取得
  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local dir = vim.fn.fnamemodify(filepath, ':h')

  -- ポート番号の決定
  local port = opts.port or cfg.port

  -- コマンドライン引数の構築（リスト形式）
  local cmd_parts = {}

  -- slidevコマンド本体を分解（npx slidev@latest の場合を考慮）
  for part in slidev_cmd:gmatch('%S+') do
    table.insert(cmd_parts, part)
  end

  -- エントリーファイル
  table.insert(cmd_parts, filepath)

  -- ポート指定
  table.insert(cmd_parts, '--port')
  table.insert(cmd_parts, tostring(port))

  -- ブラウザ自動起動
  if opts.open or cfg.auto_open_browser then
    table.insert(cmd_parts, '--open')
  end

  -- リモートアクセス
  if opts.remote or cfg.remote then
    table.insert(cmd_parts, '--remote')
    if opts.remote and opts.remote ~= true then
      table.insert(cmd_parts, opts.remote)
    elseif cfg.remote and cfg.remote ~= true then
      table.insert(cmd_parts, cfg.remote)
    end
  end

  -- テーマ指定
  if opts.theme or cfg.theme then
    table.insert(cmd_parts, '--theme')
    table.insert(cmd_parts, opts.theme or cfg.theme)
  end

  -- デバッグ用：コマンド文字列を構築
  local full_cmd = table.concat(cmd_parts, ' ')

  config.debug_log('サーバー起動コマンド: ' .. full_cmd)
  vim.notify('[slidev.nvim] Slidev サーバーを起動中...', vim.log.levels.INFO)

  -- エラーメッセージを収集
  local output_lines = {}

  -- プロセス起動（リスト形式で渡す）
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

            -- サーバー起動完了を検出
            if clean_line:match('Local:') or clean_line:match('localhost:' .. port) then
              vim.notify('[slidev.nvim] サーバーが起動しました: http://localhost:' .. port, vim.log.levels.INFO)

              -- ブラウザを開く（--openオプションがない場合）
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

            -- エラーメッセージの場合は通知
            if clean_line:match('[Ee]rror') or clean_line:match('[Ee]xception') then
              vim.notify('[slidev.nvim] エラー: ' .. clean_line, vim.log.levels.ERROR)
            end
          end
        end
      end
    end,

    on_exit = function(_, exit_code, _)
      config.debug_log('プロセス終了: exit_code=' .. exit_code)
      M.jobs[bufnr] = nil

      if exit_code ~= 0 and exit_code ~= 143 then  -- 143 = SIGTERM
        -- エラー出力を表示
        local error_msg = '[slidev.nvim] サーバーが異常終了しました: exit_code=' .. exit_code
        if #output_lines > 0 then
          error_msg = error_msg .. '\n\nコマンド: ' .. full_cmd .. '\n出力:\n' .. table.concat(output_lines, '\n')
        end
        vim.notify(error_msg, vim.log.levels.ERROR)
      else
        vim.notify('[slidev.nvim] サーバーを停止しました', vim.log.levels.INFO)
      end
    end,
  })

  if job_id <= 0 then
    vim.notify('[slidev.nvim] サーバーの起動に失敗しました', vim.log.levels.ERROR)
    return
  end

  M.jobs[bufnr] = job_id
  config.debug_log('job_id=' .. job_id .. ' でサーバーを起動しました')

  -- バッファクローズ時の自動停止
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = bufnr,
    callback = function()
      M.stop_server(bufnr)
    end,
    once = true,
  })
end

-- Slidev開発サーバーを停止
-- @param bufnr number バッファ番号
function M.stop_server(bufnr)
  local job_id = M.jobs[bufnr]

  if not job_id then
    vim.notify('[slidev.nvim] 起動中のサーバーが見つかりません', vim.log.levels.WARN)
    return
  end

  config.debug_log('サーバーを停止中: job_id=' .. job_id)
  vim.fn.jobstop(job_id)
  M.jobs[bufnr] = nil
end

-- すべてのSlidev開発サーバーを停止
function M.stop_all_servers()
  local count = 0
  for bufnr, job_id in pairs(M.jobs) do
    config.debug_log('サーバーを停止中: bufnr=' .. bufnr .. ', job_id=' .. job_id)
    vim.fn.jobstop(job_id)
    count = count + 1
  end

  M.jobs = {}

  if count > 0 then
    vim.notify('[slidev.nvim] ' .. count .. ' 個のサーバーを停止しました', vim.log.levels.INFO)
  else
    vim.notify('[slidev.nvim] 起動中のサーバーはありません', vim.log.levels.INFO)
  end
end

-- 現在のバッファでサーバーが起動しているかチェック
-- @param bufnr number|nil バッファ番号（nilの場合は現在のバッファ）
-- @return boolean サーバーが起動している場合はtrue
function M.is_server_running(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return M.jobs[bufnr] ~= nil
end

return M
