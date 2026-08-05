local M = {}
local supertab_enabled = false
local completion_trigger_characters =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$"
local signature_group =
  vim.api.nvim_create_augroup("config_javascript_signature_help", { clear = true })

local function configure_completion(client, bufnr)
  -- Recreate the completion handle so changing autotrigger takes effect.
  vim.lsp.completion.enable(false, client.id, bufnr)
  vim.lsp.completion.enable(true, client.id, bufnr, {
    autotrigger = supertab_enabled,
  })
end

local function close_signature_help(bufnr)
  local win = vim.b[bufnr].lsp_floating_preview
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local is_signature_help =
    pcall(vim.api.nvim_win_get_var, win, "textDocument/signatureHelp")
  if is_signature_help then
    vim.api.nvim_win_close(win, true)
  end
end

local function show_signature_help(bufnr)
  if not supertab_enabled then
    return
  end

  vim.schedule(function()
    if
      vim.api.nvim_buf_is_valid(bufnr)
      and vim.api.nvim_get_current_buf() == bufnr
      and vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
    then
      vim.lsp.buf.signature_help({
        bufnr = bufnr,
        close_events = { "BufHidden", "InsertLeave" },
        focusable = false,
        silent = true,
      })
    end
  end)
end

local function has_words_before()
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col == 0 then
    return false
  end
  return vim.api.nvim_get_current_line():sub(col, col):match("%s") == nil
end

local function toggle_supertab()
  supertab_enabled = not supertab_enabled

  for _, client in ipairs(vim.lsp.get_clients({ name = "javascript" })) do
    for bufnr in pairs(client.attached_buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        configure_completion(client, bufnr)
        if not supertab_enabled then
          close_signature_help(bufnr)
        end
      end
    end
  end

  if not supertab_enabled and vim.fn.pumvisible() == 1 then
    local close_menu = vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
    vim.api.nvim_feedkeys(close_menu, "n", false)
  end

  vim.notify(
    "JavaScript SuperTab " .. (supertab_enabled and "enabled" or "disabled")
  )
end

local function tab_action()
  if not supertab_enabled then
    return "<Tab>"
  end
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end
  if vim.snippet.active({ direction = 1 }) then
    return "<Cmd>lua vim.snippet.jump(1)<CR>"
  end
  if has_words_before() then
    return "<C-x><C-o>"
  end
  return "<Tab>"
end

local function shift_tab_action()
  if not supertab_enabled then
    return "<S-Tab>"
  end
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  end
  if vim.snippet.active({ direction = -1 }) then
    return "<Cmd>lua vim.snippet.jump(-1)<CR>"
  end
  return "<S-Tab>"
end

local function on_init(client)
  -- Keep Tree-sitter and the normal buffer options in charge of presentation
  -- and editing behavior.
  client.server_capabilities.semanticTokensProvider = nil
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false

  local completion = client.server_capabilities.completionProvider
  if completion then
    completion.triggerCharacters = completion.triggerCharacters or {}
    local existing = {}
    for _, char in ipairs(completion.triggerCharacters) do
      existing[char] = true
    end
    for char in completion_trigger_characters:gmatch(".") do
      if not existing[char] then
        table.insert(completion.triggerCharacters, char)
      end
    end
  end
end

local function on_attach(client, bufnr)
  vim.diagnostic.enable(false, { bufnr = bufnr })
  configure_completion(client, bufnr)

  vim.api.nvim_clear_autocmds({ group = signature_group, buffer = bufnr })
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = signature_group,
    buffer = bufnr,
    callback = function()
      local triggers =
        vim.tbl_get(client.server_capabilities, "signatureHelpProvider", "triggerCharacters")
          or {}
      if vim.tbl_contains(triggers, vim.v.char) then
        show_signature_help(bufnr)
      end
    end,
    desc = "Show JavaScript signature help while SuperTab is enabled",
  })
  vim.api.nvim_create_autocmd("CompleteDone", {
    group = signature_group,
    buffer = bufnr,
    callback = function()
      show_signature_help(bufnr)
    end,
    desc = "Show JavaScript signature help after completion",
  })

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
    buffer = bufnr,
    desc = "Go to definition",
    silent = true,
  })
  vim.keymap.set("i", "<C-l>", toggle_supertab, {
    buffer = bufnr,
    desc = "Toggle JavaScript SuperTab",
    silent = true,
  })
  vim.keymap.set("i", "<Tab>", tab_action, {
    buffer = bufnr,
    desc = "SuperTab forward",
    expr = true,
    silent = true,
  })
  vim.keymap.set("i", "<S-Tab>", shift_tab_action, {
    buffer = bufnr,
    desc = "SuperTab backward",
    expr = true,
    silent = true,
  })
end

function M.setup()
  if vim.fn.executable("typescript-language-server") ~= 1 then
    vim.notify(
      "JavaScript LSP is unavailable: install typescript-language-server and typescript",
      vim.log.levels.WARN
    )
    return
  end

  vim.opt.completeopt:append({ "menuone", "noselect" })

  vim.lsp.config("javascript", {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact" },
    root_markers = { "jsconfig.json", "package.json", ".git" },
    on_init = on_init,
    on_attach = on_attach,
    settings = {
      completions = {
        completeFunctionCalls = true,
      },
    },
  })
  vim.lsp.enable("javascript")
end

return M
