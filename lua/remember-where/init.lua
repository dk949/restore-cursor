---@class IgnorePatterns
---@field ignore {filetype_patterns:string[],filename_patterns: string[]}

---@class OnlyPatterns
---@field only {filetype_patterns:string[],filename_patterns: string[]}

---@class OverrideIgnorePatterns
---@field override_ignore {filetype_patterns:string[],filename_patterns: string[]}

---@alias Patterns IgnorePatterns|OnlyPatterns|OverrideIgnorePatterns|{}

---@class Options
---@field pat Patterns?            @ Which files to ignore/not ignore
---@field event (string|string[])? @ Which event should the restore trigger on (BufReadPost by default)
---@field cb_pre (fun(): nil)?     @ callback to execute before restoring. Not executed if the buffer is not restored
---@field cb_post (fun(): nil)?    @ callback to execute after restoring. Not executed if the buffer is not restored

---return a valid pattern object or throw an error
---@param pat any
local function typeCheckPattern(pat)
    if pat == nil then return {} end
    local errmsg =
    [[Patterns should have either no fields or one of 'ignore', 'only' or 'override_ignore'.

The field should be a table and should contain at most two fields:
    'filetype_patterns' and 'filename_patterns'

Both of those, if present, should be lists of strings]]

    if vim.tbl_count(pat) == 0 then return pat end
    if vim.tbl_count(pat) ~= 1 then error(errmsg, 2) end
    if not (type(pat.ignore) == 'table'
            or type(pat.only) == 'table'
            or type(pat.override_ignore) == 'table') then
        error(errmsg, 2)
    end
    local inner = pat.ignore or pat.only or pat.override_ignore
    if vim.tbl_count(inner) == 0 then return pat end
    if vim.tbl_count(inner) > 2 then error(errmsg, 2) end
    for field, value in pairs(inner) do
        if not (field == "filetype_patterns" or field == "filename_patterns") then error(errmsg, 2) end
        if not vim.islist(value) then error(errmsg, 2) end
        for _, str in ipairs(value) do
            if type(str) ~= 'string' then error(errmsg, 2) end
        end
    end
    return pat
end

local default_patterns = {
    override_ignore = {
        filetype_patterns = { "commit", "^xxd$", "^gitrebase$" },
        filename_patterns = {},
    }
}

---@type Options
local default_optiosn = {
    pat = default_patterns,
    event = "BufReadPost",
    cb_pre = nil,
    cb_post = nil,
}

---@param str string
---@param patterns Pattern[]
local function matchAny(str, patterns)
    if not patterns then return false end
    for _, pat in ipairs(patterns) do
        if vim.fn.match(str, pat) ~= -1 then return true end
    end
    return false
end

---@param filename string
---@param filetype string
---@param pat {filename_patterns:string[], filetype_patterns:string[]}
---@return boolean
local function patternMatches(filename, filetype, pat)
    if matchAny(filename, pat.filename_patterns) then return true end
    if matchAny(filetype, pat.filetype_patterns) then return true end
    return false
end

---Does current buffer match the pattern
---@param filename string
---@param filetype string
---@param pat Patterns
---@return boolean
local function bufMatches(filename, filetype, pat)
    if pat.only then
        return patternMatches(filename, filetype, pat.only)
    end
    if pat.ignore and patternMatches(filename, filetype, pat.ignore) then
        return false
    end
    return not patternMatches(filename, filetype, pat.override_ignore)
end


local function shouldRun()
    if vim.g.remember_where_disable then
        if vim.g.remember_where_enable_next then
            vim.g.remember_where_enable_next = false
            return true
        end
        return false
    end
    if vim.g.remember_where_disable_next then
        vim.g.remember_where_disable_next = false
        return false
    end
    return true
end


---@param opt Options
return function(opt)
    if not opt then opt = {} end
    ---@type Options
    opt = vim.tbl_deep_extend("keep", opt, default_optiosn)
    if opt.pat.only then opt.pat.override_ignore = nil end
    opt.pat = vim.tbl_deep_extend("keep", typeCheckPattern(opt.pat), default_patterns)

    local M = {}

    local function remember(ev)
        if not shouldRun() then return end
        if not bufMatches(ev.file, vim.bo.filetype, opt.pat) then return end
        local line = vim.fn.line("'\"")
        if line < 1 or line > vim.fn.line("$") then return end
        if opt.cb_pre then opt.cb_pre() end
        vim.api.nvim_feedkeys('g`"', "n", false)
        if opt.cb_post then opt.cb_post() end
    end

    function M.installHandler()
        M.group = vim.api.nvim_create_augroup("remember_where_group", { clear = true })
        M.autocmd = vim.api.nvim_create_autocmd(opt.event, {
            group = M.group,
            callback = remember,
            desc = [[When file is opened, jump to the last position of the cursor]],
        })
    end

    return M
end
