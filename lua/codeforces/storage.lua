local M = {}

local function problem_dir(contest_id, index)
  return vim.fn.stdpath("data") .. "/codeforces.nvim/" .. contest_id .. "/" .. index
end

local function mkdir(path)
  vim.fn.mkdir(path, "p")
end

local function write_file(path, lines)
  vim.fn.writefile(lines, path)
end

local function render_markdown(problem)
  local lines = {}
  local function push(s) table.insert(lines, s or "") end

  push("# " .. problem.title)
  push("")
  push("**Contest:** " .. problem.contest_id .. "  |  **Problem:** " .. problem.index)
  push("**Time limit:** " .. problem.time_limit .. "  |  **Memory:** " .. problem.memory_limit)
  push("**URL:** " .. problem.url)
  push("")
  push(("─"):rep(60))
  push("")

  if problem.sections and #problem.sections > 0 then
    for _, sec in ipairs(problem.sections) do
      if sec.heading then
        push("## " .. sec.heading)
        push("")
      end
      for _, l in ipairs(vim.split(sec.text, "\n")) do
        push(l)
      end
      push("")
    end
  else
    push("*(No statement extracted — open the URL in your browser)*")
    push("")
  end

  push(("─"):rep(60))
  push("")
  push("## Sample Tests")
  push("")

  if #problem.tests == 0 then
    push("*(No sample tests found)*")
  else
    for i, t in ipairs(problem.tests) do
      push("### Test " .. i)
      push("")
      push("**Input:**")
      push("```")
      for _, l in ipairs(vim.split(t.input, "\n")) do push(l) end
      push("```")
      push("")
      push("**Expected output:**")
      push("```")
      for _, l in ipairs(vim.split(t.output, "\n")) do push(l) end
      push("```")
      push("")
    end
  end

  return lines
end

local stubs = {
  cpp = function(p)
    return {
      "// " .. p.contest_id .. p.index .. " – " .. p.title,
      "#include <bits/stdc++.h>",
      "using namespace std;",
      "",
      "int main() {",
      "    ios_base::sync_with_stdio(false);",
      "    cin.tie(NULL);",
      "",
      "    // TODO",
      "",
      "    return 0;",
      "}",
    }
  end,
  python = function(p)
    return {
      "# " .. p.contest_id .. p.index .. " – " .. p.title,
      "import sys",
      "input = sys.stdin.readline",
      "",
      "def solve():",
      "    pass  # TODO",
      "",
      "solve()",
    }
  end,
  java = function(p)
    return {
      "// " .. p.contest_id .. p.index .. " – " .. p.title,
      "import java.util.*;",
      "import java.io.*;",
      "",
      "public class Main {",
      "    public static void main(String[] args) throws IOException {",
      "        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));",
      "        // TODO",
      "    }",
      "}",
    }
  end,
  c = function(p)
    return {
      "// " .. p.contest_id .. p.index .. " – " .. p.title,
      "#include <stdio.h>",
      "",
      "int main() {",
      "    // TODO",
      "    return 0;",
      "}",
    }
  end,
}

function M.save(problem, lang)
  local dir  = problem_dir(problem.contest_id, problem.index)
  local tdir = dir .. "/tests"
  mkdir(dir)
  mkdir(tdir)

  write_file(dir .. "/problem.md", render_markdown(problem))

  for i, t in ipairs(problem.tests) do
    write_file(tdir .. "/" .. i .. ".in",  vim.split(t.input,  "\n"))
    write_file(tdir .. "/" .. i .. ".out", vim.split(t.output, "\n"))
  end

  local cfg = require("codeforces.config").get()
  local target_lang = lang or cfg.language
  local ext_map = { cpp = "cpp", c = "c", python = "py", java = "java" }
  local ext  = ext_map[target_lang] or target_lang
  local name = (target_lang == "java") and "Main" or "solution"
  local sol  = dir .. "/" .. name .. "." .. ext

  if vim.fn.filereadable(sol) ~= 1 then
    local gen = stubs[target_lang] or stubs.cpp
    write_file(sol, gen(problem))
  end

  problem.dir           = dir
  problem.tests_dir     = tdir
  problem.solution_path = sol
  problem.md_path       = dir .. "/problem.md"
end

function M.load(contest_id, index)
  local dir = problem_dir(contest_id, index)
  if vim.fn.filereadable(dir .. "/problem.md") ~= 1 then return nil end

  local tests = {}
  local i = 1
  while true do
    local inp = dir .. "/tests/" .. i .. ".in"
    local out = dir .. "/tests/" .. i .. ".out"
    if vim.fn.filereadable(inp) ~= 1 then break end
    table.insert(tests, {
      input  = table.concat(vim.fn.readfile(inp),  "\n"),
      output = table.concat(vim.fn.readfile(out) or {}, "\n"),
    })
    i = i + 1
  end

  local cfg = require("codeforces.config").get()
  local ext_map = { cpp = "cpp", c = "c", python = "py", java = "java" }
  local ext  = ext_map[cfg.language] or cfg.language
  local name = (cfg.language == "java") and "Main" or "solution"

  return {
    contest_id    = contest_id,
    index         = index,
    tests         = tests,
    dir           = dir,
    tests_dir     = dir .. "/tests",
    solution_path = dir .. "/" .. name .. "." .. ext,
    md_path       = dir .. "/problem.md",
  }
end

function M.list_problems()
  local base = vim.fn.stdpath("data") .. "/codeforces.nvim"
  if vim.fn.isdirectory(base) ~= 1 then
    vim.notify("[CF] No problems saved yet.", vim.log.levels.INFO)
    return
  end
  local lines = { "Saved problems:" }
  for _, cid in ipairs(vim.fn.readdir(base)) do
    local cdir = base .. "/" .. cid
    if vim.fn.isdirectory(cdir) == 1 then
      for _, pidx in ipairs(vim.fn.readdir(cdir)) do
        table.insert(lines, "  " .. cid .. "/" .. pidx)
      end
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
