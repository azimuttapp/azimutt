module Components.Slices.NotFound exposing (Brand, SimpleModel, doc, simple)

import Css
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, footer, h1, img, main_, nav, p, span, text)
import Html.Styled.Attributes exposing (alt, css, href, src)
import Libs.Html.Styled.Attributes exposing (ariaHidden)
import Libs.Models exposing (Image, Link)
import Libs.Models.Color as Color
import Libs.Models.Theme exposing (Theme)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias SimpleModel =
    { brand : Brand
    , header : String
    , title : String
    , message : String
    , link : Link
    , footer : List Link
    }


type alias Brand =
    { img : Image, link : Link }


simple : Theme -> SimpleModel -> Html msg
simple theme model =
    div [ css [ Tw.min_h_full, Tw.pt_16, Tw.pb_12, Tw.flex, Tw.flex_col, Tw.bg_white ] ]
        [ main_ [ css [ Tw.flex_grow, Tw.flex, Tw.flex_col, Tw.justify_center, Tw.max_w_7xl, Tw.w_full, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ div [ css [ Tw.flex_shrink_0, Tw.flex, Tw.justify_center ] ]
                [ a [ href model.brand.link.url, css [ Tw.inline_flex ] ]
                    [ span [ css [ Tw.sr_only ] ] [ text model.brand.link.text ]
                    , img [ css [ Tw.h_12, Tw.w_auto ], src model.brand.img.src, alt model.brand.img.alt ] []
                    ]
                ]
            , div [ css [ Tw.py_16 ] ]
                [ div [ css [ Tw.text_center ] ]
                    [ p [ css [ Tw.text_sm, Tw.font_semibold, Color.text theme.color 600, Tw.uppercase, Tw.tracking_wide ] ] [ text model.header ]
                    , h1 [ css [ Tw.mt_2, Tw.text_4xl, Tw.font_extrabold, Tw.text_gray_900, Tw.tracking_tight, Bp.sm [ Tw.text_5xl ] ] ] [ text model.title ]
                    , p [ css [ Tw.mt_2, Tw.text_base, Tw.text_gray_500 ] ] [ text model.message ]
                    , div [ css [ Tw.mt_6 ] ]
                        [ a [ href model.link.url, css [ Tw.text_base, Tw.font_medium, Color.text theme.color 600, Css.hover [ Color.text theme.color 500 ] ] ]
                            [ text model.link.text
                            , span [ ariaHidden True ] [ text "→" ]
                            ]
                        ]
                    ]
                ]
            ]
        , footer [ css [ Tw.flex_shrink_0, Tw.max_w_7xl, Tw.w_full, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ] ]
            [ nav [ css [ Tw.flex, Tw.justify_center, Tw.space_x_4 ] ]
                (model.footer
                    |> List.map (\link -> a [ href link.url, css [ Tw.text_sm, Tw.font_medium, Tw.text_gray_500, Css.hover [ Tw.text_gray_600 ] ] ] [ text link.text ])
                    |> List.intersperse (span [ css [ Tw.inline_block, Tw.border_l, Tw.border_gray_300 ], ariaHidden True ] [])
                )
            ]
        ]



-- DOCUMENTATION


docModel : SimpleModel
docModel =
    { brand =
        { img = { src = "https://tailwindui.com/img/logos/workflow-mark.svg?color=indigo&shade=600", alt = "Workflow" }
        , link = { url = "#", text = "Workflow" }
        }
    , header = "404 error"
    , title = "Page not found."
    , message = "Sorry, we couldn't find the page you’re looking for."
    , link = { url = "#", text = "Go back home" }
    , footer = [ { url = "#", text = "Contact Support" }, { url = "#", text = "Status" }, { url = "#", text = "Twitter" } ]
    }


doc : Theme -> Chapter x
doc theme =
    Chapter.chapter "NotFound"
        |> Chapter.renderComponentList
            [ ( "simple", simple theme docModel )
            ]
