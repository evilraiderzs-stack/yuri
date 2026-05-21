-- {"id":12320,"ver":"0.1.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://https://yuritranslations.wordpress.com"

local WPCommon = Require("WPCommon")

--- @param url string
--- @return string
local function shrinkURL(url)
    return url:gsub("^.-yuritranslations%.wordpress%.com", "")
end

--- @param url string
--- @return string
local function expandURL(url)
    return baseURL .. url
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))
    local content = doc:selectFirst("article")

    if not content then return nil end

    local p = content:selectFirst(".entry-content")
    if not p then return nil end

    WPCommon.cleanupElement(p)
    WPCommon.cleanupPassages(p:children())

    return p
end

local function findListings(doc)
    local menu = doc:selectFirst("ul#menu-primary")
    if not menu then return {} end

    local listings = {}

    map(menu:select("li.menu-item-has-children"), function (section)
        local links = section:selectFirst("ul.sub-menu")
        if not links then return end

        map(links:select("li a"), function (a)
            listings[#listings + 1] = Novel {
                title = a:text(),
                link = shrinkURL(a:attr("href"))
            }
        end)
    end)

    return listings
end

local function parseNovelPage(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))
    local article = doc:selectFirst("article")

    local info = NovelInfo {
        title = article:selectFirst(".entry-title"):text()
    }

    local img = article:selectFirst(".entry-content img")
    if img then
        info:setImageURL(img:attr("src"))
    end

    if loadChapters then
        local chapters = {}

        local links = article:selectFirst(".entry-content")
        if links then
            map(links:select("p a"), function (a)
                local url = a:attr("href")

                -- only keep valid chapter links
                if WPCommon.contains(url, "yuritranslations.wordpress.com") then
                    chapters[#chapters + 1] = NovelChapter {
                        order = #chapters + 1,
                        title = a:text(),
                        link = shrinkURL(url)
                    }
                end
            end)
        end

        info:setChapters(AsList(chapters))
    end

    return info
end

----------------------------------------------------
-- RETURN EXTENSION
----------------------------------------------------

return {
    id = 12320,
    name = "Yuri WordPress",
    baseURL = baseURL,
    imageURL = "https://github.com/noaione/shosetsu-extensions/raw/dev/icons/Tintan.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    listings = {
        Listing("Novels", false, function()
            local doc = GETDocument(baseURL)
            return findListings(doc)
        end)
    },

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,

    parseNovel = function(novelURL, loadChapters)
        return parseNovelPage(novelURL, loadChapters)
    end,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}