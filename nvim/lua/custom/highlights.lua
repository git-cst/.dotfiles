-- Custom highlight overrides for LSP semantic tokens
--
-- This module handles two things:
--   1. Fixes the Neovim semantic token modifier priority issue where
--      @lsp.mod.* and @lsp.typemod.* groups override @lsp.type.* groups
--      with unstyled fallbacks. See: https://github.com/neovim/neovim/issues/21576
--
--   2. Adds custom highlight definitions for specific token types to give
--      more visual distinction between variables, types, structs, classes, etc.
--
-- The highlights use catppuccin's palette API so they automatically adapt
-- to whichever flavour (latte, frappe, macchiato, mocha) is active.

local M = {}

--- Apply custom highlight groups using catppuccin palette colors.
--- Called after the colorscheme is loaded so the palette is available.
local function apply_custom_highlights()
  -- Pull colors from whichever catppuccin flavour is currently active.
  -- This makes highlights portable across latte/frappe/macchiato/mocha.
  local ok, palette = pcall(function()
    return require('catppuccin.palettes').get_palette()
  end)
  if not ok or not palette then
    vim.notify('highlights.lua: Could not load catppuccin palette', vim.log.levels.WARN)
    return
  end

  -- Catppuccin Mocha palette reference (other flavours have the same keys):
  --   rosewater  #f5e0dc    flamingo  #f2cdcd    pink      #f5c2e7
  --   mauve      #cba6f7    red       #f38ba8    maroon    #eba0ac
  --   peach      #fab387    yellow    #f9e2af    green     #a6e3a1
  --   teal       #94e2d5    sky       #89dceb    sapphire  #74c7ec
  --   blue       #89b4fa    lavender  #b4befe    text      #cdd6f4
  --   subtext1   #bac2de    subtext0  #a6adc8    overlay2  #9399b2
  --   overlay1   #7f849c    overlay0  #6c7086    surface2  #585b70
  --   surface1   #45475a    surface0  #313244    base      #1e1e2e
  --   mantle     #181825    crust     #11111b

  local highlights = {
    -----------------------------------------------------------------
    -- Variables
    -----------------------------------------------------------------
    -- Base variable highlight - gives variables a distinct color
    -- from plain text so they stand out in assignments and expressions
    ['@lsp.type.variable'] = { fg = palette.text },

    -- Variable definitions (declarations like `x := ...` or `x = ...`)
    -- Slightly different shade to distinguish declaration from usage
    ['@lsp.typemod.variable.definition'] = { fg = palette.flamingo },

    -- Readonly/constant variables (e.g. `const maxRetries = 3`)
    ['@lsp.typemod.variable.readonly'] = { fg = palette.peach, italic = true },

    -- Default library readonly variables (e.g. `nil`, `true`, `false` in Go)
    ['@lsp.typemod.variable.defaultLibrary'] = { fg = palette.red },

    -- String-typed variables
    ['@lsp.typemod.variable.string'] = { fg = palette.flamingo },

    -----------------------------------------------------------------
    -- Types, Classes, and Structs
    -----------------------------------------------------------------
    -- Type names (e.g. `string`, `int`, `Config`, `http.Client`)
    ['@lsp.type.type'] = { fg = palette.yellow },

    -- Class/struct instantiation and type references
    -- Used when a type is referenced as a constructor or struct literal
    -- e.g. `FastAPI(...)` in Python, `Config{...}` in Go
    ['@lsp.type.class'] = { fg = palette.yellow, bold = true },

    -- Struct types specifically (Go sends this as a modifier)
    -- e.g. `configFile` when its type is a struct
    ['@lsp.typemod.variable.struct'] = { fg = palette.rosewater },

    -- Interface types (Go sends this as a modifier)
    -- e.g. variables whose type is an interface like `io.Reader`
    ['@lsp.typemod.variable.interface'] = { fg = palette.rosewater, italic = true },

    -- Pointer types (Go sends this for pointer variables like `*Config`)
    ['@lsp.typemod.variable.pointer'] = { fg = palette.lavender },

    -- Default library variables (e.g. `nil`, `true`, `false` in Go)
    -- These are built-in readonly values - use red to make nil stand out
    ['@lsp.typemod.variable.defaultLibrary'] = { fg = palette.red },

    -- Type-based variable modifiers
    --
    -- gopls sends these for variables based on their resolved type.
    -- This also covers struct literal field keys (e.g. `Timeout:` in
    -- `Config{Timeout: 30}`) because gopls treats composite literal
    -- keys as typed variable references rather than properties.
    --
    -- Using lavender to give them subtle distinction from plain variables
    -- while matching the property highlight, since struct field keys
    -- are the most common case for these modifiers.
    ['@lsp.typemod.variable.string'] = { fg = palette.lavender },
    ['@lsp.typemod.variable.number'] = { fg = palette.lavender },
    ['@lsp.typemod.variable.bool'] = { fg = palette.lavender },
    ['@lsp.typemod.variable.map'] = { fg = palette.lavender },
    ['@lsp.typemod.variable.slice'] = { fg = palette.lavender },
    ['@lsp.typemod.variable.chan'] = { fg = palette.lavender },
    ['@lsp.typemod.variable.func'] = { fg = palette.lavender },

    -----------------------------------------------------------------
    -- Functions and Methods
    -----------------------------------------------------------------
    -- Function names in definitions
    ['@lsp.type.function'] = { fg = palette.blue },

    -- Method calls (e.g. `obj.Method()`)
    ['@lsp.type.method'] = { fg = palette.blue },

    -- Standard library functions (e.g. `fmt.Println`, `len()`, `print()`)
    ['@lsp.typemod.function.defaultLibrary'] = { fg = palette.sky },
    ['@lsp.typemod.method.defaultLibrary'] = { fg = palette.sky },

    -----------------------------------------------------------------
    -- Parameters and Properties
    -----------------------------------------------------------------
    -- Function/method parameters
    ['@lsp.type.parameter'] = { fg = palette.maroon, italic = true },

    -- Struct field names / object properties
    -- e.g. `Timeout:` in `Config{Timeout: 30}` or `self.name`
    ['@lsp.type.property'] = { fg = palette.lavender },

    -----------------------------------------------------------------
    -- Namespaces and Modules
    -----------------------------------------------------------------
    -- Package/module names (e.g. `fmt`, `os`, `config`, `database`)
    ['@lsp.type.namespace'] = { fg = palette.teal, italic = true },

    -----------------------------------------------------------------
    -- Enums and Constants
    -----------------------------------------------------------------
    ['@lsp.type.enumMember'] = { fg = palette.peach },

    -----------------------------------------------------------------
    -- Keywords and Decorators
    -----------------------------------------------------------------
    ['@lsp.type.decorator'] = { fg = palette.pink },

    -----------------------------------------------------------------
    -- Treesitter overrides for cases where LSP doesn't send tokens
    -----------------------------------------------------------------
    -- Constructor calls in Python (e.g. `FastAPI(...)`, `MyClass(...)`)
    -- Treesitter catches these even when basedpyright doesn't emit
    -- semantic tokens for them
    ['@constructor.python'] = { fg = palette.yellow, bold = true },

    -- Constructor calls in Go (struct literals)
    ['@constructor.go'] = { fg = palette.yellow, bold = true },
  }
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

--- Fix the semantic token modifier priority issue.
---
--- Neovim applies highlight groups at three priority levels:
---   @lsp.type.<type>.<ft>         priority 125
---   @lsp.mod.<mod>.<ft>           priority 126
---   @lsp.typemod.<type>.<mod>.<ft> priority 127
---
--- When a colorscheme doesn't define the higher-priority mod/typemod
--- groups, Neovim falls through to the bare @lsp group which is unstyled.
--- The higher priority means it overrides the correctly-styled @lsp.type.*.
---
--- This function registers an LspTokenUpdate autocmd that intercepts each
--- token and ensures any undefined modifier groups either:
---   - Link to the appropriate @lsp.type.* group (for typemod groups)
---   - Are cleared to empty (for mod-only groups)
---
--- A cache prevents redundant nvim_set_hl calls after the first occurrence.
local function setup_semantic_token_fix()
  local cleared_groups = {}

  vim.api.nvim_create_autocmd('LspTokenUpdate', {
    group = vim.api.nvim_create_augroup('custom-semantic-token-fix', { clear = true }),
    callback = function(args)
      local token = args.data.token
      if not token.modifiers then return end

      local ft = vim.bo[args.buf].filetype
      for mod, _ in pairs(token.modifiers) do
        -- Fix @lsp.mod.<mod>.<ft> groups (priority 126)
        -- Clear them so they don't contribute any styling
        local mod_group = '@lsp.mod.' .. mod .. '.' .. ft
        if not cleared_groups[mod_group] then
          vim.api.nvim_set_hl(0, mod_group, {})
          cleared_groups[mod_group] = true
        end

        -- Fix @lsp.typemod.<type>.<mod>.<ft> groups (priority 127)
        -- Link to the base @lsp.type.<type> so they pick up our custom colors
        local typemod_group = '@lsp.typemod.' .. token.type .. '.' .. mod .. '.' .. ft
        if not cleared_groups[typemod_group] then
          -- Check if we've defined a custom highlight for the non-ft-specific
          -- typemod group (e.g. @lsp.typemod.variable.struct). If so, link to
          -- that so our custom styling applies. Otherwise fall back to @lsp.type.
          local custom_typemod = '@lsp.typemod.' .. token.type .. '.' .. mod
          local custom_hl = vim.api.nvim_get_hl(0, { name = custom_typemod })

          if not vim.tbl_isempty(custom_hl) then
            vim.api.nvim_set_hl(0, typemod_group, { link = custom_typemod })
          else
            vim.api.nvim_set_hl(0, typemod_group, { link = '@lsp.type.' .. token.type })
          end
          cleared_groups[typemod_group] = true
        end
      end
    end,
  })
end

--- Main setup function. Call this after the colorscheme is loaded
--- and inside the lspconfig config function.
function M.setup()
  apply_custom_highlights()
  setup_semantic_token_fix()

  -- Reapply custom highlights when colorscheme changes so they
  -- persist across :colorscheme switches
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('custom-highlights-colorscheme', { clear = true }),
    callback = function()
      apply_custom_highlights()
    end,
  })
end

return M
