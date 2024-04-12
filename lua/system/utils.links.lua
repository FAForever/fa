
local validFAForver = {
    "http://forums.faforever.com", -- old FAF forum
    "http://forum.faforever.com",  -- new FAF forum
}
local validRepositories = { 
    "http://github.com",
    "http://gitlab.com",
    "http://bitbucket.org",
    "http://sourceforge.net",
}

local validDomains = table.cat(validFAForver, validRepositories)

-- stores URLs with valid domains
local validatedLinks = {}

--- opens web browser at given URL address, e.g. "http://forum.faforever.com"
function repo(url)
    for _, domain in validRepositories do
        if string.find(url, domain) then
            return true
        end
    end
    return false
end

--- validates if URL has valid domain and auto-converts https to http
function validate(url)
    if url and type(url) == 'string' then
        -- check if we already validated the URL
        if validatedLinks[url] then 
            return validatedLinks[url]
        end

        if string.find(url, 'www.') or string.find(url, 'http') then
            -- auto-convert 'https' to 'http'
            local link = string.gsub(url, "https", "http", 1)  
            local linkHasValidDomain = false
            for _, domain in validDomains do
                if string.find(link, domain) then
                    linkHasValidDomain = true
                    break -- stop on first valid domain
                end 
            end
            -- cache validated link
            if linkHasValidDomain then
               validatedLinks[url] = link
               return link
            end
        end

    end
    return false
end

--- opens web browser at given URL address, e.g. "http://forum.faforever.com"
--- @param url string representing the URL
--- @param parent Layoutable optional parent for the open URL dialog, defaults to GetFrame(0)
function open(url, parent)
    local validLink = validate(url)
    if validLink then
        OpenURL(validLink, parent)
        return true
    end
    return false
end