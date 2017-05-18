local keys = {'globals', 'endglobals', 'constant', 'native', 'array', 'and', 'or', 'not', 'type', 'extends', 'function', 'endfunction', 'nothing', 'takes', 'returns', 'call', 'set', 'return', 'if', 'endif', 'elseif', 'else', 'loop', 'endloop', 'exitwhen'}
local key_list = {}
for _, key in ipairs(keys) do
    key_list[key] = true
end

local mt = {}
mt.__index = mt

local function find_char(self, current, is_head, is_tail)
    if not current then
        current = 0
    end
    for i = current + 1, #self.char_list do
        local char = self.char_list[i]
        if (is_head or is_tail) and char == '_' then
            goto CONTINUE
        end
        if is_head and char == self.confuse_head then
            goto CONTINUE
        end
        if is_head and not char:find '%a' then
            goto CONTINUE
        end
        do return i, char end
        :: CONTINUE ::
    end
    return nil
end

local function find_new_name(self)
    for i = 1, #self.confuse_bytes + 1 do
        local byte, char = find_char(self, self.confuse_bytes[i], i >= #self.confuse_bytes, i == 1)
        if byte then
            self.confuse_bytes[i] = byte
            self.confuse_chars[i] = char
            break
        else
            self.confuse_bytes[i], self.confuse_chars[i] = find_char(self, 0, i >= #self.confuse_bytes, i == 1)
        end
    end
    return string.reverse(table.concat(self.confuse_chars))
end

local function find_usable_name(self)
    while true do
        local new_name = find_new_name(self)
        if not key_list[new_name] and (not self.can_use or self:can_use(new_name)) then
            return new_name
        end
    end
end

function mt:head(name)
    if not self.head_list[name] then
        self.head_list[name] = self.confuse_head .. find_usable_name(self)
    end
    return self.head_list[name]
end

function mt:__call(name)
    if not self.name_list[name] then
        self.name_list[name] = find_usable_name(self)
    end
    return self.name_list[name]
end

return function (confusion)
    if not confusion then
        return false, '没有定义字符'
    end
    local chars = {}
    for char in confusion:gmatch '%a' do
        chars[#chars+1] = char
    end
    if #chars < 2 then
        return false, '至少要有2个字母'
    end
    local self = setmetatable({}, mt)
    self.char_list = {}
    self.name_list = {}
    self.head_list = {}
    self.confuse_bytes = {}
    self.confuse_chars = {}
    for char in confusion:gmatch '[%w_]' do
        self.char_list[#self.char_list+1] = char
    end
    self.confuse_head = chars[1]
    return self
end
