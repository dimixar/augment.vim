-- Copyright (c) 2025 Augment
-- MIT License - See LICENSE.md for full terms

-- blink.cmp source for Augment suggestions
-- This allows Augment suggestions to appear in blink.cmp's completion menu

local M = {}

-- Create a new blink.cmp source instance
M.new = function()
    return setmetatable({}, { __index = M })
end

-- Get completions - called by blink.cmp to fetch suggestions
-- Returns Augment suggestion if available, empty list otherwise
M.get_completions = function(self, context, callback)
    local augment = require('augment')
    local suggestion_buffer = augment.get_suggestion_buffer()

    if suggestion_buffer then
        -- Return Augment suggestion as the only completion
        callback({
            items = { suggestion_buffer },
            isIncomplete = false,
        })
    else
        -- No suggestion available
        callback({
            items = {},
            isIncomplete = false,
        })
    end
end

-- Resolve completion item - called for additional details
-- For Augment, just return the item as-is
M.resolve = function(self, item, callback)
    callback(item)
end

-- Execute completion - called when user accepts the suggestion
-- Insert the suggestion text into the buffer
M.execute = function(self, item, callback)
    local augment = require('augment')

    -- If this is an Augment suggestion, accept it
    if item.data and item.data.source == 'augment' then
        augment.accept()
    end

    callback()
end

return M
