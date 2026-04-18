local M = {}

function M.get()
  return require("codeforces").config
end

function M.problem_dir(contest_id, index)
  local base = vim.fn.stdpath("data") .. "/codeforces.nvim"
  return base .. "/" .. contest_id .. "/" .. index
end

function M.solution_path(contest_id, index)
  local cfg = M.get()
  local ext_map = { cpp = "cpp", c = "c", python = "py", java = "java" }
  local ext  = ext_map[cfg.language] or cfg.language
  local name = (cfg.language == "java") and "Main" or "solution"
  return M.problem_dir(contest_id, index) .. "/" .. name .. "." .. ext
end

return M
