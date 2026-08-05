-- Set leaders before any plugin or keymap configuration is loaded.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 3
vim.opt.softtabstop = 3
vim.opt.tabstop = 3
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.signcolumn = "yes"
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳ "

local function disable_comment_continuation()
   vim.opt_local.formatoptions:remove({ "c", "r", "o" })
end

disable_comment_continuation()

local comment_group = vim.api.nvim_create_augroup("config_comment_continuation", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
   group = comment_group,
   callback = disable_comment_continuation,
   desc = "Do not continue comments automatically",
})

if vim.uv.os_uname().sysname == "Darwin" then
   vim.opt.clipboard:append("unnamedplus")
end
