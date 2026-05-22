-- {"id":12321,"ver":"0.4.0","libVer":"1.0.0","author":"N4O","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://dragontl.net"
local WPCommon = Require("WPCommon")

-------------------------------------------------
-- URL helpers
-------------------------------------------------
local function shrinkURL(url)
    return url:gsub("^https?://dragontl%.net", "")
end

local function expandURL(url)
    if url:find("^https?://") then
        return url
    end
    return baseURL .. url
end

-------------------------------------------------
-- Clean image URLs
-------------------------------------------------
local function cleanImgUrl(url)
    if not url then return url end
    return url:gsub("%?%w+=.+", "")
end

-------------------------------------------------
-- Parse chapter page
-------------------------------------------------
local function parsePage(url)
    local doc = GETDocument(expandURL(url))

    local content = doc:selectFirst(".mbs_posts_text")
    if not content then return nil end

    WPCommon.cleanupElement(content)
    WPCommon.cleanupPassages(content:children())

    return content
end

-------------------------------------------------
-- Get passage text
-------------------------------------------------
local function getPassage(url)
    local p = parsePage(url)
    if not p then return "" end
    return pageOfElem(p)
end

-------------------------------------------------
-- Extract novel list from sidebar
-------------------------------------------------
local function getNovelList(doc)
    local list = {}

    local sidebar = doc:selectFirst("#mbds_story_widget-3")
    if not sidebar then return list end

    local links = sidebar:select("ul.mbs_story_widget_list li a")

    map(links, function(v)
        list[#list + 1] = Novel {
            title = v:text(),
            link = shrinkURL(v:attr("href"))
        }
    end)

    return list
end

-------------------------------------------------
-- Parse novel info + chapters
-------------------------------------------------
local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    local info = NovelInfo {}

    -- Title
    local titleNode = doc:selectFirst("h1, h2, title")
    if titleNode then
        local title = titleNode:text()
        title = title:gsub(" | Dragon TL", "")
        info:setTitle(title)
    else
        info:setTitle("Unknown Title")
    end

    -- Cover image (if any)
    local img = doc:selectFirst("article img, .mbs_posts_text img")
    if img then
        info:setImageURL(cleanImgUrl(img:attr("src")))
    end

    -------------------------------------------------
    -- Chapters (Table of Contents page)
    -------------------------------------------------
    if loadChapters then
        local chapters = {}

        local toc = doc:selectFirst("#table-of-contents")
        if toc then
            local links = toc:select("a[href]")

            map(links, function(v)
                local url = v:attr("href")

                chapters[#chapters + 1] = NovelChapter {
                    title = v:text(),
                    link = shrinkURL(url),
                    order = #chapters + 1
                }
            end)
        end

        info:setChapters(AsList(chapters))
    end

    return info
end

-------------------------------------------------
-- Listings (homepage sidebar novels)
-------------------------------------------------
local function listings()
    local doc = GETDocument(baseURL)
    return getNovelList(doc)
end

-------------------------------------------------
-- Return module
-------------------------------------------------
return {
    id = 12321,
    name = "Dragon TL",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Tintan.png",
    hasSearch = false,
    lang = "en",
    chapterType = ChapterType.HTML,

    listings = {
        Listing("Novels", false, listings)
    },

    parseNovel = parseNovel,
    getPassage = getPassage,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}