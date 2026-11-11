local M = {}

local deferred_plugins = {
  ["argiope.nvim"] = true,
}

local function specs()
  return {
    {
      src = "https://github.com/nvim-treesitter/nvim-treesitter",
      name = "nvim-treesitter",
      version = "main",
    },
    {
      src = "https://github.com/m4r-sh/argiope.nvim",
      name = "argiope.nvim",
      version = vim.version.range("0.2"),
    },
    {
      src = "https://github.com/nvim-mini/mini.icons",
      name = "mini.icons",
      version = vim.version.range("0.17"),
    },
    {
      src = "https://github.com/folke/snacks.nvim",
      name = "snacks.nvim",
      version = vim.version.range("2.x"),
    },
    {
      src = "https://github.com/dmtrKovalenko/fff.nvim",
      name = "fff.nvim",
      version = vim.version.range("0.10"),
    },
    {
      src = "https://github.com/stevearc/oil.nvim",
      name = "oil.nvim",
      version = vim.version.range("2.x"),
    },
    {
      src = "https://github.com/kylechui/nvim-surround",
      name = "nvim-surround",
      version = vim.version.range("4.x"),
    },
    {
      src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
      name = "nvim-treesitter-textobjects",
    },
  }
end

local function install_fff_binary(event)
  local name = event.data.spec.name
  local kind = event.data.kind
  if name ~= "fff.nvim" or (kind ~= "install" and kind ~= "update") then
    return
  end

  if not event.data.active then
    vim.cmd.packadd("fff.nvim")
  end
  require("fff.download").download_or_build_binary()
end

local function load_plugin(plugin)
  if deferred_plugins[plugin.spec.name] then
    return
  end
  vim.cmd.packadd(plugin.spec.name)
end

function M.setup()
  local treesitter_group = vim.api.nvim_create_augroup("config_treesitter_update", { clear = true })
  vim.api.nvim_create_autocmd("PackChanged", {
    group = treesitter_group,
    callback = function(event)
      if event.data.spec.name == "nvim-treesitter"
        and (event.data.kind == "install" or event.data.kind == "update") then
        if not event.data.active then
          vim.cmd.packadd("nvim-treesitter")
        end
        require("nvim-treesitter").update():wait(300000)
      end
    end,
    desc = "Update Tree-sitter parsers after plugin changes",
  })

  local group = vim.api.nvim_create_augroup("config_fff_build", { clear = true })
  vim.api.nvim_create_autocmd("PackChanged", {
    group = group,
    callback = install_fff_binary,
    desc = "Install the fff native binary after plugin changes",
  })

  vim.g.fff = {
    lazy_sync = true,
  }

  vim.pack.add(specs(), {
    confirm = false,
    load = load_plugin,
  })

  require("mini.icons").setup()
  require("snacks").setup({
    explorer = {
      enabled = true,
      replace_netrw = true,
    },
    picker = {
      enabled = true,
      sources = {
        explorer = {
          formatters = {
            file = {
              git_status_hl = false,
            },
          },
        },
      },
    },
    image = {
      enabled = true,
    },
  })
  require("oil").setup({
    default_file_explorer = false,
    view_options = {
      show_hidden = true,
    },
  })
  require("nvim-treesitter-textobjects").setup({
    select = {
      lookahead = false,
    },
  })

  local surround_config = require("nvim-surround.config")
  require("nvim-surround").setup({
    surrounds = {
      ["`"] = {
        find = function()
          local template = surround_config.get_selection({
            query = {
              capture = "@template.outer",
              type = "textobjects",
            },
          })
          if template then
            return template
          end
          return surround_config.get_selection({ motion = "a`" })
        end,
      },
    },
  })
end

function M.load_argiope()
  vim.cmd.packadd("argiope.nvim")
end

return M
