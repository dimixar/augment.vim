# !!!!WARNING!!!!
This fork has some modifications in order to make it work well with AstroNvim and its AI community plugin integration.
MOST OF THE CODE WAS SLOPPED TOGETHER BY CLAUDE CODE.
I only made sure that it works, and that the example configurations are correct and working.

## Fork Modifications

### New Lua API for Completion Engine Integration

This fork exposes Augment's suggestion system via Lua functions, allowing seamless integration with completion engines like blink.cmp.

#### Available Functions

**`require('augment').has_suggestion()`**
- Returns `true` if an active Augment ghost text suggestion exists, `false` otherwise
- Useful for checking if a suggestion is available before attempting to accept it

**`require('augment').accept()`**
- Accepts the currently active Augment suggestion if one exists
- Returns `true` if a suggestion was accepted, `false` otherwise
- This is the primary function for integration with external completion engines

**`require('augment').accept_suggestion()`**
- Alias for `accept()` for API clarity

#### Integration with blink.cmp

Augment provides a custom blink.cmp source that makes suggestions appear directly in the completion menu. This is the recommended integration method for AstroNvim.

**Configuration:**

Add the Augment source to your blink.cmp sources in AstroNvim:

```lua
return {
  "Saghen/blink.cmp",
  optional = true,
  opts = {
    sources = {
      default = { "augment", "lsp", "path", "snippets", "buffer" },
      providers = {
        augment = {
          name = "augment",
          module = "blink_source_augment",
          enabled = function()
            return require('augment').get_suggestion_buffer() ~= nil
          end,
        },
      },
    },
  },
}
```

Or more simply using the blink_source factory:

```lua
{
  "Saghen/blink.cmp",
  optional = true,
  opts = function(_, opts)
    if not opts.sources then opts.sources = {} end
    if not opts.sources.default then opts.sources.default = {} end
    if not opts.sources.providers then opts.sources.providers = {} end

    -- Add augment to default sources (before lsp for priority)
    table.insert(opts.sources.default, 1, "augment")

    -- Register the Augment source
    opts.sources.providers.augment = require('augment').blink_source()
  end,
}
```

#### How It Works

- **Ghost Text + Completion Menu**: Augment displays suggestions as inline ghost text while also exposing them to blink.cmp
- **AI-Marked Suggestions**: Each suggestion is clearly prefixed with `[AI]` in the menu
- **Detailed Preview**: View the complete code and explanation in the detail popup
- **Flexible Integration**: The Lua API is completion engine-agnostic, so you can use it with any completion system

#### Suggestion Display

Augment suggestions appear in the completion menu with the `[AI]` prefix, making them easily identifiable. When you hover over or view the suggestion details, you'll see:
- The complete AI-generated code
- A clear label indicating it's an Augment suggestion
- Full context for informed code acceptance

**Features:**
- Clear `[AI]` indicator in the completion menu
- Full code preview in documentation popup
- Works seamlessly with blink.cmp and other LSP-based completion systems
- Ghost text and menu suggestions work together
- No additional configuration required

#### AstroNvim Configuration

> **NOTE:** This fork has been tested and verified to work with AstroNvim, including integration with blink.cmp and the AI accept functionality.

**Example AstroNvim configuration (`~/.config/nvim/lua/plugins/user.lua`):**

```lua
{
  "dimixar/augment.vim",
  lazy = false,
  init = function()
    vim.g.augment_disable_tab_mapping = true
  end,
  opts = {
    autocmds = {
      augment_workspace_setup = {
        event = "VimEnter",
        description = "Sets the current path where nvim was opened as the workspace folder.",
        callback = function()
          vim.g.augment_workspace_folders = {vim.fn.getcwd()}
        end,
      },
    },
  },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = {
        options = {
          g = {
            ai_accept = function()
              local blink = require('blink.cmp')
              if blink.is_menu_visible() then
                return false
              end
              local augment = require('augment')
              if augment.has_suggestion() then
                vim.schedule(function()
                  augment.accept_suggestion()
                end)
                return true
              end
              return false
            end,
          },
        },
      },
    },
    {
      "Saghen/blink.cmp",
      optional = true,
      opts = function(_, opts)
        opts.sources = opts.sources or {}
        opts.sources.default = opts.sources.default or {}
        opts.sources.providers = opts.sources.providers or {}
        table.insert(opts.sources.default, 1, "augment")
        opts.sources.providers.augment = {
          name = "augment",
          module = "blink_source_augment",
        }
        if not opts.keymap then opts.keymap = {} end
        opts.keymap["<Tab>"] = {
          "snippet_forward",
          function()
            if vim.g.ai_accept then
              return vim.g.ai_accept()
            end
          end,
          "select_next",
          "fallback",
        }
        return opts
      end,
    },
  },
}
```

This configuration:
- Integrates with AstroNvim's `ai_accept` hook for seamless ghost text acceptance
- Registers Augment as a blink.cmp source for menu suggestions
- Overrides TAB keymap to support both menu cycling and AI suggestion acceptance

--------------------------
# Augment Vim & Neovim Plugin

## A Quick Tour

Augment's Vim/Neovim plugin provides inline code completions and multi-turn
chat conversations specially tailored to your codebase. The plugin is designed
to work with any modern Vim or Neovim setup, and features the same underlying
context engine that powers our VSCode and IntelliJ plugins.

Once you've installed the plugin, tell Augment about your project by adding
[workspace folders](#workspace-folders) to your config file, and then sign-in
to the Augment service. You can now open a source file in your project, begin
typing, and you should receive context-aware code completions. Use tab to
accept a suggestion, or keep typing to refine the suggestions. To ask questions
about your codebase or request specific changes, use the `:Augment chat` command
to start a chat conversation.

## Getting Started

1. Sign up for a free trial of Augment at
   [augmentcode.com](https://augmentcode.com).

1. Ensure you have a compatible editor version installed. Both Vim and Neovim
   are supported, but the plugin may require a newer version than what is
   installed on your system by default.

   - For [Vim](https://github.com/vim/vim?tab=readme-ov-file#installation),
     version 9.1.0 or newer.

   - For
     [Neovim](https://github.com/neovim/neovim/tree/master?tab=readme-ov-file#install-from-package),
     version 0.10.0 or newer.

1. Install [Node.js](https://nodejs.org/en/download/package-manager/all),
   version 22.0.0 or newer, which is a required dependency.

1. Install the plugin

    - Manual installation (Vim):

        ```bash
        git clone https://github.com/dimixar/augment.vim.git \
            ~/.vim/pack/dimixar/start/augment.vim
        ```

    - Manual installation (Neovim):

        ```bash
        git clone https://github.com/dimixar/augment.vim.git \
            ~/.config/nvim/pack/dimixar/start/augment.vim
        ```

    - Vim Plug:

        ```vim
        Plug 'dimixar/augment.vim'
        ```

    - Lazy.nvim:

        ```lua
        { 'dimixar/augment.vim' },
        ```

1. Add workspace folders to your config file. This is really essential to getting the most out of augment! See the [Workspace Folders](#workspace-folders) section for more information.

1. Open Vim and sign in to Augment with the `:Augment signin` command.

## Basic Usage

Open a file in vim, start typing, and use tab to accept suggestions as they
appear.

The following commands are provided:

```vim
:Augment status        " View the current status of the plugin
:Augment signin        " Start the sign in flow
:Augment signout       " Sign out of Augment
:Augment log           " View the plugin log
:Augment chat          " Send a chat message to Augment AI
:Augment chat-new      " Start a new chat conversation
:Augment chat-toggle   " Toggle the chat panel visibility
```

## Workspace Folders

Workspace folders help Augment understand your codebase better by providing
additional context. Adding your project's root directory as a workspace folder
allows Augment to take advantage of context from across your project, rather
than just the currently open file, improving the accuracy and style of
completions and chat.

You can configure workspace folders by setting
`g:augment_workspace_folders` in your vimrc:

```vim
let g:augment_workspace_folders = ['/path/to/project', '~/another-project']
```

Workspace folders can be specified using absolute paths or paths relative to
your home directory (~). Adding your project's root directory as a workspace
folder helps Augment generate completions that match your codebase's patterns
and conventions.

Note: This option must be set before the plugin is loaded.

After adding a workspace folder and restarting vim, the output of the
`:Augment status` command will include the syncing progress for the added
folder.

If you want to ignore particular files or directories from your workspace, you
can create a `.augmentignore` file in the root of your workspace folder. This
file is treated similar to a `.gitignore` file. For example, to ignore all
files within the `node_modules` directory, you can add
the following lines to your `.augmentignore` file:

```
node_modules/
```

For more information on how to use the `.augmentignore` file, see the [documentation](https://docs.augmentcode.com/setup-augment/sync).


## Chat

Augment chat supports multi-turn conversations using your project's full
context. Once a conversation is started, subsequent chat exchanges will include
the history from the previous exchanges. This is useful for asking follow-up
questions or getting context-specific help.

You can interact with chat in two ways:

1. Direct command with message:

    ```vim
    :Augment chat How do I implement binary search?
    ```

2. With selected text:

   - Select text in visual mode

   - Type `:Augment chat` followed by your question about the selection

The response will appear in a separate chat buffer with markdown formatting.

To start a new conversation, use the `:Augment chat-new` command. This will
clear the chat history from your context.

Use the `:Augment chat-toggle` command to open and close the chat panel. When
the chat panel is closed, the chat conversation will be preserved and can be
reopened with the same command.

## Alternate Keybinds

Tab mapping is **disabled by default**. To enable the default tab mapping for accepting
suggestions, set `g:augment_disable_tab_mapping = v:false` before the plugin is loaded.

To use a different key or create custom mappings, use `augment#Accept()`. The function
takes an optional argument used to specify the fallback text to insert if no
suggestion is available.

```vim
" Enable default tab mapping
let g:augment_disable_tab_mapping = v:false

" Or create a custom mapping with a different key
" Use Ctrl-Y to accept a suggestion
inoremap <c-y> <cmd>call augment#Accept()<cr>

" Use enter to accept a suggestion, falling back to a newline if no suggestion
" is available
inoremap <cr> <cmd>call augment#Accept("\n")<cr>
```

Completions can be disabled entirely by setting
`g:augment_disable_completions = v:true` in your vimrc or at any time during
editing.

If another plugin uses tab in insert mode, the Augment tab mapping may be
overridden depending on the order in which the plugins are loaded. If tab isn't
working for you, the `imap <tab>` command can be used to check if the mapping is
present.

## FAQ

**Q: I'm not seeing any completions. Is the plugin working?**

A: You may want to first check the output of the `:Augment status` command.
This command will show the current status of the plugin, including whether
you're signed in and whether your workspace folders are synced. If you're not
signed in, you'll need to sign in using the `:Augment signin` command. If those
are not indicating a problem, you can check the plugin log using the `:Augment
log` command. This will show any errors that may have occurred.

**Q: Can I create shortcuts for the Augment commands?**

A: Absolutely! You can create mappings for any of the Augment commands. For
example, to create a shortcut for the `:Augment chat*` commands, you can add the
following to your vimrc:

```vim
nnoremap <leader>ac :Augment chat<CR>
vnoremap <leader>ac :Augment chat<CR>
nnoremap <leader>an :Augment chat-new<CR>
nnoremap <leader>at :Augment chat-toggle<CR>
```

**Q: My workspace is taking a long time to sync. What should I do?**

A: It may take a while to sync if you have a very large codebase that has not
been synced before. It's also not uncommon to inadvertenly include a large
directory like `node_modules/`. You can use `:Augment status` to see the
progress of the sync. If the sync is making progress but just slow, it may be
worth checking if you have a large directory that you don't need to sync. You
can add these directories to your `.augmentignore` file to exclude it from the
sync. If you're still having trouble, please file a github issue with a
description of the problem and include the output of `:Augment log`.


## Licensing and Distribution

This repository includes two main components:

1. **Vim Plugin:** This includes all files in the repository except `dist` folder. These files are licensed under the [MIT License](LICENSE.md#vim-plugin).
2. **Server (`dist` folder):** This file is proprietary and licensed under a [Custom Proprietary License](LICENSE.md#server).

For details on usage restrictions, refer to the [LICENSE.md](LICENSE.md) file.

## Reporting Issues

We encourage users to report any bugs or issues directly to us. Please use the [Issues](https://github.com/augmentcode/augment.vim/issues) section of this repository to share your feedback.

For any other questions, feel free to reach out to support@augmentcode.com.
