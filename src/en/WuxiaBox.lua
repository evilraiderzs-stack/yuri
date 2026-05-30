-- {"id":14445,"ver":"0.1.0","libVer":"1.0.0","author":"YourName","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://www.wuxiabox.com"

local WPCommon = Require("WPCommon")

----------------------------------------------------
-- URL HELPERS
----------------------------------------------------

local function shrinkURL(url)
    return url:gsub("^https?://www%.wuxiabox%.com", "")
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
-- CHAPTER CONTENT
----------------------------------------------------

local function parsePage(url)
    local doc = GETDocument(expandURL(url))

    local content = doc:selectFirst("div.chapter-content")

    if not content then
        return nil
    end

    content:select("script"):remove()
    content:select("iframe"):remove()
    content:select("style"):remove()
    content:select(".TPuhiHlg"):remove()

    if WPCommon then
        WPCommon.cleanupElement(content)
        WPCommon.cleanupPassages(content:children())
    end

    return content
end

local function getPassage(url)
    local page = parsePage(url)

    if not page then
        return ""
    end

    return pageOfElem(page)
end

----------------------------------------------------
-- TEST LISTING
----------------------------------------------------

local function listings()
    return {
        Novel {
            title = "The Princess' Shadow Guard Cannot Be Too Clever",
            link = "/novel/the-princess-shadow-guard-cannot-be-too-clever.html"
        }
    }
end

----------------------------------------------------
-- NOVEL INFO
----------------------------------------------------

local function parseNovel(novelURL, loadChapters)

    local doc = GETDocument(expandURL(novelURL))

    local info = NovelInfo {}

    ------------------------------------------------
    -- TITLE
    ------------------------------------------------

    local titleNode =
        doc:selectFirst("h1")
        or doc:selectFirst(".novel-title")
        or doc:selectFirst(".book-title")

    if titleNode then
        info:setTitle(titleNode:text())
    else
        info:setTitle("The Princess' Shadow Guard Cannot Be Too Clever")
    end

    ------------------------------------------------
    -- COVER
    ------------------------------------------------

    local img =
        doc:selectFirst(".book-cover img")
        or doc:selectFirst(".novel-cover img")
        or doc:selectFirst("img")

    if img then
        info:setImageURL(cleanImg(img:attr("src")))
    end

    ------------------------------------------------
    -- CHAPTERS
    ------------------------------------------------

    if loadChapters then

        local chapters = {}
        local order = 1

        local links = doc:select("ul.chapter-list li a")

        map(links, function(v)

            local titleNode = v:selectFirst(".chapter-title")

            local title

            if titleNode then
                title = titleNode:text()
            else
                title = v:text()
            end

            chapters[#chapters + 1] = NovelChapter {
                title = title,
                link = shrinkURL(v:attr("href")),
                order = order
            }

            order = order + 1
        end)

        info:setChapters(AsList(chapters))
    end

    return info
end

----------------------------------------------------
-- EXPORT
----------------------------------------------------

return {
    id = 14445,
    name = "Wuxia Box",
    baseURL = baseURL,

    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Tintan.png",

    hasSearch = false,
    lang = "en",

    chapterType = ChapterType.HTML,

    listings = {
        Listing("Test Novel", false, listings)
    },

    parseNovel = parseNovel,
    getPassage = getPassage,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}