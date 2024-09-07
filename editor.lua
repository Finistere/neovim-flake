--
-- EDITOR
--
require('leap').add_default_mappings()

vim.wo.foldlevel = 99
vim.wo.conceallevel = 2

require('gitsigns').setup({
  current_line_blame_opts = {
    delay = 100,
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local bopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', '<leader>hb', function() gs.blame_line { full = true } end, bopts)
    vim.keymap.set('n', '<leader>tb', gs.toggle_current_line_blame, bopts)
  end
})

require('diffview').setup()

require("nvim-surround").setup()

-- rainbow & indent guidelines
require("rainbow-delimiters")
require("ibl").setup({
  scope = {
    highlight = {
      "RainbowDelimiterRed",
      "RainbowDelimiterYellow",
      "RainbowDelimiterBlue",
      "RainbowDelimiterOrange",
      "RainbowDelimiterGreen",
      "RainbowDelimiterViolet",
      "RainbowDelimiterCyan",
    }
  }
})
local hooks = require "ibl.hooks"
hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

require('nvim-cursorline').setup()

require('Comment').setup()
require('range-highlight').setup()
require('todo-comments').setup()

-- nvim-ufo. Capabilities were also added to the LSP server.
vim.o.foldcolumn = '0' -- Whether to show folder column
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

require('ufo').setup()


-- disable highlight after search
-- https://this-week-in-neovim.org/2023/Jan/9#tips
local ns = vim.api.nvim_create_namespace('toggle_hlsearch')

local function toggle_hlsearch(char)
  if vim.fn.mode() == 'n' then
    local keys = { '<CR>', 'n', 'N', '*', '#', '?', '/' }
    local new_hlsearch = vim.tbl_contains(keys, vim.fn.keytrans(char))

    if vim.opt.hlsearch:get() ~= new_hlsearch then
      vim.opt.hlsearch = new_hlsearch
    end
  end
end

vim.on_key(toggle_hlsearch, ns)


if os.getenv("SSH_CONNECTION") ~= nil then
  local function copy(lines, _)
    require('osc52').copy(table.concat(lines, '\n'))
  end

  local function paste()
    return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
  end

  vim.g.clipboard = {
    name = 'osc52',
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
  }

  -- Now the '+' register will copy to system clipboard using OSC52
  vim.keymap.set('n', '<leader>c', '"+y')
  vim.keymap.set('n', '<leader>cc', '"+yy')
end
