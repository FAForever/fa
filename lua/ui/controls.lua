local controls = {}

function Get(key)
    if not key then
        key = debug.getinfo(2, "S").source
    end

    controls[key] = controls[key] or {}
    return controls[key]
end
