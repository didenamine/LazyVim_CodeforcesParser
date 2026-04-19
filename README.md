# codeforcesparser.nvim

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

If you use LazyVim, put this in your `lua/plugins/example.lua` file:

```lua
return {
  {
    "didenamine/codeforcesparser.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "CF" },

    -- The repo is named codeforcesparser.nvim, but the Lua module is "codeforces".
    main = "codeforces",
    opts = {
      language = "cpp",
      timeout = 5000,
    },

    -- Runs from the plugin directory.
    build = "npm install && npx playwright install chromium",
  },
}
```

## Setup

After lazy.nvim installs the plugin, make sure Playwright's Chromium browser is available.

The easiest (path-independent) way is:

```vim
:Lazy build codeforcesparser.nvim
```

If you prefer to run it manually, run these commands from the plugin root:

```bash
npm install
npx playwright install chromium
```

To find the actual checkout path on any system/config:

```vim
:lua print(require("lazy.core.config").options.root)
```

Then use `<printed_root>/codeforcesparser.nvim`.

## Usage

- `:CF fetch <url>`: Fetch a problem. You will be prompted to choose C++ or Python.
- `:CF runtests`: Run all sample test cases for the current problem.
- `:CF open`: Re-open the last fetched problem in a new tab.
- `:CF list`: List all locally saved problems.

### Keymaps

Inside a solution buffer, you can use:
- `<leader>ct`: Run all tests (shortcut for `:CF runtests`).
- `<leader>co`: Focus the problem statement pane.
