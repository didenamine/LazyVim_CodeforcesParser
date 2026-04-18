local M = {}

local function get_problem()
  local ui = require("codeforces.ui")
  if ui._current then return ui._current end

  local path = vim.fn.expand("%:p")
  local cid, idx = path:match("codeforces%.nvim[/\\](%d+)[/\\]([A-Za-z0-9]+)[/\\]")
  if cid and idx then
    local p = require("codeforces.storage").load(cid, idx)
    if p then ui._current = p; return p end
  end
  return nil
end

local function compile(problem, cfg, callback)
  local lang = cfg.language
  local tpl  = (cfg.compile_commands or {})[lang]
  if not tpl then callback(nil); return end

  local bin = problem.dir .. "/.bin"
  local cmd = tpl
    :gsub("%%out", vim.fn.shellescape(bin))
    :gsub("%%src", vim.fn.shellescape(problem.solution_path))
    :gsub("%%dir", vim.fn.shellescape(problem.dir))

  require("codeforces.ui").notify_running("Compiling…")

  vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data then
        local msg = table.concat(data, "\n"):match("^%s*(.-)%s*$")
        if msg ~= "" then
          vim.schedule(function()
            vim.notify("[CF] " .. msg, vim.log.levels.WARN)
          end)
        end
      end
    end,
    on_exit = vim.schedule_wrap(function(_, code)
      if code ~= 0 then
        callback("Compilation failed (exit " .. code .. ")")
      else
        problem._bin = bin
        callback(nil)
      end
    end),
  })
end

local function run_test(problem, cfg, idx, callback)
  local test = problem.tests[idx]
  if not test then callback({ index = idx, error = "not found" }); return end

  local lang    = cfg.language
  local run_tpl = (cfg.run_commands or {})[lang] or problem._bin or problem.solution_path
  local bin     = problem._bin or problem.solution_path
  local in_file = problem.tests_dir .. "/" .. idx .. ".in"
  local out_file = "/tmp/cf_out_" .. idx
  local timeout_s = math.max(1, math.floor((cfg.timeout or 5000) / 1000))

  local run_cmd = run_tpl
    :gsub("%%out", vim.fn.shellescape(bin))
    :gsub("%%src", vim.fn.shellescape(problem.solution_path))
    :gsub("%%dir", vim.fn.shellescape(problem.dir))

  local shell = ("timeout %d sh -c '%s < %s > %s 2>&1'"):format(
    timeout_s,
    run_cmd:gsub("'", "'\\''"),
    vim.fn.shellescape(in_file),
    vim.fn.shellescape(out_file)
  )

  vim.fn.jobstart(shell, {
    on_exit = vim.schedule_wrap(function(_, code)
      local actual = table.concat(vim.fn.readfile(out_file) or {}, "\n")

      local function norm(s)
        local ls = vim.split(s:match("^%s*(.-)%s*$"), "\n")
        for i, l in ipairs(ls) do ls[i] = l:match("^(.-)%s*$") end
        while #ls > 0 and ls[#ls] == "" do table.remove(ls) end
        return table.concat(ls, "\n")
      end

      local passed = code == 0 and norm(actual) == norm(test.output)
      callback({
        index    = idx,
        passed   = passed,
        input    = test.input,
        expected = test.output,
        actual   = code == 124 and "[Time Limit Exceeded]" or actual,
        timedout = code == 124,
      })
    end),
  })
end

  local function get_lang_from_ext(path)
    local ext = path:match("%.([^.]+)$")
    local inv_map = { cpp = "cpp", py = "python", c = "c", java = "java" }
    return inv_map[ext] or ext
  end

  function M.run_all()
    local problem = get_problem()
    if not problem then
      vim.notify("[CF] No problem loaded. Use :CF fetch <url>", vim.log.levels.ERROR)
      return
    end
    if #problem.tests == 0 then
      vim.notify("[CF] No test cases found.", vim.log.levels.WARN)
      return
    end

    local cfg = vim.deepcopy(require("codeforces.config").get())
    cfg.language = get_lang_from_ext(problem.solution_path)

    compile(problem, cfg, function(err)
      if err then vim.notify("[CF] " .. err, vim.log.levels.ERROR); return end
      require("codeforces.ui").notify_running("Running " .. #problem.tests .. " test(s)…")

      local results   = {}
      local remaining = #problem.tests

      for i = 1, #problem.tests do
        run_test(problem, cfg, i, function(r)
          results[r.index] = r
          remaining = remaining - 1
          if remaining == 0 then
            local ordered = {}
            for j = 1, #problem.tests do table.insert(ordered, results[j]) end
            require("codeforces.ui").show_results(ordered)
          end
        end)
      end
    end)
  end

  function M.run_one(idx)
    local problem = get_problem()
    if not problem then
      vim.notify("[CF] No problem loaded.", vim.log.levels.ERROR)
      return
    end
    local cfg = vim.deepcopy(require("codeforces.config").get())
    cfg.language = get_lang_from_ext(problem.solution_path)

    compile(problem, cfg, function(err)
      if err then vim.notify("[CF] " .. err, vim.log.levels.ERROR); return end
      run_test(problem, cfg, idx, function(r)
        require("codeforces.ui").show_results({ r })
      end)
    end)
  end

return M
