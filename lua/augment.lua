-- Copyright (c) 2025 Augment
-- MIT License - See LICENSE.md for full terms

local M = {}

-- Start the lsp client
M.start_client = function(command, notification_methods, workspace_folders)
    local vim_version = tostring(vim.version())
    local plugin_version = vim.call('augment#version#Version')

    -- Set up noficiation handlers that forward requests to the handlers in the vimscript
    local handlers = {}
    for _, method in ipairs(notification_methods) do
        handlers[method] = function(_, params, _)
            vim.call('augment#client#NvimNotification', method, params)
        end
    end

    -- Custom handler for textDocument/completion to transform items before blink.cmp sees them
    handlers['textDocument/completion'] = function(err, result, ctx)
        -- Transform completion items so blink.cmp shows code instead of GUIDs
        if result then
            for _, item in ipairs(result) do
                -- Server sends: label=GUID (request ID), insertText=code suggestion
                -- Swap them so completion engines display the actual code
                if item.label and item.insertText then
                    local temp = item.label
                    item.label = item.insertText  -- Show code in completion menu
                    item.data = temp  -- Store GUID in data field for request tracking
                end
            end
        end
        -- Forward to VimScript handler for ghost text processing
        vim.call('augment#client#NvimResponse', 'textDocument/completion', ctx.params, result, err)
        return result  -- Return transformed result to LSP client for broadcasting
    end

    local config = {
        name = 'Augment Server',
        cmd = command,
        init_options = {
            editor = 'nvim',
            vimVersion = vim_version,
            pluginVersion = plugin_version,
        },
        on_exit = function(code, signal, client_id)
            -- We can not call vim functions directly from callback functions.
            -- Instead, we schedule the functions for async execution
            vim.schedule(function()
                vim.call('augment#client#NvimOnExit', code, signal, client_id)
            end)
        end,
        handlers = handlers,
        -- TODO(mpauly): on_error
    }

    -- If workspace folders are provided, use them
    if workspace_folders and #workspace_folders > 0 then
        config.workspace_folders = workspace_folders
    end

    local id = vim.lsp.start_client(config)
    return id
end

-- Attach the lsp client to a buffer
M.open_buffer = function(client_id, bufnr)
    vim.lsp.buf_attach_client(bufnr, client_id)
end

-- Send a lsp notification
M.notify = function(client_id, method, params)
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        vim.call('augment#log#Error', 'No lsp client found for id: ' .. client_id)
        return
    end

    client.notify(method, params)
end

-- Send a lsp request
M.request = function(client_id, method, params)
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        vim.call('augment#log#Error', 'No lsp client found for id: ' .. client_id)
        return
    end

    local _, id = client.request(method, params, function(err, result)
        vim.call('augment#client#NvimResponse', method, params, result, err)
    end)
    return id
end

-- Check if there is an active suggestion
M.has_suggestion = function()
    return vim.fn.exists('b:_augment_suggestion') == 1
end

-- Accept the currently active suggestion if one is available
-- Returns true if a suggestion was accepted, false otherwise
M.accept = function()
    return vim.call('augment#suggestion#Accept')
end

-- Alias for accept() for API clarity
M.accept_suggestion = M.accept

return M
