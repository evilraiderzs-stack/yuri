-- {"id":14444,"ver":"0.4.0","libVer":"1.0.0","author":"YourName","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://baihetales.wordpress.com"
local WPCommon = Require("WPCommon")

----------------------------------------------------
-- URL HELPERS
----------------------------------------------------

local function shrinkURL(url)
    return url:gsub("^https?://baihetales%.wordpress%.com", "")
end

local function expandURL(url)
    if url:find("^https?://") then
        return url
    end
    return baseURL .. url
end

----------------------------------------------------
-- IMAGE CLEANUP
----------------------------------------------------

local function cleanImg(url)
    if not url then return nil end
    return url:gsub("%?.+$", "")
end

----------------------------------------------------
-- PAGE PARSER (CHAPTER CONTENT)
----------------------------------------------------

local function parsePage(url)
    local doc = GETDocument(expandURL(url))

    local content =
        doc:selectFirst(".entry-content")
        or doc:selectFirst(".wp-block-post-content")

    if not content then
        return nil
    end

    -- cut footer / ads / navigation
    local sep = content:selectFirst("hr.wp-block-separator")

    if sep then
        local node = sep
        while node do
            local nextNode = node:nextElementSibling()
            node:remove()
            node = nextNode
        end
    end

    content:select("script"):remove()
    content:select("iframe"):remove()
    content:select("style"):remove()

    WPCommon.cleanupElement(content)
    WPCommon.cleanupPassages(content:children())

    return content
end

local function getPassage(url)
    local page = parsePage(url)
    if not page then return "" end
    return pageOfElem(page)
end

----------------------------------------------------
-- NOVEL LIST
----------------------------------------------------

local function getNovelList(doc)
    local novels = {}

    local posts = doc:select("li.wp-block-post")

    map(posts, function(v)
        local titleNode = v:selectFirst("h3.wp-block-post-title a")
        if not titleNode then return end

        novels[#novels + 1] = Novel {
            title = titleNode:text(),
            link = shrinkURL(titleNode:attr("href"))
        }
    end)

    return novels
end

local function listings()
    local doc = GETDocument(baseURL)
    return getNovelList(doc)
end

----------------------------------------------------
-- NOVEL + CHAPTERS (FIXED PAGINATION)
----------------------------------------------------

local function parseNovel(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    local info = NovelInfo {}

    ------------------------------------------------
    -- TITLE
    ------------------------------------------------

    local titleNode =
        doc:selectFirst("h1.entry-title")
        or doc:selectFirst("h1")

    if titleNode then
        info:setTitle(titleNode:text())
    else
        info:setTitle("Unknown Title")
    end

    ------------------------------------------------
    -- COVER IMAGE
    ------------------------------------------------

    local img =
        doc:selectFirst(".wp-block-post-featured-image img")
        or doc:selectFirst("img.wp-post-image")
        or doc:selectFirst(".entry-content img")

    if img then
        info:setImageURL(cleanImg(img:attr("src")))
    end

    ------------------------------------------------
    -- CHAPTERS (PAGINATION FIX)
    ------------------------------------------------

    if loadChapters then

        local chapters = {}
        local order = 1
        local nextURL = expandURL(novelURL)

        while nextURL do

            local pageDoc = GETDocument(nextURL)

            local links = pageDoc:select(
                "ul.wp-block-post-template h6.wp-block-post-title a"
            )

            map(links, function(v)
                chapters[#chapters + 1] = NovelChapter {
                    title = v:text(),
                    link = shrinkURL(v:attr("href")),
                    order = order
                }
                order = order + 1
            end)

            -- find "Next Page"
            local nextBtn = pageDoc:selectFirst("a.wp-block-query-pagination-next")

            if nextBtn then
                nextURL = expandURL(nextBtn:attr("href"))
            else
                nextURL = nil
            end
        end

        info:setChapters(AsList(chapters))
    end

    return info
end

----------------------------------------------------
-- EXPORT
----------------------------------------------------

return {
    id = 14444,
    name = "Baihe Tales",
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