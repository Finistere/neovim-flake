--
-- UI
--

vim.cmd([[colorscheme tokyonight-moon]])

require('nvim-web-devicons').setup()

local fzf = require('fzf-lua')

local function hidden_rg_opts(extra_args)
  local args = {
    '--column',
    '--line-number',
    '--no-heading',
    '--color=always',
    '--smart-case',
    '--max-columns=4096',
    '--hidden',
  }
  for _, arg in ipairs(extra_args or {}) do
    table.insert(args, vim.fn.shellescape(arg))
  end
  table.insert(args, '-e')
  return table.concat(args, ' ')
end

require('nvim-tree').setup({
  diagnostics = {
    enable = true,
    show_on_dirs = true,
  },
  on_attach = function(bufnr)
    local api = require('nvim-tree.api')

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
          fzf.live_grep({
            cwd = node.absolute_path,
            rg_opts = hidden_rg_opts(),
          })
        else
          fzf.live_grep({
            rg_opts = hidden_rg_opts(),
          })
        end
      end,
      opts('fzf-lua live grep')
    )
    vim.keymap.set(
      "n",
      "<leader>ff",
      function()
        local node = api.tree.get_node_under_cursor()
        if node and node.type == "directory" then
          fzf.files({
            hidden = true,
            cwd = node.absolute_path,
          })
        else
          fzf.files()
        end
      end,
      opts('fzf-lua files')
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
  sort = {
    folders_first = false
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
  noremap <silent><C-,> <cmd>NvimTreeToggle<cr>
  noremap <silent><C-/> <cmd>NvimTreeFindFile<cr>
]])

require('trouble').setup({
  padding = false,
  auto_jump = { 'lsp_definitions', 'lsp_type_definitions' },
  action_keys = {
    jump_close = { '<cr>' },
    jump = { 'o', '<tab>' }
  }
})
vim.cmd([[
  nnoremap <silent><leader>xx <cmd>Trouble diagnostics toggle focus=true<cr>
  nnoremap <silent><leader>xd <cmd>Trouble diagnostics toggle filter.buf=0 focus=true<cr>
  nnoremap <silent><leader>cs <cmd>Trouble symbols toggle focus=false<cr>
  nnoremap <silent><leader>cr <cmd>Trouble lsp toggle focus=false win.position=right<cr>

]])


fzf.setup({
  files = {
    hidden = false,
  },
  buffers = {
    sort_lastused = true,
    ignore_current_buffer = true,
  },
})
local fzf_config = require('fzf-lua.config')
fzf_config.defaults.actions.files['ctrl-t'] = require('trouble.sources.fzf').actions.open
vim.cmd([[
  nnoremap <silent><leader>ff <cmd>FzfLua files<cr>
  nnoremap <silent><leader>fb <cmd>FzfLua buffers<cr>
  nnoremap <silent><leader>fh <cmd>FzfLua helptags<cr>
  nnoremap <silent><leader>fs <cmd>FzfLua git_status<cr>
  nnoremap <silent><leader>fw <cmd>FzfLua grep_cword<cr>
  nnoremap <silent><leader>fal <cmd>FzfLua lsp_workspace_symbols<cr>
  nnoremap <silent><leader>fl <cmd>FzfLua lsp_document_symbols<cr>
]])
vim.keymap.set('n', '<leader>fg', function()
  fzf.live_grep({
    rg_opts = hidden_rg_opts(),
  })
end, { silent = true })

vim.api.nvim_create_user_command('Rg', function(opts)
  local path = vim.fn.getcwd()

  -- try retrieving current node from nvim-tree-lua
  local view = require('nvim-tree.view')
  if view.is_visible() then
    local api = require('nvim-tree.api')
    local node = api.tree.get_node_under_cursor()
    if node and node.type == "directory" then
      local abs_path = node.absolute_path
      local local_path = string.sub(abs_path, string.len(path) + 1, string.len(abs_path))
      local choice = vim.fn.input({
        prompt = "Use " .. local_path .. " ? (y/N) ",
        default = '',
      })
      if choice == 'y' then
        path = node.absolute_path
      end
    end
  end

  -- command cleanup
  vim.cmd('echo ""')

  fzf.live_grep({
    cwd = path,
    rg_opts = hidden_rg_opts(opts.fargs),
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
vim.cmd([[
  nnoremap <silent><leader>tn <cmd>tabnew<cr>
  nnoremap <silent><leader>tc <cmd>tabclose<cr>
  nnoremap <silent><leader>to <cmd>tabonly<cr>
  nnoremap <silent><leader>th <cmd>tabprevious<cr>
  nnoremap <silent><leader>tl <cmd>tabnext<cr>
  nnoremap <silent><leader>t1 <cmd>tabnext 1<cr>
  nnoremap <silent><leader>t2 <cmd>tabnext 2<cr>
  nnoremap <silent><leader>t3 <cmd>tabnext 3<cr>
  nnoremap <silent><leader>t4 <cmd>tabnext 4<cr>
  nnoremap <silent><leader>t5 <cmd>tabnext 5<cr>
  nnoremap <silent><leader>t6 <cmd>tabnext 6<cr>
  nnoremap <silent><leader>t7 <cmd>tabnext 7<cr>
  nnoremap <silent><leader>t8 <cmd>tabnext 8<cr>
  nnoremap <silent><leader>t9 <cmd>tabnext 9<cr>
]])
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
  let g:floaterm_keymap_toggle = '<F13>'
  " let g:floaterm_keymap_kill   = '<C-k>'
  " rnvimr is slight faster as it keeps ranger process in the background
  nnoremap <silent><C-.> <cmd>FloatermNew ranger<cr>
  tnoremap <silent><C-.> <cmd>FloatermNew ranger<CR>
]])
