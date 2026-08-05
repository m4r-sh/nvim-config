if vim.fn.has("nvim-0.12") ~= 1 then
  error("this configuration requires Neovim 0.12 or newer")
end

-- Keep first-run parser installs visible to Neovim's runtime cache. The
-- default data-site entry may not exist when Neovim first expands runtimepath.
vim.fn.mkdir(vim.fs.joinpath(vim.fn.stdpath("data"), "site"), "p")
vim.o.runtimepath = vim.o.runtimepath
vim.loader.enable()
require("config.options")
local plugins = require("config.plugins")
plugins.setup()

vim.cmd("filetype plugin indent on")
require("config.treesitter").setup()
plugins.load_argiope()
require("argiope").setup()
vim.cmd.colorscheme("argiope")
require("config.keymaps").setup({
  plugins = true,
})
require("config.lsp").setup()
