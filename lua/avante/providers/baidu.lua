-- FILEPATH: avante.nvim/lua/avante/providers/baidu.lua
local Utils = require("avante.utils")
local Config = require("avante.config")
local P = require("avante.providers")

---@class AvanteProviderFunctor
local M = {}

M.api_key_name = "BAIDU_API_KEY"

M.role_map = {
  user = "user",
  assistant = "assistant",
}

---@param opts AvantePromptOptions
M.parse_messages = function(opts)
  local messages = {}

  table.insert(messages, { role = "user", content = opts.system_prompt })

  vim
    .iter(opts.messages)
    :each(function(msg) table.insert(messages, { role = M.role_map[msg.role], content = msg.content }) end)

  return messages
end

M.parse_response = function(ctx, data_stream, _, opts)
  if data_stream:match('"%[DONE%]":') then
    opts.on_stop({ reason = "complete" })
    return
  end

  ---@type BaiduChatResponse
  local jsn = vim.json.decode(data_stream)
  if jsn.result then
    opts.on_chunk(jsn.result)
    if jsn.is_end then opts.on_stop({ reason = "complete" }) end
  end
end

local Log = require("avante.utils.log")

M.parse_curl_args = function(provider, prompt_opts)
  local base, body_opts = P.parse_config(provider)

  -- 验证 appid 是否存在
  if not base.appid or base.appid == "" then error("Baidu provider requires appid to be set in config") end

  local headers = {
    ["Content-Type"] = "application/json",
    ["appid"] = base.appid, -- 将 appid 加入请求头
  }

  if P.env.require_api_key(base) then
    local api_key = provider.parse_api_key()
    if api_key == nil then
      error("Baidu API key is not set, please set BAIDU_API_KEY in your environment variable or config file")
    end
    headers["Authorization"] = "Bearer " .. api_key
  end

  local request = {
    url = Utils.url_join(base.endpoint, "/chat/completions"),
    proxy = base.proxy,
    insecure = base.allow_insecure,
    headers = headers,
    body = vim.tbl_deep_extend("force", {
      model = base.model,
      messages = M.parse_messages(prompt_opts),
      disable_search = base.disable_search,
      enable_citation = base.enable_citation,
    }, body_opts),
  }

  -- 记录请求详细信息
  Log.log_request(request.url, request.headers, request.body)

  return request
end

return M
