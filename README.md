# slidev.nvim

Neovim plugin for [Slidev](https://sli.dev/) - a presentation slides tool for developers.

This plugin allows you to use Slidev CLI features directly from Neovim, enabling you to create presentations without switching to other editors like VSCode.

## Features

- Launch dev server with live preview
- Export to multiple formats (PDF, PNG, PPTX, Markdown)
- Production build (SPA)
- Markdown formatting
- Auto cleanup on buffer close
- Cross-platform support (macOS, Linux, Windows)

## Requirements

- Neovim 0.7+
- Node.js and npm (required for Slidev CLI)
- Slidev CLI (recommended: global installation)

### Installing Slidev CLI

```bash
# Global installation (recommended)
npm install -g @slidev/cli

# Or local installation per project
npm install -D @slidev/cli

# Can also use npx without installation
```

### For Export Functionality

PDF/PNG/PPTX export requires Playwright:

```bash
# For global Slidev installation
npm install -g playwright-chromium

# For local installation
npm install -D playwright-chromium
```

**Alternative**: Browser Export
1. Start server with `:SlidevPreview`
2. Navigate to `http://localhost:3030/export` in browser
3. Use browser's print function to save as PDF

The plugin detects Slidev CLI in the following priority:
1. Command specified in config
2. Global installation (detected from PATH)
3. Local installation (`node_modules/.bin/slidev`)
4. Auto-run with npx (`@slidev/cli@latest`)

## Installation

### lazy.nvim

```lua
{
  'mei28/slidev.nvim',
  config = function()
    require('slidev').setup({
      -- Optional configuration (default values)
      port = 3030,
      auto_open_browser = true,
      debug = false,
    })
  end,
}
```

### packer.nvim

```lua
use {
  'mei28/slidev.nvim',
  config = function()
    require('slidev').setup()
  end
}
```

### vim-plug

```vim
Plug 'mei28/slidev.nvim'

lua << EOF
require('slidev').setup()
EOF
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:SlidevPreview` | Start dev server and open in browser |
| `:SlidevWatch` | Alias for `SlidevPreview` |
| `:SlidevStop` | Stop server for current buffer |
| `:SlidevStopAll` | Stop all servers |
| `:SlidevExport [format]` | Export (default: pdf) |
| `:SlidevBuild` | Build for production |
| `:SlidevFormat` | Format markdown |
| `:SlidevStatus` | Show detailed server status (all buffers) |

### Basic Workflow

1. Open a Slidev markdown file:
   ```vim
   :e slides.md
   ```

2. Start preview:
   ```vim
   :SlidevPreview
   ```

3. Edit with live reload

4. Export:
   ```vim
   :SlidevExport pdf
   " Output: <filename>-export.pdf (same directory as source file)
   ```

### Configuration

```lua
require('slidev').setup({
  -- Path to Slidev CLI command (nil for auto-detect)
  slidev_command = nil,

  -- Default port for dev server
  port = 3030,

  -- Enable automatic browser opening
  auto_open_browser = true,

  -- Browser to use (nil for system default)
  browser = nil,

  -- Enable debug logging
  debug = false,

  -- Remote access configuration
  remote = nil,  -- nil or password string

  -- Theme specification
  theme = nil,
})
```

### Lua API

```lua
local slidev = require('slidev')

-- Preview
slidev.preview()

-- Preview with custom port
slidev.preview({ port = 8080 })

-- Stop server
slidev.stop()

-- Stop all servers
slidev.stop_all()

-- Export
slidev.export('pdf')
slidev.export('png', { dark = true, range = '1-5' })

-- Custom output path
slidev.export('pdf', { output = '/path/to/output.pdf' })
slidev.export('pdf', { output = 'my-slides.pdf' })  -- relative path

-- Build
slidev.build()
slidev.build({ out = 'build', download = true })

-- Custom output directory
slidev.build({ output = '/path/to/dist' })
slidev.build({ output = 'public' })  -- relative path

-- Format
slidev.format()

-- Check server status
if slidev.is_running() then
  print('Server is running')
end
```

## How It Works

slidev.nvim is implemented with an architecture inspired by marp.nvim:

1. **CLI Detection**: Prioritizes local `node_modules/.bin/slidev`, falls back to `npx @slidev/cli@latest`
2. **Process Management**: Launches Slidev CLI processes using `vim.fn.jobstart()`
3. **Auto Cleanup**: Automatically stops servers when buffers are closed
4. **Browser Integration**: Cross-platform browser launching

## Troubleshooting

### Server Won't Start

1. Verify Slidev CLI is installed:
   ```bash
   npx @slidev/cli@latest --version
   ```

2. Enable debug mode:
   ```lua
   require('slidev').setup({ debug = true })
   ```

3. Check Neovim messages:
   ```vim
   :messages
   ```

### Port Already in Use

Specify a different port:
```vim
:lua require('slidev').preview({ port = 8080 })
```

Or change default port in config:
```lua
require('slidev').setup({ port = 8080 })
```

## Contributing

Issues and Pull Requests are welcome.

## License

MIT

## Acknowledgments

This plugin was inspired by [marp.nvim](https://github.com/nwiizo/marp.nvim).
