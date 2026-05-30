-- {"id":12322,"ver":"0.1.0","libVer":"1.0.0","author":"YourName"}

local baseURL = "https://baihetales.wordpress.com"

local WPCommon = Require("WPCommon")

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

    WPCommon.cleanupElement(content)
    WPCommon.cleanupPassages(content:children())

    -- Remove everything after the translation text
    map(content:select("hr"), function(hr)
        hr:remove()
    end)

    map(content:select(".wp-block-columns"), function(e)
        e:remove()
    end)

    map(content:select("script"), function(e)
        e:remove()
    end)

    return content
end

----------------------------------------------------
-- NOVEL LIST
----------------------------------------------------

local function findListings(doc)
    local novels = {}

    map(doc:select(".wp-block-post-template li"), function(item)
        local titleElem = item:selectFirst(".wp-block-post-title a")

        if titleElem then
            novels[#novels + 1] = Novel {
                title = titleElem:text(),
                link = shrinkURL(titleElem:attr("href"))
            }
        end
    end)

    return novels
end

----------------------------------------------------
-- NOVEL PAGE / TOC
----------------------------------------------------

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

        local content = article:selectFirst(".entry-content")

        if content then
            map(content:select("a"), function(a)
                local href = a:attr("href")

                if href
                    and href:find("baihetales.wordpress.com")
                    and not href:find("patreon")
                    and not href:find("buymeacoffee")
                then
                    chapters[#chapters + 1] = NovelChapter {
                        order = #chapters + 1,
                        title = a:text(),
                        link = shrinkURL(href)
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