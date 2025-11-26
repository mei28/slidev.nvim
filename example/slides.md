---
theme: seriph
background: https://cover.sli.dev
class: text-center
highlighter: shiki
lineNumbers: false
info: |
  ## slidev.nvim Demo
  Neovim plugin for Slidev - presentation slides for developers
drawings:
  persist: false
transition: slide-left
title: Welcome to slidev.nvim
mdc: true
---

# Welcome to slidev.nvim 

Neovim plugin for Slidev

Control Slidev presentations directly from Neovim without switching editors.

<div class="pt-12">
  <span @click="$slidev.nav.next" class="px-2 py-1 rounded cursor-pointer" hover="bg-white bg-opacity-10">
    Press Space for next page <carbon:arrow-right class="inline"/>
  </span>
</div>

---
transition: fade-out
---

# What is slidev.nvim?

A Neovim plugin that brings Slidev CLI functionality into your editor

<v-clicks>

- 🚀 **Dev Server** - Launch with live preview and auto-reload
- 📦 **Export** - PDF, PNG, PPTX, and Markdown support
- 🏗️ **Build** - Generate production-ready SPA
- 🎨 **Format** - Auto-format markdown files
- 🔄 **Auto Cleanup** - Servers stop when buffers close
- 🌍 **Cross-platform** - macOS, Linux, Windows

</v-clicks>

---

# Features

Main features of slidev.nvim

### Server Management
- Start dev server with `:SlidevPreview` or `:SlidevWatch`
- Auto-detect Slidev CLI (global → local → npx)
- Automatic browser launch
- Process management per buffer

### Export & Build
- Export to multiple formats: PDF, PNG, PPTX, MD
- Build production SPA with `:SlidevBuild`
- Custom output paths supported

### Developer Experience
- Detailed server status with `:SlidevStatus`
- Debug logging available
- Auto cleanup on buffer close or Vim exit

---

# Commands

Available commands

| Command | Description |
|---------|-------------|
| `:SlidevPreview` | Start dev server and preview in browser |
| `:SlidevWatch` | Alias for SlidevPreview |
| `:SlidevStop` | Stop server for current buffer |
| `:SlidevStopAll` | Stop all servers |
| `:SlidevExport [format]` | Export (default: pdf) |
| `:SlidevBuild` | Build for production |
| `:SlidevFormat` | Format markdown |
| `:SlidevStatus` | Show detailed server status |

---

# Installation

### lazy.nvim

```lua
{
  'yourusername/slidev.nvim',
  config = function()
    require('slidev').setup({
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
  'yourusername/slidev.nvim',
  config = function()
    require('slidev').setup()
  end
}
```

---

# Code Example

Configuration options

```lua {all|2|4|5|all}
require('slidev').setup({
  port = 3030,              -- Dev server port
  auto_open_browser = true, -- Auto-open browser
  debug = false,            -- Enable debug logs
  slidev_command = nil,     -- Auto-detect CLI
  remote = nil,             -- Remote access password
  theme = nil,              -- Default theme
})
```

<arrow v-click="[3, 4]" x1="400" y1="420" x2="230" y2="330" color="#564" width="3" arrowSize="1" />

---

# Quick Start

Basic workflow

<v-clicks>

1. Open a Slidev markdown file
   ```vim
   :e slides.md
   ```

2. Start preview
   ```vim
   :SlidevPreview
   ```

3. Edit and watch live reload ✨

4. Export when ready
   ```vim
   :SlidevExport pdf
   " Output: slides-export.pdf
   ```

</v-clicks>

---

# Lua API

Use slidev.nvim from Lua

```lua
local slidev = require('slidev')

-- Preview with custom port
slidev.preview({ port = 8080 })

-- Export with options
slidev.export('pdf', {
  dark = true,
  range = '1-5',
  output = 'presentation.pdf'
})

-- Build with custom output
slidev.build({
  output = 'public',
  download = true
})

-- Check status
if slidev.is_running() then
  print('Server is running')
end
```

---

# How It Works

Architecture inspired by marp.nvim

<div class="grid grid-cols-2 gap-4">
<div>

### Process Management
- Uses `vim.fn.jobstart()`
- PTY mode for stable output
- Per-buffer job tracking
- Auto cleanup with autocmds

### CLI Detection
1. User-specified command
2. Global installation (PATH)
3. Local node_modules
4. npx fallback

</div>
<div>

### Browser Integration
- Cross-platform support
- Configurable browser
- Auto-open on server start

### Error Handling
- ANSI code stripping
- Detailed error messages
- Playwright detection
- Debug logging

</div>
</div>

---

# Requirements

What you need to run slidev.nvim

### Essential
- Neovim 0.7+
- Node.js and npm
- Slidev CLI

```bash
# Install Slidev CLI globally (recommended)
npm install -g @slidev/cli
```

### For Export (Optional)
PDF/PNG/PPTX export requires Playwright:

```bash
npm install -g playwright-chromium
```

**Alternative**: Use browser export at `http://localhost:3030/export`

---

# Configuration Example

Advanced configuration

```lua
require('slidev').setup({
  -- Path to Slidev CLI (nil for auto-detect)
  slidev_command = nil,

  -- Dev server port
  port = 3030,

  -- Browser settings
  auto_open_browser = true,
  browser = nil,  -- Use system default

  -- Remote presentation
  remote = nil,  -- or password string

  -- Theme
  theme = nil,

  -- Debug mode
  debug = false,
})
```

---
layout: center
class: text-center
---

# Thanks!

Made with ❤️ using Neovim and Slidev

[GitHub](https://github.com/mei28/slidev.nvim) · [Documentation](https://sli.dev)

<div class="pt-12">
  <span class="px-2 py-1 rounded border border-white border-opacity-20">
    Press ESC to exit presentation
  </span>
</div>
