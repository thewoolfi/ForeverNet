local _, F = ...
F.Codec = {}
-- Length-prefixed values, never loadstring. Deterministic table encoding.
function F.Codec.Encode(value)
    local function encode(v, depth)
        assert(depth <= 12, 'depth')
        local t = type(v)
        if t == 'string' then return 's' .. #v .. ':' .. v end
        if t == 'number' then assert(F.Integer(v, 0, 2147483647), 'number'); return 'n' .. v .. ':' end
        if t == 'boolean' then return v and 't' or 'f' end
        assert(t == 'table', 'type')
        local keys, out = F.Keys(v), {}
        out[1] = 'm' .. #keys .. ':'
        for _, key in ipairs(keys) do
            assert(type(key) == 'string', 'key')
            out[#out + 1] = encode(key, depth + 1); out[#out + 1] = encode(v[key], depth + 1)
        end
        return table.concat(out)
    end
    local s = encode(value, 0); assert(#s <= 96000, 'size'); return s
end
function F.Codec.Decode(s)
    if type(s) ~= 'string' or #s > 96000 then return nil end
    local pos, budget = 1, 0
    local function number()
        local stop = s:find(':', pos, true); assert(stop and stop - pos <= 10, 'length')
        local digits = s:sub(pos, stop - 1); assert(digits:match('^%d+$'), 'digits')
        pos = stop + 1; return tonumber(digits)
    end
    local function decode(depth)
        budget = budget + 1; assert(budget <= 30000 and depth <= 12, 'budget')
        local tag = s:sub(pos, pos); pos = pos + 1
        if tag == 't' then return true elseif tag == 'f' then return false end
        if tag == 'n' then local n = number(); assert(F.Integer(n, 0, 2147483647)); return n end
        if tag == 's' then
            local len = number(); assert(len <= 96000 and pos + len - 1 <= #s, 'string')
            local v = s:sub(pos, pos + len - 1); pos = pos + len; return v
        end
        assert(tag == 'm', 'tag'); local n, out = number(), {}; assert(n <= 2000, 'table')
        for i = 1, n do
            local key = decode(depth + 1); assert(type(key) == 'string' and out[key] == nil, 'key')
            out[key] = decode(depth + 1)
        end
        return out
    end
    local ok, result = pcall(decode, 0)
    if ok and pos == #s + 1 then return result end
end
