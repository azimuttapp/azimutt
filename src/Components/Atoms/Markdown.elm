module Components.Atoms.Markdown exposing (doc, markdown, markdownUnsafe)

import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Attributes exposing (class)
import Html.Styled as Styled exposing (Html)
import Markdown exposing (Options)


markdown : String -> Html msg
markdown md =
    render defaultOptions md


markdownUnsafe : String -> Html msg
markdownUnsafe md =
    render { defaultOptions | sanitize = False } md


render : Options -> String -> Html msg
render options md =
    Styled.fromUnstyled (Markdown.toHtmlWith options [ class "markdown" ] md)


defaultOptions : Options
defaultOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Nothing
    , sanitize = True
    , smartypants = True
    }


doc : Chapter x
doc =
    chapter "Markdown"
        |> renderComponentList
            [ ( "markdown", markdown "Some *text*, but <b>html</b> is escaped \\o/" )
            , ( "markdownUnsafe", markdownUnsafe "Some *text* with <b>html</b> working!" )
            ]
