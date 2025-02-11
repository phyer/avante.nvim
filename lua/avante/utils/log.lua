local M = {}
--
-- local log_file = vim.fn.stdpath("cache") .. "/avante_requests.log"
local log_file = "/tmp/avante/avante_requests.log"

function M.log_request(url, headers, body)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local log_entry = string.format(
    [[
[%s] Request Details:
URL: %s
Headers:
%s
Body:
%s
]],
    timestamp,
    url,
    vim.inspect(headers),
    vim.inspect(body)
  )

  -- Append to log file
  local file = io.open(log_file, "a")
  if file then
    file:write(log_entry .. "\n\n")
    file:close()
  end
end

return M
