module Components.Atoms.Markdown exposing (doc, markdown, markdownUnsafe)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind exposing (TwClass)
import Markdown exposing (Options)


markdown : TwClass -> String -> Html msg
markdown styles md =
    render defaultOptions styles md


markdownUnsafe : TwClass -> String -> Html msg
markdownUnsafe styles md =
    render { defaultOptions | sanitize = False } styles md


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
            ]
