--
-- UI
--

require("tokyonight").setup({
  on_highlights = function(hl, c)
    local util = require("tokyonight.util")
    hl.LspInlayHint = {
      bg = util.darken(c.blue7, 0.1),
      fg = c.dark3,
      style = {
        italic = true
      }
    }
  end
})
vim.cmd([[colorscheme tokyonight-moon]])

require('colorizer').setup {}
require('nvim-web-devicons').setup()
require('mini.move').setup()

require('nvim-tree').setup({
  diagnostics = {
    enable = true,
    show_on_dirs = true,
  },
  on_attach = function(bufnr)
    local api = require('nvim-tree.api')
    local telescope = require('telescope.builtin')

    local function opts(desc)
      return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    api.config.mappings.default_on_attach(bufnr)

    vim.keymap.set(
      "n",
      "<leader>fg",
      function()
        local node = api.tree.get_node_under_cursor()
        if node and node.type == "directory" then
          telescope.live_grep({
            search_dirs = { node.absolute_path }
          })
        else
          telescope.live_grep()
        end
      end,
      opts('Telescope live grep')
    )
  end,
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    icons = {
      show = {
        git = false,
      },
    },
  },
  filters = {
    custom = { "^\\.git$" }
  },
  filesystem_watchers = {
    enable = true,
    debounce_delay = 50,
    -- FIXME: shouldn't be necessary
    -- maybe? https://github.com/nvim-tree/nvim-tree.lua/issues/1931
    ignore_dirs = {
      ".*/target/debug/.*"
    },
  }
})
vim.cmd([[
  noremap <silent><C-n> <cmd>NvimTreeToggle<cr>
  noremap <silent><leader>tf <cmd>NvimTreeFocus<cr>
]])

require('trouble').setup({
  padding = false,
  auto_jump = { 'lsp_definitions', 'lsp_type_definitions' },
  action_keys = {
    jump_close = { '<cr>' },
    jump = { "o", "<tab>" }
  }
})
vim.cmd([[
  nnoremap <silent><leader>xx <cmd>Trouble diagnostics toggle<cr>
  nnoremap <silent><leader>xX <cmd>Trouble diagnostics toggle filter.buf=0<cr>
  nnoremap <silent><leader>cs <cmd>Trouble symbols toggle focus=false<cr>
  nnoremap <silent><leader>cr <cmd>Trouble lsp toggle focus=false win.position=right<cr>

]])


local telescope = require('telescope')
local trouble = require('trouble.sources.telescope')
telescope.setup({
  defaults = {
    -- path_display = { 'smart' },
    mappings = {
      i = {
        ["<C-t>"] = trouble.open,
        ["<esc>"] = require('telescope.actions').close
      },
      n = { ["<C-t>"] = trouble.open },
    },
    dynamic_preview_title = true,
  },
  pickers = {
    buffers = {
      theme = "dropdown",
      sort_mru = true,
      ignore_current_buffer = true
    },
  }
})
telescope.load_extension('fzf')
vim.cmd([[
  nnoremap <silent><leader>ff <cmd>Telescope find_files<cr>
  nnoremap <silent><leader>fg <cmd>Telescope live_grep<cr>
  nnoremap <silent><leader>fb <cmd>Telescope buffers<cr>
  nnoremap <silent><leader>fh <cmd>Telescope help_tags<cr>
  nnoremap <silent><leader>fs <cmd>Telescope git_status<cr>
  nnoremap <silent><leader>fw <cmd>Telescope grep_string<cr>
  nnoremap <silent><leader>fl <cmd>Telescope lsp_dynamic_workspace_symbols<cr>
]])

vim.api.nvim_create_user_command('Rg', function(opts)
  local path = vim.fn.getcwd()

  -- try retrieving current node from nvim-tree-lua
  local view = require("nvim-tree.view")
  if view.is_visible() then
    local api = require("nvim-tree.api")
    local node = api.tree.get_node_under_cursor()
    if node and node.type == "directory" then
      local abs_path = node.absolute_path
      local local_path = string.sub(abs_path, string.len(path) + 1, string.len(abs_path))
      local choice = vim.fn.input({
        prompt = "Use " .. local_path .. " ? (y/N) ",
        default = ""
      })
      if choice == "y" then
        path = node.absolute_path
      end
    end
  end

  -- command cleanup
  vim.cmd("echo \"\"")

  require('telescope.builtin').live_grep({
    search_dirs = { path },
    additional_args = opts.fargs
  })
end, { nargs = '*' })

-- Add last modification date to buffer
vim.cmd([[
  aug ChangedTime
    au!
    au TextChangedI,TextChanged * let b:changedtime = localtime()
  aug END
]])
require('scope').setup()
require('bufferline').setup({
  options = {
    show_close_icon = false,
    show_buffer_close_icons = false,
    separator_style = 'thin',
    -- diagnostics = 'nvim_lsp',
    -- diagnostics_indicator = function(count, level, diagnostics_dict, context)
    --   if context.buffer:current() then
    --     return ''
    --   end
    --   local icon = level:match("error") and " " or ""
    --   return " " .. icon .. count
    -- end,
    name_formatter = function(buf)
      capture = string.match(buf.path, 'cargo/registry/.*/(.*)-%d+%.%d+%.%d+/src')
      if capture then
        return buf.name .. ' @ ' .. capture
      end
      return buf.name
    end,
    sort_by = function(buffer_a, buffer_b)
      local a = tonumber(vim.fn.getbufvar(buffer_a.id, 'changedtime')) or 0
      local b = tonumber(vim.fn.getbufvar(buffer_b.id, 'changedtime')) or 0
      return a > b
    end
  }
})
vim.cmd([[
  nnoremap <silent><leader>b <cmd>BufferLinePick<cr>
  nnoremap <silent><leader>p <cmd>BufferLineTogglePin<cr>
  nnoremap <silent><leader>1 <cmd>lua require("bufferline").go_to_buffer(1, true)<cr>
  nnoremap <silent><leader>2 <cmd>lua require("bufferline").go_to_buffer(2, true)<cr>
  nnoremap <silent><leader>3 <cmd>lua require("bufferline").go_to_buffer(3, true)<cr>
  nnoremap <silent><leader>4 <cmd>lua require("bufferline").go_to_buffer(4, true)<cr>
  nnoremap <silent><leader>5 <cmd>lua require("bufferline").go_to_buffer(5, true)<cr>
  nnoremap <silent><leader>6 <cmd>lua require("bufferline").go_to_buffer(6, true)<cr>
  nnoremap <silent><leader>7 <cmd>lua require("bufferline").go_to_buffer(7, true)<cr>
  nnoremap <silent><leader>8 <cmd>lua require("bufferline").go_to_buffer(8, true)<cr>
  nnoremap <silent><leader>9 <cmd>lua require("bufferline").go_to_buffer(9, true)<cr>
  nnoremap <silent><leader>$ <cmd>lua require("bufferline").go_to_buffer(-1, true)<cr>
  nnoremap <silent><A-left> <cmd>BufferLineCyclePrev<cr>
  nnoremap <silent><A-right> <cmd>BufferLineCycleNext<cr>
]])

require('lualine').setup({
  sections = {
    lualine_b = {
      {
        'filename',
        path = 1,
      }
    },
    lualine_c = { 'diff', 'diagnostics' },
    lualine_x = {}
  },
  extensions = { 'nvim-dap-ui', 'nvim-tree', 'trouble' }
})

require('marks').setup {}

-- https://github.com/rmagatti/auto-session/issues/259
require('auto-session').setup {
  pre_save_cmds = { "NvimTreeClose" },
  save_extra_cmds = {
    "NvimTreeOpen"
  },
  post_restore_cmds = {
    "NvimTreeOpen"
  }
}

vim.cmd([[
  let g:floaterm_width  = 0.8
  let g:floaterm_height = 0.8
  let g:floaterm_opener = 'edit'
  " let g:floaterm_keymap_new    = '<C-s>'
  " let g:floaterm_keymap_prev   = '<C-p>'
  " let g:floaterm_keymap_next   = '<C-n>'
  let g:floaterm_keymap_toggle = '<F4>'
  " let g:floaterm_keymap_kill   = '<C-k>'
  " rnvimr is slight faster as it keeps ranger process in the background
  nnoremap <silent><C-.> <cmd>FloatermNew ranger<cr>
  tnoremap <silent><C-.> <cmd>FloatermNew ranger<CR>
]])

require('spectre').setup({
  highlight = {
    ui = "Keyword",
    search = "diffChanged",
    replace = "diffAdded"
  }
})
vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', {
  desc = "Toggle Spectre"
})
vim.keymap.set('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
  desc = "Search current word"
})
vim.keymap.set('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', {
  desc = "Search current word"
})
vim.keymap.set('n', '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
  desc = "Search on current file"
})
