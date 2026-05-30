-- {"id":12322,"ver":"0.2.0","libVer":"1.0.0","author":"YourName","dep":["WPCommon>=1.0.0"]}

local baseURL = "https://baihetales.wordpress.com"

local WPCommon = Require("WPCommon")

----------------------------------------------------
-- URL HELPERS
----------------------------------------------------

local function shrinkURL(url)
    return url:gsub("^.-baihetales%.wordpress%.com", "")
end

local function expandURL(url)
    return baseURL .. url
end

----------------------------------------------------
-- CHAPTER PARSER
----------------------------------------------------

local function parsePage(url)
    local doc = GETDocument(expandURL(url))

    local content = doc:selectFirst(".entry-content")
    if not content then
        return nil
    end

    ------------------------------------------------
    -- Remove everything after first HR
    -- (Patreon, navigation, socials, etc.)
    ------------------------------------------------

    local hr = content:selectFirst("hr")

    if hr then
        local elem = hr

        while elem do
            local nextElem = elem:nextElementSibling()
            elem:remove()
            elem = nextElem
        end
    end

    ------------------------------------------------
    -- Remove scripts
    ------------------------------------------------

    map(content:select("script"), function(e)
        e:remove()
    end)

    ------------------------------------------------
    -- Remove iframes
    ------------------------------------------------

    map(content:select("iframe"), function(e)
        e:remove()
    end)

    ------------------------------------------------
    -- Remove ads
    ------------------------------------------------

    map(content:select("[id^=atatags]"), function(e)
        e:remove()
    end)

    map(content:select("#jp-post-flair"), function(e)
        e:remove()
    end)

    WPCommon.cleanupElement(content)
    WPCommon.cleanupPassages(content:children())

    return content
end

----------------------------------------------------
-- LISTINGS
----------------------------------------------------

local function findListings(doc)
    local novels = {}

    map(doc:select("li.wp-block-post"), function(post)
        local titleElem = post:selectFirst("h3.wp-block-post-title a")

        if not titleElem then
            return
        end

        novels[#novels + 1] = Novel {
            title = titleElem:text(),
            link = shrinkURL(titleElem:attr("href"))
        }
    end)

    return novels
end

----------------------------------------------------
-- NOVEL PARSER
----------------------------------------------------

local function parseNovelPage(novelURL, loadChapters)
    local doc = GETDocument(expandURL(novelURL))

    local article = doc:selectFirst("article")

    local info = NovelInfo {
        title = article:selectFirst(".entry-title"):text()
    }

    ------------------------------------------------
    -- COVER
    ------------------------------------------------

    local img = article:selectFirst(".entry-content img")

    if img then
        info:setImageURL(img:attr("src"))
    end

    ------------------------------------------------
    -- CHAPTERS
    ------------------------------------------------

    if loadChapters then
        local chapters = {}

        local page = 1

        while true do
            local pageURL = novelURL

            if page > 1 then
                pageURL = novelURL .. "?query-4-page=" .. page
            end

            local pageDoc = GETDocument(expandURL(pageURL))

            local links = pageDoc:select(
                "li.wp-block-post h6.wp-block-post-title a"
            )

            if links:isEmpty() then
                break
            end

            map(links, function(a)
                local href = a:attr("href")

                if WPCommon.contains(
                    href,
                    "baihetales.wordpress.com"
                ) then
                    chapters[#chapters + 1] = NovelChapter {
                        order = #chapters + 1,
                        title = a:text(),
                        link = shrinkURL(href)
                    }
                end
            end)

            page = page + 1
        end

        info:setChapters(AsList(chapters))
    end

    return info
end

----------------------------------------------------
-- RETURN EXTENSION
----------------------------------------------------

return {
    id = 12322,
    name = "Baihe Tales",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Tintan.png",

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
```
