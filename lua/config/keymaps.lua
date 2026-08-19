local M = {}

local function map(mode, lhs, rhs, description, options)
  vim.keymap.set(
    mode,
    lhs,
    rhs,
    vim.tbl_extend("force", {
      desc = description,
      silent = true,
    }, options or {})
  )
end

local function escape_markdown_template_syntax()
  local bufnr = vim.api.nvim_get_current_buf()
  local first = vim.api.nvim_buf_get_mark(bufnr, "<")
  local last = vim.api.nvim_buf_get_mark(bufnr, ">")
  local mode = vim.fn.visualmode()

  if first[1] == 0 or last[1] == 0 then
    return
  end

  local function escape(text)
    return text:gsub("%${", "\\${"):gsub("`", "\\`")
  end

  if mode == "\22" then
    local first_column = math.min(first[2], last[2])
    local last_column = math.max(first[2], last[2])

    for row = math.min(first[1], last[1]), math.max(first[1], last[1]) do
      local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
      local start_column = math.min(first_column, #line)
      local end_column = math.min(last_column + 1, #line)

      vim.api.nvim_buf_set_text(
        bufnr,
        row - 1,
        start_column,
        row - 1,
        end_column,
        { escape(line:sub(start_column + 1, end_column)) }
      )
    end
    return
  end

  local start_row = math.min(first[1], last[1]) - 1
  local end_row = math.max(first[1], last[1]) - 1
  local start_column = first[1] <= last[1] and first[2] or last[2]
  local end_column = first[1] <= last[1] and last[2] or first[2]

  if mode == "V" then
    start_column = 0
    end_column = #vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1]
  elseif vim.o.selection ~= "exclusive" then
    local line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1]
    end_column = vim.str_byteindex(line, vim.str_utfindex(line, end_column) + 1)
  end

  local selection = vim.api.nvim_buf_get_text(
    bufnr,
    start_row,
    start_column,
    end_row,
    end_column,
    {}
  )
  for index, line in ipairs(selection) do
    selection[index] = escape(line)
  end
  vim.api.nvim_buf_set_text(bufnr, start_row, start_column, end_row, end_column, selection)
end

function M.setup(options)
  options = options or {}

  map({ "n", "i", "x" }, "<C-s>", "<Cmd>write<CR>", "Write buffer")
  map("n", "<leader>w", "<Cmd>write<CR>", "Write buffer")
  map("n", "<leader>q", "<Cmd>confirm quit<CR>", "Quit window")
  map("n", "[b", "<Cmd>bprevious<CR>", "Previous buffer")
  map("n", "]b", "<Cmd>bnext<CR>", "Next buffer")
  map("n", "<leader>bb", "<Cmd>bprevious<CR>", "Previous buffer")
  map("n", "<leader>bd", "<Cmd>bdelete<CR>", "Delete buffer")
  map("n", "<Esc>", "<Cmd>nohlsearch<CR>", "Clear search highlight")
  map("n", "j", function()
    return vim.v.count == 0 and "gj" or "j"
  end, "Move down by display line", { expr = true })
  map("n", "k", function()
    return vim.v.count == 0 and "gk" or "k"
  end, "Move up by display line", { expr = true })
  map("x", "p", "P", "Paste without replacing default register")
  map("n", "<leader>hi", "<Cmd>Inspect<CR>", "Inspect highlight captures")
  map("n", "<leader>ht", "<Cmd>InspectTree<CR>", "Inspect Tree-sitter tree")
  map("x", "<leader>ze", escape_markdown_template_syntax, "Escape JavaScript for Markdown template")

  if not options.plugins then
    return
  end

  map("n", "-", "<Cmd>Oil<CR>", "Open parent directory")
  map("n", "<leader>e", function()
    Snacks.explorer()
  end, "File explorer")
  map("n", "<leader>ff", function()
    require("fff").find_files()
  end, "Find files")
  map("n", "<leader>fg", function()
    require("fff").live_grep()
  end, "Live grep")
  map("n", "<leader>zt", function()
    Snacks.picker.colorschemes({ pattern = "argiope-" })
  end, "Argiope themes")
  map("n", "<leader>uC", function()
    Snacks.picker.colorschemes()
  end, "Colorschemes")
  map({ "n", "x" }, "<leader>fw", function()
    require("fff").live_grep_under_cursor()
  end, "Search word or selection")
  map("n", "<leader>fz", function()
    require("fff").live_grep({
      grep = {
        modes = { "fuzzy", "plain" },
      },
    })
  end, "Fuzzy live grep")

  local function select_template(capture)
    return function()
      require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
    end
  end

  local function map_template_textobjects(bufnr)
    local options = { buffer = bufnr }
    map("x", "<leader>zc", function()
      require("argiope").toggle_interpolation_selection(bufnr)
    end, "Toggle template interpolation comment", options)
    map(
      { "x", "o" },
      "i`",
      select_template("@template.inner"),
      "Inside template literal",
      options
    )
    map(
      { "x", "o" },
      "a`",
      select_template("@template.outer"),
      "Around template literal",
      options
    )
  end

  local group = vim.api.nvim_create_augroup("config_template_textobjects", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "javascript",
    callback = function(event)
      map_template_textobjects(event.buf)
    end,
    desc = "Enable multiline JavaScript template text objects",
  })

  if vim.bo.filetype == "javascript" then
    map_template_textobjects(vim.api.nvim_get_current_buf())
  end
end

return M
