module Components.Organisms.Header exposing (Brand, ExtLink, LeftLinksModel, LeftLinksTheme, RightLinksModel, RightLinksTheme, doc, leftLinks, leftLinksIndigo, leftLinksWhite, rightLinks, rightLinksIndigo, rightLinksWhite)

import Css
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, header, img, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, href, src)
import Libs.Html.Styled exposing (extLink)
import Libs.Html.Styled.Attributes exposing (ariaLabel)
import Libs.Models exposing (Image, Link)
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias RightLinksModel msg =
    { brand : Brand
    , links : List (ExtLink msg)
    }


type alias Brand =
    { img : Image, link : Link }


type alias ExtLink msg =
    { url : String, content : List (Html msg), external : Bool }


type alias RightLinksTheme =
    { bg : Css.Style, text : Css.Style }


rightLinksWhite : RightLinksModel msg -> Html msg
rightLinksWhite model =
    rightLinks { bg = Tw.bg_white, text = Css.batch [ Tw.text_gray_500, Css.hover [ Tw.text_gray_900 ] ] } model


rightLinksIndigo : RightLinksModel msg -> Html msg
rightLinksIndigo model =
    rightLinks { bg = Tw.bg_indigo_600, text = Css.batch [ Tw.text_white, Css.hover [ Tw.text_indigo_50 ] ] } model


rightLinks : RightLinksTheme -> RightLinksModel msg -> Html msg
rightLinks theme model =
    header [ css [ theme.bg ] ]
        [ div [ css [ Tw.flex, Tw.justify_between, Tw.items_center, Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Tw.py_6, Bp.lg [ Tw.px_8 ], Bp.md [ Tw.justify_start, Tw.space_x_10 ], Bp.sm [ Tw.px_6 ] ] ]
            [ a [ href model.brand.link.url, css [ Tw.flex, Tw.justify_start, Tw.items_center, Tw.font_medium, Bp.lg [ Tw.w_0, Tw.flex_1 ] ] ]
                [ img [ src model.brand.img.src, alt model.brand.img.alt, css [ Tw.h_8, Tw.w_auto, Bp.sm [ Tw.h_10 ] ] ] []
                , span [ css [ Tw.ml_3, Tw.text_2xl, theme.text ] ] [ text model.brand.link.text ]
                ]
            , nav [ css [ Tw.hidden, Tw.space_x_10, Bp.md [ Tw.flex ] ] ]
                (model.links
                    |> List.map
                        (\l ->
                            if l.external then
                                extLink l.url [ css [ Tw.text_base, Tw.font_medium, theme.text ] ] l.content

                            else
                                a [ href l.url, css [ Tw.text_base, Tw.font_medium, theme.text ] ] l.content
                        )
                )
            ]
        ]


type alias LeftLinksModel =
    { brand : Brand
    , primary : Link
    , secondary : Link
    , links : List Link
    }


type alias LeftLinksTheme =
    { bg : Css.Style, links : Css.Style, primary : Css.Style, secondary : Css.Style }


leftLinksIndigo : LeftLinksModel -> Html msg
leftLinksIndigo model =
    leftLinks { bg = Tw.bg_indigo_600, links = Css.batch [ Tw.text_white, Css.hover [ Tw.text_indigo_50 ] ], secondary = Css.batch [ Tw.text_white, Tw.bg_indigo_500, Css.hover [ Tw.bg_opacity_75 ] ], primary = Css.batch [ Tw.text_indigo_600, Tw.bg_white, Css.hover [ Tw.bg_indigo_50 ] ] } model


leftLinksWhite : LeftLinksModel -> Html msg
leftLinksWhite model =
    leftLinks { bg = Tw.bg_white, links = Css.batch [ Tw.text_gray_500, Css.hover [ Tw.text_gray_900 ] ], secondary = Css.batch [ Tw.text_gray_500, Css.hover [ Tw.text_gray_900 ] ], primary = Css.batch [ Tw.text_white, Tw.bg_indigo_600, Css.hover [ Tw.bg_indigo_700 ] ] } model


leftLinks : LeftLinksTheme -> LeftLinksModel -> Html msg
leftLinks theme model =
    header [ css [ theme.bg ] ]
        [ nav [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.px_4, Bp.lg [ Tw.px_8 ], Bp.sm [ Tw.px_6 ] ], ariaLabel "Top" ]
            [ div [ css [ Tw.w_full, Tw.py_6, Tw.flex, Tw.items_center, Tw.justify_between, Tw.border_b, Tw.border_indigo_500, Bp.lg [ Tw.border_none ] ] ]
                [ div [ css [ Tw.flex, Tw.items_center ] ]
                    [ a [ href model.brand.link.url ] [ span [ css [ Tw.sr_only ] ] [ text model.brand.link.text ], img [ css [ Tw.h_10, Tw.w_auto ], src model.brand.img.src, alt model.brand.img.alt ] [] ]
                    , div [ css [ Tw.hidden, Tw.ml_10, Tw.space_x_8, Bp.lg [ Tw.block ] ] ]
                        (model.links |> List.map (\link -> a [ href link.url, css [ Tw.text_base, Tw.font_medium, theme.links ] ] [ text link.text ]))
                    ]
                , div [ css [ Tw.ml_10, Tw.space_x_4 ] ]
                    [ a [ href model.secondary.url, css [ Tw.inline_block, Tw.py_2, Tw.px_4, Tw.border, Tw.border_transparent, Tw.rounded_md, Tw.text_base, Tw.font_medium, theme.secondary ] ] [ text model.secondary.text ]
                    , a [ href model.primary.url, css [ Tw.inline_block, Tw.py_2, Tw.px_4, Tw.border, Tw.border_transparent, Tw.rounded_md, Tw.text_base, Tw.font_medium, theme.primary ] ] [ text model.primary.text ]
                    ]
                ]
            , div [ css [ Tw.py_4, Tw.flex, Tw.flex_wrap, Tw.justify_center, Tw.space_x_6, Bp.lg [ Tw.hidden ] ] ]
                (model.links |> List.map (\link -> a [ href link.url, css [ Tw.text_base, Tw.font_medium, theme.links ] ] [ text link.text ]))
            ]
        ]



-- DOCUMENTATION


logoWhite : String
logoWhite =
    "https://tailwindui.com/img/logos/workflow-mark.svg?color=white"


logoIndigo : String
logoIndigo =
    "https://tailwindui.com/img/logos/workflow-mark-indigo-600.svg"


rightLinksModel : String -> RightLinksModel msg
rightLinksModel img =
    { brand = { img = { src = img, alt = "Workflow" }, link = { url = "#", text = "Workflow" } }
    , links =
        [ { url = "#", content = [ text "Solutions" ], external = False }
        , { url = "#", content = [ text "Pricing" ], external = False }
        , { url = "#", content = [ text "Docs" ], external = False }
        , { url = "#", content = [ text "Company" ], external = False }
        ]
    }


leftLinksModel : String -> LeftLinksModel
leftLinksModel img =
    { brand = { img = { src = img, alt = "Workflow" }, link = { url = "#", text = "Workflow" } }
    , primary = { url = "#", text = "Sign up" }
    , secondary = { url = "#", text = "Sign in" }
    , links =
        [ { url = "#", text = "Solutions" }
        , { url = "#", text = "Pricing" }
        , { url = "#", text = "Docs" }
        , { url = "#", text = "Company" }
        ]
    }


doc : Chapter x
doc =
    Chapter.chapter "Header"
        |> Chapter.renderStatefulComponentList
            [ ( "rightLinksIndigo", \_ -> rightLinksIndigo (rightLinksModel logoWhite) )
            , ( "rightLinksWhite", \_ -> rightLinksWhite (rightLinksModel logoIndigo) )
            , ( "rightLinks", \_ -> rightLinks { bg = Tw.bg_white, text = Tu.noStyle } (rightLinksModel logoIndigo) )
            , ( "leftLinksIndigo", \_ -> leftLinksIndigo (leftLinksModel logoWhite) )
            , ( "leftLinksWhite", \_ -> leftLinksWhite (leftLinksModel logoIndigo) )
            , ( "leftLinks", \_ -> leftLinks { bg = Tw.bg_white, links = Tu.noStyle, secondary = Tu.noStyle, primary = Tu.noStyle } (leftLinksModel logoIndigo) )
            ]
