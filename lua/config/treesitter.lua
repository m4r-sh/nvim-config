local M = {}

local parser_packages = {
  "javascript",
  "html",
  "css",
  "glsl",
  "wgsl",
  "markdown",
  "markdown_inline",
}

local inherited_query_packages = {
  "ecma",
  "jsx",
  "html_tags",
}

local native_shader_languages = {
  glsl = "glsl",
  wgsl = "wgsl",
}

local function setup_native_shader_highlighting()
  local group = vim.api.nvim_create_augroup("config_treesitter_shaders", {
    clear = true,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = vim.tbl_keys(native_shader_languages),
    callback = function(event)
      vim.treesitter.start(event.buf, native_shader_languages[event.match])
    end,
    desc = "Start Tree-sitter highlighting for native shader buffers",
  })
end

function M.setup()
  setup_native_shader_highlighting()

  -- Vimote owns the Leg grammar and queries. Build with `bun run build:grammar`
  -- in that checkout; no parser build or installation is done during startup.
  local vimote = vim.env.VIMOTE_SOURCE or vim.fn.expand("~/vimote/vimote-neovim-spans")
  local runtime = vim.fs.joinpath(vimote, "editors", "neovim")
  if vim.fn.isdirectory(runtime) == 1 then
    vim.opt.runtimepath:prepend(runtime)
    require("vimote.leg").setup()
  end

  local missing = vim.tbl_filter(function(language)
    local ok, loaded = pcall(vim.treesitter.language.add, language)
    return not ok or not loaded
  end, parser_packages)

  for _, package_name in ipairs(inherited_query_packages) do
    local path = ("queries/%s/highlights.scm"):format(package_name)
    if #vim.api.nvim_get_runtime_file(path, false) == 0 then
      table.insert(missing, package_name)
    end
  end

  if #missing == 0 then
    return
  end

  local installed = require("nvim-treesitter").install(missing):wait(300000)
  if not installed then
    vim.notify(
      ("Failed to install Tree-sitter packages: %s"):format(
        table.concat(missing, ", ")
      ),
      vim.log.levels.ERROR
    )
  end

  -- Clear any query lookup memoized before the new runtime files existed.
  if type(vim.treesitter.query.get.clear) == "function" then
    vim.treesitter.query.get:clear()
  end
end

return M
