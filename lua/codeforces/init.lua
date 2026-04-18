local M = {}

M.config = {
  language         = "cpp",
  timeout          = 5000,
  compile_commands = {
    cpp    = "g++ -O2 -o %out %src",
    c      = "gcc -O2 -o %out %src",
    java   = "javac -d %dir %src",
  },
  run_commands = {
    cpp    = "%out",
    c      = "%out",
    python = "python3 %src",
    java   = "java -cp %dir Main",
  },
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

return M