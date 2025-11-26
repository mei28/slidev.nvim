-- init.lua: slidev.nvimのメインモジュール

local config = require('slidev.config')
local server = require('slidev.server')
local utils = require('slidev.utils')

local M = {}

-- プラグインのセットアップ
-- @param user_config table|nil ユーザー設定
function M.setup(user_config)
  config.setup(user_config)
end

-- Slidev開発サーバーを起動（プレビュー）
-- @param opts table|nil オプション
function M.preview(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()

  -- ファイルタイプのチェック（オプション）
  local filetype = vim.bo.filetype
  if filetype ~= 'markdown' and filetype ~= 'md' then
    vim.notify('[slidev.nvim] Markdownファイルで実行してください', vim.log.levels.WARN)
    return
  end

  server.start_server(bufnr, opts)
end

-- Slidev開発サーバーを停止
function M.stop()
  local bufnr = vim.api.nvim_get_current_buf()
  server.stop_server(bufnr)
end

-- すべてのSlidev開発サーバーを停止
function M.stop_all()
  server.stop_all_servers()
end

-- サーバーの状態を確認
-- @return boolean サーバーが起動している場合はtrue
function M.is_running()
  local bufnr = vim.api.nvim_get_current_buf()
  return server.is_server_running(bufnr)
end

-- エクスポート機能
-- @param format string エクスポート形式（'pdf', 'png', 'pptx', 'md'）
-- @param opts table|nil オプション
function M.export(format, opts)
  local export_module = require('slidev.export')
  export_module.export(format, opts)
end

-- ビルド機能
-- @param opts table|nil オプション
function M.build(opts)
  local build_module = require('slidev.build')
  build_module.build(opts)
end

-- フォーマット機能
-- @param opts table|nil オプション
function M.format(opts)
  opts = opts or {}

  local filepath = utils.get_current_file()
  if not filepath then
    return
  end

  local slidev_cmd = utils.find_slidev_command()
  local cmd = slidev_cmd .. ' format ' .. vim.fn.shellescape(filepath)

  config.debug_log('フォーマットコマンド: ' .. cmd)
  vim.notify('[slidev.nvim] フォーマット中...', vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        vim.notify('[slidev.nvim] フォーマット完了', vim.log.levels.INFO)
        -- ファイルを再読み込み
        vim.cmd('edit!')
      else
        vim.notify('[slidev.nvim] フォーマット失敗: exit_code=' .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

return M
