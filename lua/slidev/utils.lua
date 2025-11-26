-- utils.lua: ユーティリティ関数

local config = require('slidev.config')

local M = {}

-- Slidev CLIコマンドの検出
-- 優先順位: 設定 > グローバル > ローカル > npx
-- @return string Slidev CLIコマンドのパス
function M.find_slidev_command()
  -- 設定で明示的に指定されている場合はそれを使用
  local cfg = config.get()
  if cfg.slidev_command then
    config.debug_log('設定から Slidev コマンドを使用: ' .. cfg.slidev_command)
    return cfg.slidev_command
  end

  -- グローバルインストールされたslidevを検索（PATHから）
  local global_slidev = vim.fn.exepath('slidev')
  if global_slidev ~= '' then
    config.debug_log('グローバル Slidev を検出: ' .. global_slidev)
    return global_slidev
  end

  -- ローカルの node_modules/.bin/slidev を検索
  local local_slidev = vim.fn.findfile('node_modules/.bin/slidev', '.;')
  if local_slidev ~= '' then
    local full_path = vim.fn.fnamemodify(local_slidev, ':p')
    config.debug_log('ローカル Slidev を検出: ' .. full_path)
    return full_path
  end

  -- フォールバック: npx を使用（正しいパッケージ名 @slidev/cli）
  config.debug_log('npx @slidev/cli@latest を使用')
  return 'npx @slidev/cli@latest'
end

-- URLをブラウザで開く（クロスプラットフォーム対応）
-- @param url string 開くURL
function M.open_browser(url)
  local cfg = config.get()

  if not cfg.auto_open_browser then
    config.debug_log('auto_open_browser が無効のため、ブラウザを開きません')
    return
  end

  local cmd
  local browser = cfg.browser

  -- ブラウザが指定されている場合
  if browser then
    cmd = browser .. ' ' .. vim.fn.shellescape(url)
  else
    -- システムデフォルトブラウザを使用
    if vim.fn.has('mac') == 1 then
      cmd = 'open ' .. vim.fn.shellescape(url)
    elseif vim.fn.has('unix') == 1 then
      cmd = 'xdg-open ' .. vim.fn.shellescape(url)
    elseif vim.fn.has('win32') == 1 then
      cmd = 'start ' .. vim.fn.shellescape(url)
    else
      vim.notify('[slidev.nvim] サポートされていないプラットフォームです', vim.log.levels.WARN)
      return
    end
  end

  config.debug_log('ブラウザを起動: ' .. cmd)
  vim.fn.system(cmd)
end

-- 現在のバッファのファイルパスを取得
-- @return string|nil ファイルパス（存在しない場合はnil）
function M.get_current_file()
  local filepath = vim.fn.expand('%:p')
  if filepath == '' then
    vim.notify('[slidev.nvim] ファイルが開かれていません', vim.log.levels.ERROR)
    return nil
  end
  return filepath
end

-- 現在のバッファのディレクトリパスを取得
-- @return string|nil ディレクトリパス（存在しない場合はnil）
function M.get_current_dir()
  local filepath = M.get_current_file()
  if not filepath then
    return nil
  end
  return vim.fn.fnamemodify(filepath, ':h')
end

-- ANSIエスケープシーケンスを削除
-- @param str string 入力文字列
-- @return string エスケープシーケンスを削除した文字列
function M.strip_ansi_codes(str)
  -- ANSI エスケープシーケンスのパターンをマッチして削除
  return str:gsub('\27%[[0-9;]*m', '')
end

-- ポート番号が使用可能かチェック
-- @param port number ポート番号
-- @return boolean 使用可能な場合はtrue
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
