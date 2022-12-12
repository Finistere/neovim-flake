--
-- UI
--

require('colorizer').setup {}
require('nvim-web-devicons').setup()

require('nvim-tree').setup({
  open_on_setup = true,
  diagnostics = {
    enable = true,
    show_on_dirs = true,
  },
  on_attach = function(bufnr)
    local inject_node = require("nvim-tree.utils").inject_node
    local telescope = require('telescope.builtin')
    vim.keymap.set("n", "<leader>fg", inject_node(function(node)
      if node and node.type == "directory" then
        telescope.live_grep({
          search_dirs = { node.absolute_path }
        })
      end
    end), { buffer = bufnr, noremap = true })
  end,
  view = {
    hide_root_folder = true,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = false,
      },
    },
  },
  filters = {
    custom = { "^\\.git$" }
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
  nnoremap <silent><leader>xx <cmd>TroubleToggle<cr>
  nnoremap <silent><leader>xw <cmd>TroubleToggle workspace_diagnostics<cr>
  nnoremap <silent><leader>xd <cmd>TroubleToggle document_diagnostics<cr>
  nnoremap <silent><leader>xq <cmd>TroubleToggle quickfix<cr>
  nnoremap <silent><leader>xl <cmd>TroubleToggle loclist<cr>
]])


local telescope = require('telescope')
local trouble = require('trouble.providers.telescope')
telescope.setup({
  defaults = {
    -- path_display = { 'smart' },
    mappings = {
      i = {
        ["<C-t>"] = trouble.open_with_trouble,
        ["<esc>"] = require('telescope.actions').close
      },
      n = { ["<C-t>"] = trouble.open_with_trouble },
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
  nnoremap <silent><leader>fc <cmd>Telescope grep_string<cr>
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
  nnoremap <silent><leader>s <cmd>BufferLinePick<cr>
  nnoremap <silent><leader>p <cmd>BufferLineTogglePin<cr>
  nnoremap <silent><leader>1 <cmd>BufferLineGoToBuffer 1<cr>
  nnoremap <silent><leader>2 <cmd>BufferLineGoToBuffer 2<cr>
  nnoremap <silent><leader>3 <cmd>BufferLineGoToBuffer 3<cr>
  nnoremap <silent><leader>4 <cmd>BufferLineGoToBuffer 4<cr>
  nnoremap <silent><leader>5 <cmd>BufferLineGoToBuffer 5<cr>
  nnoremap <silent><leader>6 <cmd>BufferLineGoToBuffer 6<cr>
  nnoremap <silent><leader>7 <cmd>BufferLineGoToBuffer 7<cr>
  nnoremap <silent><leader>8 <cmd>BufferLineGoToBuffer 8<cr>
  nnoremap <silent><leader>9 <cmd>BufferLineGoToBuffer 9<cr>
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
  extensions = { 'nvim-dap-ui', 'symbols-outline', 'nvim-tree' }
})

require("auto-session").setup {}

-- ranger
vim.cmd([[
  " Hide ranger after picking a file
  let g:rnvimr_enable_picker = 1
  " Hide the files included in gitignore
  let g:rnvimr_hide_gitignore = 1
  " wipe buffers associated with deleted files
  let g:rnvimr_enable_bw = 1
  nnoremap <silent><C-.> <cmd>RnvimrToggle<cr>
  tnoremap <silent><C-.> <cmd>RnvimrToggle<CR>
]])

vim.cmd([[
  let g:floaterm_width  = 0.7
  let g:floaterm_height = 0.7
  let g:floaterm_opener = 'edit'
  " let g:floaterm_keymap_new    = '<C-s>'
  " let g:floaterm_keymap_prev   = '<C-p>'
  " let g:floaterm_keymap_next   = '<C-n>'
  let g:floaterm_keymap_toggle = '<F1>'
  " let g:floaterm_keymap_kill   = '<C-k>'
  " rnvimr is slight faster as it keeps ranger process in the background
  " nnoremap <silent><leader>r <cmd>FloatermNew ranger<cr>
]])

require('neotest').setup({
  adapters = {
    require("neotest-rust")
  }
})
