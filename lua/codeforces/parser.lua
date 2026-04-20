local M = {}

local function strip_tags(s)
  return s:gsub("<[^>]+>", "")
end

local function decode_entities(s)
  return s
    :gsub("&lt;",   "<")
    :gsub("&gt;",   ">")
    :gsub("&amp;",  "&")
    :gsub("&quot;", '"')
    :gsub("&#39;",  "'")
    :gsub("&nbsp;", " ")
    :gsub("&#(%d+);", function(n) return string.char(tonumber(n)) end)
end

local function html_to_text(s)
  s = s:gsub("<br%s*/?>", "\n")
  s = s:gsub("</p>",     "\n")
  s = s:gsub("<p[^>]*>", "")
  s = strip_tags(s)
  s = decode_entities(s)
  s = s:gsub("\n\n\n+", "\n\n")
  return s:match("^%s*(.-)%s*$")
end

local function extract_class(html, class_name)
  local pattern = '<([a-zA-Z0-9]+)[^>]+class="[^"]*' .. class_name .. '[^"]*"[^>]*>'
  local s, e, tag_name = html:find(pattern)
  if not s then return nil end

  local rest = html:sub(e + 1)
  local open_tag  = "<" .. tag_name
  local close_tag = "</" .. tag_name .. ">"

  local depth = 1
  local i = 1
  local len = #rest
  local result_end = len

  while i <= len and depth > 0 do
    local open_s  = rest:find(open_tag,  i, true)
    local close_s = rest:find(close_tag, i, true)

    if not close_s then break end

    if open_s and open_s < close_s then
      depth = depth + 1
      i = open_s + #open_tag
    else
      depth = depth - 1
      if depth == 0 then
        result_end = close_s - 1
      end
      i = close_s + #close_tag
    end
  end

  return rest:sub(1, result_end)
end

local function parse_title(html)
  local t = html:match('<div class="title">%s*(.-)%s*</div>')
  if t then return decode_entities(strip_tags(t)) end
  local pt = html:match("<title>(.-)</title>")
  if pt then return decode_entities(pt) end
  return "Unknown Problem"
end

local function parse_limits(html)
  local tl = html:match("time limit per test</div>%s*<div[^>]*>([^<]+)") or "?"
  local ml = html:match("memory limit per test</div>%s*<div[^>]*>([^<]+)") or "?"
  return decode_entities(tl):match("^%s*(.-)%s*$"),
         decode_entities(ml):match("^%s*(.-)%s*$")
end

local function parse_statement(html)
  local block = extract_class(html, "problem%-statement")
  if not block then return {} end
  block = block:gsub('<div class="header">.-</div>%s*', "")

  local sections = {}
  -- Split by section-title divs to get individual sections
  local parts = {}
  local last_pos = 1
  while true do
    local s, e = block:find('<div class="section%-title">', last_pos)
    if not s then
      table.insert(parts, block:sub(last_pos))
      break
    end
    table.insert(parts, block:sub(last_pos, s - 1))
    last_pos = e + 1   -- Fix: move past the found title to avoid infinite loop
  end

  for _, part in ipairs(parts) do
    local title, content = part:match('<div class="section%-title">([^<]*)</div>(.*)')
    if title and content then
      local heading = decode_entities(title):match("^%s*(.-)%s*$")
      local text    = html_to_text(content)
      if heading ~= "" and text ~= "" then
        table.insert(sections, { heading = heading, text = text })
      end
    end
  end

  if #sections == 0 then
    local raw = html_to_text(block)
    if raw ~= "" then
      table.insert(sections, { heading = nil, text = raw })
    end
  end

  return sections
end

local function parse_tests(html)
  local tests = {}
  local sample_block = extract_class(html, "sample%-tests")
                    or extract_class(html, "sample%-test")
  if not sample_block then return tests end

  local pres = {}
  -- Match pre tags with any attributes
  for pre_content in sample_block:gmatch("<pre[^>]*>(.-)</pre>") do
    local text = pre_content
      :gsub("<br%s*/?>", "\n")
      :gsub("<[^>]+>", "")
    text = decode_entities(text)
    text = text:match("^%s*(.-)%s*$") or text
    table.insert(pres, text)
  end

  local i = 1
  while i + 1 <= #pres do
    table.insert(tests, { input = pres[i], output = pres[i + 1] })
    i = i + 2
  end

  return tests
end

function M.parse(html, contest_id, index)
  if not html or html == "" then return nil, "empty HTML" end

  if not html:find("problem-statement", 1, true)
  and not html:find("sample-tests", 1, true) then
    return nil, "no problem statement found (private/future contest?)"
  end

  local problem = {
    contest_id   = contest_id,
    index        = index,
    title        = parse_title(html),
    time_limit   = nil,
    memory_limit = nil,
    sections     = parse_statement(html),
    tests        = parse_tests(html),
    url          = ("https://codeforces.com/contest/%s/problem/%s"):format(contest_id, index),
    fetched_at   = os.time(),
  }

  local tl, ml = parse_limits(html)
  problem.time_limit   = tl
  problem.memory_limit = ml

  if #problem.tests == 0 then
    vim.notify("[CF] Warning: no sample tests found", vim.log.levels.WARN)
  else
    vim.notify(("[CF] Parsed '%s' — %d test(s)"):format(problem.title, #problem.tests), vim.log.levels.INFO)
  end

  return problem, nil
end

return M
