-- config.lua: 設定管理モジュール

local M = {}

-- デフォルト設定
M.defaults = {
  -- Slidev CLIコマンドのパス（nilの場合は自動検出）
  slidev_command = nil,

  -- 開発サーバーのデフォルトポート
  port = 3030,

  -- ブラウザ自動起動の有効化
  auto_open_browser = true,

  -- 使用するブラウザ（nilの場合はシステムデフォルト）
  browser = nil,

  -- デバッグログの出力
  debug = false,

  -- リモートアクセスの設定
  remote = nil,  -- nilまたはパスワード文字列

  -- テーマの指定
  theme = nil,
}

-- 現在の設定（ユーザー設定でオーバーライド可能）
M.options = vim.deepcopy(M.defaults)

-- 設定のセットアップ
-- @param user_config table|nil ユーザー提供の設定
function M.setup(user_config)
  M.options = vim.tbl_deep_extend('force', M.defaults, user_config or {})

  if M.options.debug then
    vim.notify('[slidev.nvim] 設定完了: ' .. vim.inspect(M.options), vim.log.levels.DEBUG)
  end
end

-- 現在の設定を取得
-- @return table 現在の設定
function M.get()
  return M.options
end

-- デバッグログの出力
-- @param message string ログメッセージ
function M.debug_log(message)
  if M.options.debug then
    vim.notify('[slidev.nvim] ' .. message, vim.log.levels.DEBUG)
  end
end

return M
