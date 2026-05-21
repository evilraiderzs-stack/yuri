-- {"id":12320,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://https://yuritranslations.wordpress.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-yuritranslations%.wordpress%.com", "")
end