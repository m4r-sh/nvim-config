# Personal Neovim configuration

This directory is a portable daily Neovim configuration. Move it to
`~/.config/nvim`, start Neovim normally, and `vim.pack` will install the
configured plugins into Neovim's standard data directory.

The first startup installs plugins and the required Tree-sitter parser/query
packages. Later startups reuse the lockfile and installed packages.

## Requirements

- Neovim 0.12+
- Git and curl
- Tree-sitter CLI 0.26.1+

## Included plugins

- `m4r-sh/argiope.nvim` for JavaScript tagged-template highlighting, indentation, and the Argiope colorscheme
- `mini.icons` for filetype-aware icons in Snacks Explorer and other pickers
- the current nvim-treesitter parser registry and runtime
- Snacks Explorer on `<leader>e`
- `oil.nvim` on `-` for editable directory buffers
- `fff.nvim` for file finding and live grep
- `nvim-surround`
- `nvim-treesitter-textobjects` with multiline template-literal text objects

Argiope follows the repository's default branch so this config works before
the first release tag. During local plugin development, `ARGIOPE_NVIM_SOURCE`
can point at another Git URI; for example:

```sh
ARGIOPE_NVIM_SOURCE=file:///absolute/path/to/argiope.nvim nvim
```

The override still installs Argiope through `vim.pack`; it does not inject the
working tree directly into `runtimepath`.

---

# Keymaps

`<leader>` is `<Space>`.

## Daily essentials

| Keys | Action |
| --- | --- |
| `<C-s>` | Write the current buffer in normal, insert, or visual mode |
| `<Space>w` | Write the current buffer |
| `<Space>q` | Quit the current window, prompting for unsaved changes |
| `[b` / `]b` | Previous / next buffer |
| `<Space>bd` | Delete the current buffer |
| `<Esc>` | Clear search highlighting |
| `<Space>zt` | Toggle JavaScript between monochrome and Dracula syntax colors |
| `<Space>zc` in Visual mode | Toggle the selected template text as an empty-interpolation comment |

Picker-local mappings take precedence while a picker is focused, so `<C-s>`
continues to mean “open in a horizontal split” inside fff and Snacks.

## Files

| Keys | Action |
| --- | --- |
| `<Space>e` | Open the Snacks tree explorer |
| `-` | Open the current file's parent directory in Oil |

Useful Snacks Explorer keys:

| Keys | Action |
| --- | --- |
| `<CR>` / `l` | Open a file or toggle a directory |
| `h` | Close a directory |
| `<BS>` | Go to the parent directory |
| `a` | Add a file or directory |
| `r` | Rename |
| `d` | Delete |
| `H` | Toggle hidden files |
| `I` | Toggle ignored files |
| `u` | Refresh |

Snacks shows `?` for Git-untracked files. The explorer keeps that status
indicator visible without dimming the entire filename, and `mini.icons`
provides filetype-specific icons.

Oil buffers remain editable directories: rename, create, move, or delete
entries by editing lines, then use `:write` to apply the changes.

## Search with fff

| Keys | Action |
| --- | --- |
| `<Space>ff` | Find files in the current project |
| `<Space>fg` | Search file contents |
| `<Space>fw` | Search the word under the cursor or visual selection |
| `<Space>fz` | Search file contents in fuzzy/plain mode |

Inside an fff picker:

| Keys | Action |
| --- | --- |
| `<CR>` | Open selection |
| `<Esc>` | Close picker |
| `<C-n>` / `<C-p>` | Move down / up |
| `<C-s>` | Open in a horizontal split |
| `<C-v>` | Open in a vertical split |
| `<C-t>` | Open in a tab |
| `<C-q>` | Send results to the quickfix list |
| `<S-Tab>` | Cycle grep modes |

## Surrounds and templates

| Keys | Example |
| --- | --- |
| `ys{motion}{char}` | `ysiw)` wraps a word as `(word)` |
| `ds{char}` | `ds]` removes surrounding brackets |
| `cs{old}{new}` | `cs'"` changes single quotes to double quotes |
| `dst` | Remove the surrounding HTML tag |
| `S{char}` in visual mode | Surround the selection |
| `` vi` `` / `` va` `` | Select inside / around a JavaScript template literal |
| `` di` `` / `` da` `` | Delete inside / around a JavaScript template literal |

The backtick text objects are Tree-sitter-aware and work across lines.
In a JavaScript template, visually select text and press `<Space>zc` to wrap
that exact range as `${''/* ... */}`. Characterwise selections can cover part
of one line or span lines; Visual Line mode continues to wrap each selected
line. Selecting exactly `value` inside `${value}`, or the whole
interpolation, changes it to `${''/* value */}` instead of nesting another
interpolation.

## Inspection and maintenance

| Keys | Action |
| --- | --- |
| `<Space>hi` | Inspect Tree-sitter captures under the cursor |
| `<Space>ht` | Open the Tree-sitter syntax tree |

- `:packupdate` reviews plugin updates.
- `:FFFHealth` checks fff and its native binary.
- `:checkhealth argiope` checks Argiope.
- `:checkhealth snacks` checks Snacks Explorer.
