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

    -- Remove ads/scripts
    content:select("script"):remove()
    content:select("iframe"):remove()
    content:select("style"):remove()

    -- Remove common ad containers
    content:select(".TPuhiHlg"):remove()

    WPCommon.cleanupElement(content)
    WPCommon.cleanupPassages(content:children())

    return content
end

local function getPassage(url)
    local page = parsePage(url)

    if not page then
        return ""
    end

    return pageOfElem(page)
end

local function search(data)

    local query = data[QUERY]

    local doc = GETDocument(
        baseURL .. "/search.html?keyboard=" .. query
    )

    local results = {}

    local novels = doc:select("a[href*='/novel/']")

    map(novels, function(v)

        local href = v:attr("href")

        if href and href:find("/novel/") then

            results[#results + 1] = Novel {
                title = v:text(),
                link = shrinkURL(href)
            }

        end
    end)

    return results
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
        or doc:selectFirst(".book-title")

    if titleNode then
        info:setTitle(titleNode:text())
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

            local title =
                v:selectFirst(".chapter-title")
                and v:selectFirst(".chapter-title"):text()
                or v:text()

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

    hasSearch = true,
    lang = "en",

    chapterType = ChapterType.HTML,

    search = search,

    parseNovel = parseNovel,
    getPassage = getPassage,

    shrinkURL = shrinkURL,
    expandURL = expandURL
}