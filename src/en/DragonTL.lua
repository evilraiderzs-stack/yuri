-- {"id":12321,"ver":"0.1.0","libVer":"1.0.0","author":"N4O"}

local baseURL = "https://dragontl.net"
local WPCommon = Require("WPCommon")

--- Remove footnote links like:
--- <a id="ref8" href="#fn8">8</a>
local function removeFootnotes(elem)
    -- remove anchor footnote refs
    for _, a in ipairs(elem:select("a[id^=ref]"):toArray()) do
        a:remove()
    end

    -- remove backlink symbols like ↩ if left behind
    local html = elem:html()
    html = html:gsub("%s*↩%s*", "")
    elem:html(html)
end

local function expandURL(url)
    if url:match("^https?://") then return url end
    return baseURL .. url
end

local function shrinkURL(url)
    return url:gsub("^https?://dragontl%.net", "")
end

local function parsePage(url)
    local doc = GETDocument(expandURL(url))

    local content = doc:selectFirst(".mbs_posts_text")
    if not content then return nil end

    WPCommon.cleanupElement(content)
    removeFootnotes(content)
    WPCommon.cleanupPassages(content:children())

    return content
end

local function getTitle(doc)
    local t = doc:selectFirst("h1")
    if t then return t:text() end
    local title = doc:selectFirst("title")
    return title and title:text() or "Unknown"
end

return {
    id = 12321,
    name = "Dragon TL",
    baseURL = baseURL,
    imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/Tintan.png",
    hasSearch = false,
    chapterType = ChapterType.HTML,

    listings = {
        Listing("Novels", false, function()
            local doc = GETDocument(baseURL)

            local out = {}

            -- story list in sidebar
            for _, a in ipairs(doc:select(".mbs_story_widget_list a"):toArray()) do
                out[#out + 1] = Novel {
                    title = a:text(),
                    link = shrinkURL(a:attr("href"))
                }
            end

            return out
        end)
    },

    parseNovel = function(novelURL, loadChapters)
        local doc = GETDocument(expandURL(novelURL))

        local info = NovelInfo {
            title = getTitle(doc)
        }

        if loadChapters then
            local chapters = {}

            for _, a in ipairs(doc:select(".mbs_toc_list a"):toArray()) do
                chapters[#chapters + 1] = NovelChapter {
                    title = a:text(),
                    link = shrinkURL(a:attr("href")),
                    order = #chapters + 1
                }
            end

            info:setChapters(AsList(chapters))
        end

        return info
    end,

    getPassage = function(chapterURL)
        return pageOfElem(parsePage(chapterURL))
    end,
}