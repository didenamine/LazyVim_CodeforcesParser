local M = {}

-- Path to the fetch_page.js Playwright script (same directory as this file)
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*)/")
local fetch_script = script_dir .. "/fetch_page.js"

local function node_bin()
  local sys = vim.fn.exepath("node")
  if sys and sys ~= "" then return sys end
  return "node"
end

local function parse_url(url)
  local id, idx = url:match("/problemset/problem/(%d+)/([A-Za-z0-9]+)")
  if id then return id, idx:upper() end
  id, idx = url:match("/contest/(%d+)/problem/([A-Za-z0-9]+)")
  if id then return id, idx:upper() end
  id, idx = url:match("/gym/(%d+)/problem/([A-Za-z0-9]+)")
  if id then return id, idx:upper() end
  return nil, nil
end

local function canonical_url(contest_id, index)
  return ("https://codeforces.com/contest/%s/problem/%s"):format(contest_id, index)
end

--- Fetch the page HTML using the local Playwright script.
local function fetch_via_playwright(url, callback)
  local stderr_chunks = {}

  -- stdout_buffered = true: Neovim collects ALL stdout into one array of lines,
  -- then fires on_stdout BEFORE on_exit, guaranteeing we have the full HTML.
  vim.fn.jobstart({ node_bin(), fetch_script, url }, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stdout = vim.schedule_wrap(function(_, data)
      -- data is a table of lines (the whole stdout split by \n)
      local html = table.concat(data, "\n")
      callback(nil, html)
    end),

    on_stderr = vim.schedule_wrap(function(_, data)
      if data then
        for _, chunk in ipairs(data) do
          if chunk ~= "" then table.insert(stderr_chunks, chunk) end
        end
      end
    end),

    on_exit = vim.schedule_wrap(function(_, code)
      if code ~= 0 then
        local err_msg = table.concat(stderr_chunks, "\n"):match("^%s*(.-)%s*$") or ""
        if err_msg == "" then err_msg = "node exited with code " .. code end
        callback("Playwright error: " .. err_msg, nil)
      end
      -- on exit code 0: html was already delivered via on_stdout
    end),
  })
end

function M.fetch_and_open(url)
  local contest_id, index = parse_url(url)
  if not contest_id then
    vim.notify("[CF] Could not parse URL: " .. url, vim.log.levels.ERROR)
    return
  end

  local langs = { "cpp", "c", "python", "java" }
  local lang_names = { cpp = "C++", c = "C", python = "Python", java = "Java" }
  vim.ui.select(langs, {
    prompt = "Choose language for this problem:",
    format_item = function(item)
      return lang_names[item] or item
    end,
  }, function(lang)
    if not lang then return end

    vim.notify(("[CF] Fetching %s/%s via headless browser…"):format(contest_id, index), vim.log.levels.INFO)

    fetch_via_playwright(canonical_url(contest_id, index), function(err, html)
      if err then
        vim.notify("[CF] Fetch error: " .. err, vim.log.levels.ERROR)
        return
      end

      local parser  = require("codeforces.parser")
      local storage = require("codeforces.storage")
      local ui      = require("codeforces.ui")

      local problem, parse_err = parser.parse(html, contest_id, index)
      if parse_err then
        vim.notify("[CF] Parse error: " .. parse_err, vim.log.levels.ERROR)
        return
      end

      storage.save(problem, lang)
      ui.open(problem)
    end)
  end)
end

return M
