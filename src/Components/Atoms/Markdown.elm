module Components.Atoms.Markdown exposing (doc, markdown, markdownUnsafe, rawHtml)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html)
import Html.Attributes exposing (class, classList)
import Markdown exposing (Options)


markdown : List String -> String -> Html msg
markdown classes md =
    render defaultOptions classes md


markdownUnsafe : List String -> String -> Html msg
markdownUnsafe classes md =
    render { defaultOptions | sanitize = False } classes md


rawHtml : String -> Html msg
rawHtml content =
    Markdown.toHtmlWith { githubFlavored = Nothing, defaultHighlighting = Nothing, sanitize = False, smartypants = False } [] content


render : Options -> List String -> String -> Html msg
render options classes md =
    Markdown.toHtmlWith options [ class "markdown", classList (classes |> List.map (\c -> ( c, True ))) ] md


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
            [ ( "markdown", markdown [] "Some *text*, but <b>html</b> is escaped \\o/" )
            , ( "markdownUnsafe", markdownUnsafe [] "Some *text* with <b>html</b> working!" )
            , ( "samples", markdown [ "prose prose-indigo prose-lg" ] """
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

```js
project.sources.flatMap(s => s.tables).length
```
""" )
            ]
