local _, VG = ...

function VG:SafeCall(label, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then self:Error(label .. ": " .. tostring(result)) end
    return ok, result
end

function VG:CopyTable(source)
    local copy = {}
    for key, value in pairs(source or {}) do copy[key] = value end
    return copy
end

function VG:FormatCoordinates(x, y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return string.format("%.1f, %.1f", x * 100, y * 100)
end
