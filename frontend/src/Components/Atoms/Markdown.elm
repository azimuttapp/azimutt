module Components.Atoms.Markdown exposing (doc, markdown, markdownUnsafe, prose, rawHtml)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind exposing (TwClass)
import Markdown exposing (Options)


prose : TwClass -> String -> Html msg
prose styles md =
    markdown
        (styles
            ++ " prose leading-tight "
            ++ "prose-p:my-2 prose-p:first:mt-0 prose-p:last:mb-0 "
            ++ "prose-ul:my-2 prose-li:my-0 "
            ++ "prose-img:my-0 "
            ++ "prose-pre:my-2 prose-pre:py-1 prose-pre:px-2 prose-pre:bg-gray-200 prose-pre:text-gray-700"
        )
        md


markdown : TwClass -> String -> Html msg
markdown styles md =
    render defaultOptions styles md


markdownUnsafe : TwClass -> String -> Html msg
markdownUnsafe styles md =
    render { defaultOptions | sanitize = False } styles md


rawHtml : String -> Html msg
rawHtml content =
    Markdown.toHtmlWith { githubFlavored = Nothing, defaultHighlighting = Nothing, sanitize = False, smartypants = False } [] content


render : Options -> TwClass -> String -> Html msg
render options styles md =
    Markdown.toHtmlWith options [ css [ "markdown", styles ] ] md


defaultOptions : Options
defaultOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = True
    , smartypants = True
    }



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Markdown"
        |> renderComponentList
            [ ( "markdown", markdown "" "Some *text*, but <b>html</b> is escaped \\o/" )
            , ( "markdownUnsafe", markdownUnsafe "" "Some *text* with <b>html</b> working!" )
            , ( "samples", markdown "prose prose-indigo prose-lg" """
A text with *italic*, **bold**, [link](#) and other markdown features such as list:
- item 1
- item 2
# Title 1
## Title 2
### Title 3
#### Title 4
##### Title 5
###### Title 6
several codes:
```sql
SELECT * FROM users;
```
```elm
type alias Dialog =
    { id : HtmlId }
```
```javascript
project.sources.flatMap(s => s.tables).length
```
```aml
users
  id uuid pk
  name varchar
```
""" )
            ]
