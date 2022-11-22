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


local trouble = require('trouble.providers.telescope')
local telescope = require('telescope')
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-t>"] = trouble.open_with_trouble,
        ["<esc>"] = require('telescope.actions').close
      },
      n = { ["<C-t>"] = trouble.open_with_trouble },
    }
  },
  pickers = {
    buffers = {
      theme = "dropdown"
    }
  }
})
telescope.load_extension('fzf')
vim.cmd([[
  nnoremap <silent><leader>ff <cmd>Telescope find_files<cr>
  nnoremap <silent><leader>fg <cmd>Telescope live_grep<cr>
  nnoremap <silent><leader>fb <cmd>Telescope buffers<cr>
  nnoremap <silent><leader>fh <cmd>Telescope help_tags<cr>
  nnoremap <silent><leader>fs <cmd>Telescope git_status<cr>
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
  }
})
vim.cmd([[
  nnoremap <silent><leader>s <cmd>BufferLinePick<cr>
  nnoremap <silent><leader>d <cmd>BufferLinePickClose<cr>
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
  nnoremap <silent><S-left> <cmd>BufferLineMovePrev<cr>
  nnoremap <silent><S-right> <cmd>BufferLineMoveNext<cr>
]])

require('lualine').setup({
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
  nnoremap <silent><leader>r <cmd>RnvimrToggle<cr>
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

-- Heavily inspired by: https://www.reddit.com/r/neovim/comments/r74647/comment/hmx0w58/
-- Doesn't work though...
local telescope_live_grep_in_ranger_folder = function(opts)
  local Path = require "plenary.path"
  local action_set = require "telescope.actions.set"
  local action_state = require "telescope.actions.state"
  local actions = require "telescope.actions"
  local conf = require("telescope.config").values
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local os_sep = Path.path.sep
  local pickers = require "telescope.pickers"
  local scan = require "plenary.scandir"

  opts = opts or {}
  local data = {}
  scan.scan_dir(vim.loop.cwd(), {
    hidden = opts.hidden,
    only_dirs = true,
    respect_gitignore = opts.respect_gitignore,
    on_insert = function(entry)
      table.insert(data, entry .. os_sep)
    end,
  })
  table.insert(data, 1, "." .. os_sep)

  pickers.new(opts, {
    prompt_title = "Folders for Live Grep",
    finder = finders.new_table { results = data, entry_maker = make_entry.gen_from_file(opts) },
    previewer = conf.grep_previewer(opts),
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      action_set.select:replace(function()
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        local dirs = {}
        local selections = current_picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          table.insert(dirs, action_state.get_selected_entry().value)
        else
          for _, selection in ipairs(selections) do
            table.insert(dirs, selection.value)
          end
        end
        actions._close(prompt_bufnr, current_picker.initial_mode == "insert")
        require("telescope.builtin").live_grep { search_dirs = dirs }
      end)
      return true
    end,
  }):find()
end

-- Doesn't work yet...
-- vim.keymap.set('n', '<leader>fl', telescope_live_grep_in_ranger_folder, { noremap = true, silent = true })

require('neotest').setup({
  adapters = {
    require("neotest-rust")
  }
})
