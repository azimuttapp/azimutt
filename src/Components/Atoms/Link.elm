module Components.Atoms.Link exposing (LinkProps, doc, link)

import Css exposing (hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, text)
import Html.Styled.Attributes exposing (css, href)
import Tailwind.Utilities exposing (bg_indigo_600, bg_indigo_700, border, border_transparent, font_medium, inline_flex, items_center, justify_center, px_5, py_3, rounded_md, shadow, text_base, text_white)


type alias LinkProps =
    { label : String, url : String }


link : LinkProps -> Html msg
link props =
    div []
        [ div [ css [ inline_flex, rounded_md, shadow ] ]
            [ a [ href props.url, css [ inline_flex, items_center, justify_center, px_5, py_3, border, border_transparent, text_base, font_medium, rounded_md, text_white, bg_indigo_600, hover [ bg_indigo_700 ] ] ]
                [ text props.label ]
            ]
        ]



-- DOCUMENTATION


defaultProps : LinkProps
defaultProps =
    { label = "Click me!", url = "#" }


doc : Chapter x
doc =
    chapter "Link"
        |> renderComponentList
            [ ( "link", link defaultProps )
            ]
