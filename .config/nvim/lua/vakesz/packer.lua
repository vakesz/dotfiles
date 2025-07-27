vim.cmd [[packadd packer.nvim]]

-- for your Telescope mappings
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
	  'nvim-telescope/telescope.nvim', 
	  tag = '0.1.8',
	  requires = {'nvim-lua/plenary.nvim'}
  }


  use {
	  'rose-pine/neovim',
	  as = 'rose-pine',
	  config = function()
		  vim.cmd('colorscheme rose-pine')
	  end,
  }

end)
