-- {"id":14444,"ver":"0.3.0","libVer":"1.0.0","author":"YourName","dep":["WPCommon>=1.0.0"]}

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
    if not url then
        return nil
    end

    return url:gsub("%?.+$", "")
end


------------------------------------------------
-- CHAPTERS
------------------------------------------------

if loadChapters then

    local chapters = {}
    local order = 1
    local pageNum = 1

    while true do

        local pageURL

        if pageNum == 1 then
            pageURL = expandURL(novelURL)
        else
            pageURL =
                expandURL(novelURL)
                .. "?query-4-page="
                .. pageNum
                .. "&cst"
        end

        local pageDoc = GETDocument(pageURL)

        local links =
            pageDoc:select(
                "ul.wp-block-post-template h6.wp-block-post-title a"
            )

        if links:size() == 0 then
            break
        end

        map(links, function(v)

            chapters[#chapters + 1] = NovelChapter {
                title = v:text(),
                link = shrinkURL(v:attr("href")),
                order = order
            }

            order = order + 1

        end)

        pageNum = pageNum + 1
    end

    info:setChapters(AsList(chapters))
end

----------------------------------------------------
-- NOVEL LIST
----------------------------------------------------

local function getNovelList(doc)
    local novels = {}

    local posts = doc:select("li.wp-block-post")

    map(posts, function(v)

        local titleNode =
            v:selectFirst("h3.wp-block-post-title a")

        if not titleNode then
            return
        end

        novels[#novels + 1] = Novel {
            title = titleNode:text(),
            link = shrinkURL(titleNode:attr("href"))
        }

    end)

    return novels
end

----------------------------------------------------
-- LISTINGS
----------------------------------------------------

local function listings()
    local doc = GETDocument(baseURL)
    return getNovelList(doc)
end

----------------------------------------------------
-- NOVEL INFO + CHAPTERS
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
        info:setImageURL(
            cleanImg(img:attr("src"))
        )
    end

    ------------------------------------------------
    -- CHAPTERS
    ------------------------------------------------

    if loadChapters then

        local chapters = {}

        local links =
            doc:select(
                "ul.wp-block-post-template h6.wp-block-post-title a"
            )

        map(links, function(v)

            chapters[#chapters + 1] = NovelChapter {
                title = v:text(),
                link = shrinkURL(v:attr("href")),
                order = #chapters + 1
            }

        end)

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