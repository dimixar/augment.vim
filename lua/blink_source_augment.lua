-- Copyright (c) 2025 Augment
-- MIT License - See LICENSE.md for full terms

-- blink.cmp source for Augment suggestions
-- This allows Augment suggestions to appear in blink.cmp's completion menu

local M = {}

-- Create a new blink.cmp source instance
M.new = function()
    return setmetatable({}, { __index = M })
end

-- Check if source is enabled
-- Returns true if Augment has a suggestion available
M.enabled = function(self)
    local augment = require('augment')
    local has_suggestion = augment.get_suggestion_buffer() ~= nil
    vim.call('augment#log#Info', '[blink-augment] enabled() called, has_suggestion=' .. tostring(has_suggestion))
    return has_suggestion
end

-- Get trigger characters - empty means trigger on any keyword change
M.get_trigger_characters = function(self)
    vim.call('augment#log#Info', '[blink-augment] get_trigger_characters() called')
    return {}
end

-- Get completions - called by blink.cmp to fetch suggestions
-- Returns Augment suggestion if available, empty list otherwise
M.get_completions = function(self, ctx, callback)
    local augment = require('augment')
    local suggestion_buffer = augment.get_suggestion_buffer()

    vim.call('augment#log#Info', '[blink-augment] get_completions() called, has_suggestion=' .. tostring(suggestion_buffer ~= nil))

    if suggestion_buffer then
        -- Return Augment suggestion as the only completion
        vim.call('augment#log#Info', '[blink-augment] returning 1 item: ' .. (suggestion_buffer.label or 'no-label'))
        callback({
            is_incomplete_forward = true,
            is_incomplete_backward = false,
            items = { suggestion_buffer },
        })
    else
        -- No suggestion available
        vim.call('augment#log#Info', '[blink-augment] returning 0 items')
        callback({
            is_incomplete_forward = true,
            is_incomplete_backward = false,
            items = {},
        })
    end

    -- Return cancellation function (no-op for Augment since we're synchronous)
    return function() end
end

-- Resolve completion item - called for additional details
-- For Augment, just return the item as-is
M.resolve = function(self, item, callback)
    vim.call('augment#log#Info', '[blink-augment] resolve() called')
    callback(item)
end

-- Execute completion - called when user accepts the suggestion
-- blink.cmp will use insertText from the item, so we just need to track acceptance
M.execute = function(self, item, callback)
    local augment = require('augment')

    -- If this is an Augment suggestion, notify that it was accepted
    if item.data and item.data.source == 'augment' then
        vim.call('augment#log#Info', '[blink-augment] execute() called for Augment suggestion: ' .. (item.label or 'no-label'))
        -- Let augment know the suggestion was accepted (for analytics/telemetry)
        -- The actual text insertion is handled by blink.cmp via insertText
    else
        vim.call('augment#log#Info', '[blink-augment] execute() called but not an Augment item')
    end

    callback()
end

return M
