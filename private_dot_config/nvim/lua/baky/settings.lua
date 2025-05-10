vim.opt.shell = "bash"
vim.opt.shellcmdflag = "-c"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand("~/.vim/undo")
vim.opt.undofile = false

vim.opt.updatetime = 50
vim.opt.colorcolumn = "88"

vim.o.scrolloff = 5
vim.o.sidescrolloff = 5
vim.o.encoding = "utf-8"
vim.o.fileencoding = "utf-8"
vim.o.guifont = "JetBrains_Mono"
vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
vim.wo.relativenumber = true
vim.wo.number = true
vim.wo.wrap = false
vim.opt.virtualedit = 'all'
vim.opt.list = true
vim.opt.listchars = {
    eol = '⏎',
    trail = '●',
    nbsp = '⎵',
    extends = '→',
    precedes = '←',
    space = '·',
    tab = '--┊',
    leadmultispace = '···┊'
}
