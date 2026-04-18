if vim.g.codeforces_nvim_loaded then return end
vim.g.codeforces_nvim_loaded = true

vim.api.nvim_create_user_command("CF", function(args)
  local cf = require("codeforces")
  if not cf._setup_done then
    cf.setup({})
    cf._setup_done = true
  end

  local parts = vim.split(args.args, "%s+", { trimempty = true })
  local sub   = parts[1]

  if sub == "fetch" then
    local url = parts[2]
    if not url then
      vim.notify("[CF] Usage: :CF fetch <url>", vim.log.levels.ERROR)
      return
    end
    require("codeforces.fetch").fetch_and_open(url)

  elseif sub == "runtests" then
    require("codeforces.runner").run_all()

  elseif sub == "testcase" then
    local idx = tonumber(parts[2])
    if not idx then
      vim.notify("[CF] Usage: :CF testcase <number>", vim.log.levels.ERROR)
      return
    end
    require("codeforces.runner").run_one(idx)

  elseif sub == "open" then
    require("codeforces.ui").open_last()

  elseif sub == "list" then
    require("codeforces.storage").list_problems()

  else
    vim.notify("[CF] Unknown sub-command: " .. (sub or "(none)") ..
      "\nAvailable: fetch, runtests, testcase, open, list", vim.log.levels.ERROR)
  end
end, {
  nargs    = "+",
  desc     = "Codeforces plugin",
  complete = function()
    return { "fetch", "runtests", "testcase", "open", "list" }
  end,
})
