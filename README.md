# codeforces.nvim

A feature-rich Codeforces plugin for Neovim. Solve competitive programming problems without leaving your favorite editor.

## Features

- **Cloudflare Bypass**: Uses Playwright to reliably fetch problems despite Cloudflare bot protection.
- **Language Choice**: Prompted to choose between **C++** and **Python** on every fetch.
- **Auto-Test Runner**: Run sample test cases with a single command and see detailed pass/fail results.
- **Side-by-Side View**: Opens the problem statement and solution file in a dedicated tab.
- **Smart Detection**: Runner automatically detects the language from your file extension.

## Requirements

- Neovim 0.8+
- [Node.js](https://nodejs.org/) & `npm` (required for Playwright)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "didenamine/LazyVim_CodeforcesParser",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "CF" },
  config = function()
    require("codeforces").setup({
      -- Default settings
      language = "cpp",
      timeout  = 5000,
    })
  end,
  build = function()
    -- Automatically install node dependencies
    local dir = vim.fn.stdpath("data") .. "/lazy/LazyVim_CodeforcesParser"
    if vim.fn.isdirectory(dir) == 1 then
      vim.fn.system("cd " .. vim.fn.shellescape(dir) .. " && npm install && npx playwright install chromium")
    end
  end,
}
```

## Setup

After installing, ensure you have the required Node.js browsers. If you need to install them manually, run the commands from the plugin root inside your Neovim data directory. The exact path depends on your system and lazy.nvim config.

```bash
npm install
npx playwright install chromium
```

## Usage

- `:CF fetch <url>`: Fetch a problem. You will be prompted to choose C++ or Python.
- `:CF runtests`: Run all sample test cases for the current problem.
- `:CF open`: Re-open the last fetched problem in a new tab.
- `:CF list`: List all locally saved problems.

### Keymaps

Inside a solution buffer, you can use:
- `<leader>ct`: Run all tests (shortcut for `:CF runtests`).
- `<leader>co`: Focus the problem statement pane.
