-- Copyright (c) 2025 Augment
-- MIT License - See LICENSE.md for full terms

local M = {}

-- Buffer to store the last Augment suggestion for injection into LSP completions
local suggestion_buffer = nil

-- Flag to track if completion injection is set up
local completion_injection_setup = false

-- Start the lsp client
M.start_client = function(command, notification_methods, workspace_folders)
    -- Set up completion injection on first client start
    if not completion_injection_setup then
        M.setup_completion_injection()
        completion_injection_setup = true
    end

    local vim_version = tostring(vim.version())
    local plugin_version = vim.call('augment#version#Version')

    -- Set up noficiation handlers that forward requests to the handlers in the vimscript
    local handlers = {}
    for _, method in ipairs(notification_methods) do
        handlers[method] = function(_, params, _)
            vim.call('augment#client#NvimNotification', method, params)
        end
    end

    -- Custom handler for textDocument/completion for ghost text processing only
    handlers['textDocument/completion'] = function(err, result, ctx)
        -- Forward to VimScript handler for ghost text processing
        -- The suggestion is now managed via suggestion_buffer and injected globally
        vim.call('augment#client#NvimResponse', 'textDocument/completion', ctx.params, result, err)
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

-- Update the suggestion buffer with new Augment suggestion
-- Called from VimScript when a suggestion is received
M.update_suggestion_buffer = function(text, request_id)
    if not text or text == '' then
        suggestion_buffer = nil
        return
    end

    -- Create a completion item with the suggestion
    suggestion_buffer = {
        label = text:sub(1, 100),  -- First 100 chars for label
        insertText = text,
        kind = 1,  -- CompletionItemKind.Text
        sortText = '\0',  -- Sort first (null character sorts before everything)
        data = {
            source = 'augment',
            request_id = request_id,
        },
    }
end

-- Clear the suggestion buffer
M.clear_suggestion_buffer = function()
    suggestion_buffer = nil
end

-- Inject Augment suggestion into LSP completion results
-- This wraps the default completion handler to inject our suggestion
M.setup_completion_injection = function()
    -- Store original handler
    local original_handler = vim.lsp.handlers['textDocument/completion']

    -- Create new handler that injects our suggestion
    vim.lsp.handlers['textDocument/completion'] = function(err, result, ctx, config)
        -- Inject Augment suggestion if available
        if suggestion_buffer and result then
            -- Ensure result is a list
            if type(result) == 'table' and result[1] then
                table.insert(result, 1, suggestion_buffer)
            end
        end

        -- Call original handler with potentially injected results
        if original_handler then
            return original_handler(err, result, ctx, config)
        end
    end
end

return M
