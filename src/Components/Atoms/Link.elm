module Components.Atoms.Link exposing (LinkProps, link, linkChapter)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (css, href)
import Tailwind.Utilities as Tw


type alias LinkProps =
    { label : String, url : String }


link : LinkProps -> Html msg
link props =
    div []
        [ div [ css [ Tw.inline_flex, Tw.rounded_md, Tw.shadow ] ]
            [ a [ href props.url, css [ Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.px_5, Tw.py_3, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.text_white, Tw.bg_indigo_600, Css.hover [ Tw.bg_indigo_700 ] ] ]
                [ text props.label ]
            ]
        ]


linkChapter : Chapter x
linkChapter =
    let
        defaultProps : LinkProps
        defaultProps =
            { label = "Click me!", url = "#" }
    in
    chapter "Links"
        |> renderComponentList
            [ ( "button Link", link defaultProps )
            ]
