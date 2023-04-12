--
-- UI
--

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
-- https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#workaround-when-using-rmagattiauto-session
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  pattern = 'NvimTree*',
  callback = function()
    local view = require('nvim-tree.view')
    local is_visible = view.is_visible()

    local api = require('nvim-tree.api')
    if not is_visible then
      api.tree.open()
    end
  end,
})

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
  nnoremap <silent><leader>s <cmd>BufferLinePick<cr>
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
  extensions = { 'nvim-dap-ui', 'symbols-outline', 'nvim-tree' }
})

require('marks').setup {}

require("auto-session").setup {}

-- -- ranger
-- vim.cmd([[
--   " Hide ranger after picking a file
--   let g:rnvimr_enable_picker = 1
--   " Hide the files included in gitignore
--   let g:rnvimr_hide_gitignore = 1
--   " wipe buffers associated with deleted files
--   let g:rnvimr_enable_bw = 1
--   nnoremap <silent><C-.> <cmd>RnvimrToggle<cr>
--   tnoremap <silent><C-.> <cmd>RnvimrToggle<CR>
-- ]])

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

require('neotest').setup({
  adapters = {
    require("neotest-rust")
  }
})
