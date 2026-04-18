local M = {}
M._current = nil

local function set_win_opts(win, opts)
  for k, v in pairs(opts) do
    vim.api.nvim_win_set_option(win, k, v)
  end
end

function M.open(problem)
  M._current = problem

  vim.cmd("tabnew")

  -- Left: problem statement
  local lines   = vim.fn.readfile(problem.md_path)
  local prob_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(prob_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(prob_buf, "filetype",   "markdown")
  vim.api.nvim_buf_set_option(prob_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(prob_buf, "buftype",    "nofile")

  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, prob_buf)
  vim.api.nvim_win_set_width(left_win, math.floor(vim.o.columns * 0.45))
  set_win_opts(left_win, { wrap = true, linebreak = true, number = false })

  -- Right: solution file
  vim.cmd("vsplit")
  local right_win = vim.api.nvim_get_current_win()
  vim.cmd("edit " .. vim.fn.fnameescape(problem.solution_path))
  set_win_opts(right_win, { number = true, relativenumber = true })

  -- Keymaps on solution buffer
  local sol_buf = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "<leader>ct", function()
    require("codeforces.runner").run_all()
  end, { buffer = sol_buf, desc = "CF: run all tests" })
  vim.keymap.set("n", "<leader>co", function()
    vim.api.nvim_set_current_win(left_win)
  end, { buffer = sol_buf, desc = "CF: focus problem pane" })

  vim.api.nvim_set_current_win(right_win)
  vim.notify(("[CF] Opened %s/%s — %d test(s). <leader>ct to test."):format(
    problem.contest_id, problem.index, #problem.tests), vim.log.levels.INFO)
end

function M.open_last()
  if not M._current then
    vim.notify("[CF] No problem loaded yet.", vim.log.levels.WARN)
    return
  end
  M.open(M._current)
end

function M.notify_running(msg)
  vim.notify("[CF] " .. msg, vim.log.levels.INFO)
end

function M.show_results(results)
  local lines = { "  Test Results  ", "" }
  local all_pass = true

  for _, r in ipairs(results) do
    if r.error then
      table.insert(lines, "✗ Error: " .. r.error)
      all_pass = false
    else
      if not r.passed then all_pass = false end
      table.insert(lines, (r.passed and "✓" or "✗") .. " Test " .. r.index)
      if not r.passed then
        table.insert(lines, "  Input:")
        for _, l in ipairs(vim.split(r.input or "", "\n")) do
          table.insert(lines, "    " .. l)
        end
        table.insert(lines, "  Expected:")
        for _, l in ipairs(vim.split(r.expected or "", "\n")) do
          table.insert(lines, "    " .. l)
        end
        table.insert(lines, "  Got:")
        for _, l in ipairs(vim.split(r.actual or "", "\n")) do
          table.insert(lines, "    " .. l)
        end
      end
      table.insert(lines, "")
    end
  end

  table.insert(lines, all_pass and "  ✓ All passed!" or "  ✗ Some tests failed")
  table.insert(lines, "")
  table.insert(lines, "  q / <Esc> to close")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype",    "nofile")

  local width  = math.min(70, vim.o.columns - 6)
  local height = math.min(#lines + 2, vim.o.lines - 8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = math.floor((vim.o.lines   - height) / 2),
    col       = math.floor((vim.o.columns - width)  / 2),
    style     = "minimal",
    border    = "rounded",
    title     = all_pass and " ✓ All Passed " or " ✗ Some Failed ",
    title_pos = "center",
  })
  vim.api.nvim_win_set_option(win, "wrap", true)

  -- Highlights
  local ns = vim.api.nvim_create_namespace("cf_results")
  for i, line in ipairs(lines) do
    if line:match("^✓") or line:match("All passed") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticOk",    i-1, 0, -1)
    elseif line:match("^✗") or line:match("Some tests") then
      vim.api.nvim_buf_add_highlight(buf, ns, "DiagnosticError", i-1, 0, -1)
    end
  end

  local close = function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set("n", "q",     close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

return M
