-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    {
      '<leader>e',
      function()
        require('neo-tree.command').execute({ toggle = true, dir = vim.uv.cwd() })
      end,
      desc = 'Explorer NeoTree (Root Dir)',
    },
    {
      '<leader>E',
      function()
        require('neo-tree.command').execute({ toggle = true, dir = vim.lsp.buf.list_workspace_folders()[1] })
      end,
      desc = 'Explorer NeoTree (CWD)',
    },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['<leader>e'] = 'close_window',
        },
      },
      filtered_items = {
        visible = true, -- show hidden files by default
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      follow_current_file = {
        enabled = true, -- This will find and focus the file you are currently editing
      },
    },
  },
}
