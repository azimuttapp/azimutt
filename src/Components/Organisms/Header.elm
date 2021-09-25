module Components.Organisms.Header exposing (Brand, ExtLink, LeftLinksModel, LeftLinksTheme, RightLinksModel, RightLinksTheme, doc, leftLinks, leftLinksIndigo, leftLinksWhite, rightLinks, rightLinksIndigo, rightLinksWhite)

import Css exposing (hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, div, header, img, nav, span, text)
import Html.Styled.Attributes exposing (alt, css, href, src)
import Libs.Html.Styled exposing (extLink)
import Libs.Html.Styled.Attributes exposing (ariaLabel)
import Libs.Models exposing (Image, Link)
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (bg_indigo_50, bg_indigo_500, bg_indigo_600, bg_indigo_700, bg_opacity_75, bg_white, block, border, border_b, border_indigo_500, border_none, border_transparent, flex, flex_1, flex_wrap, font_medium, h_10, h_8, hidden, inline_block, items_center, justify_between, justify_center, justify_start, max_w_7xl, ml_10, mx_auto, px_4, px_6, px_8, py_2, py_4, py_6, rounded_md, space_x_10, space_x_4, space_x_6, space_x_8, sr_only, text_base, text_gray_500, text_gray_900, text_indigo_50, text_indigo_600, text_white, w_0, w_auto, w_full)


type alias RightLinksModel msg =
    { brand : Brand
    , links : List (ExtLink msg)
    }


type alias Brand =
    { img : Image, link : Link }


type alias ExtLink msg =
    { url : String, content : List (Html msg), external : Bool }


type alias RightLinksTheme =
    { bg : Css.Style, links : List Css.Style }


rightLinksWhite : RightLinksModel msg -> Html msg
rightLinksWhite model =
    rightLinks { bg = bg_white, links = [ text_gray_500, hover [ text_gray_900 ] ] } model


rightLinksIndigo : RightLinksModel msg -> Html msg
rightLinksIndigo model =
    rightLinks { bg = bg_indigo_600, links = [ text_white, hover [ text_indigo_50 ] ] } model


rightLinks : RightLinksTheme -> RightLinksModel msg -> Html msg
rightLinks theme model =
    header [ css [ theme.bg ] ]
        [ div [ css [ flex, justify_between, items_center, max_w_7xl, mx_auto, px_4, py_6, lg [ px_8 ], md [ justify_start, space_x_10 ], sm [ px_6 ] ] ]
            [ div [ css [ flex, justify_start, lg [ w_0, flex_1 ] ] ]
                [ a [ href model.brand.link.url ]
                    [ span [ css [ sr_only ] ] [ text model.brand.link.text ]
                    , img [ src model.brand.img.src, alt model.brand.img.alt, css [ h_8, w_auto, sm [ h_10 ] ] ] []
                    ]
                ]
            , nav [ css [ hidden, space_x_10, md [ flex ] ] ]
                (model.links
                    |> List.map
                        (\l ->
                            if l.external then
                                extLink l.url [ css ([ text_base, font_medium ] ++ theme.links) ] l.content

                            else
                                a [ href l.url, css ([ text_base, font_medium ] ++ theme.links) ] l.content
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
    { bg : Css.Style, links : List Css.Style, primary : List Css.Style, secondary : List Css.Style }


leftLinksIndigo : LeftLinksModel -> Html msg
leftLinksIndigo model =
    leftLinks { bg = bg_indigo_600, links = [ text_white, hover [ text_indigo_50 ] ], secondary = [ text_white, bg_indigo_500, hover [ bg_opacity_75 ] ], primary = [ text_indigo_600, bg_white, hover [ bg_indigo_50 ] ] } model


leftLinksWhite : LeftLinksModel -> Html msg
leftLinksWhite model =
    leftLinks { bg = bg_white, links = [ text_gray_500, hover [ text_gray_900 ] ], secondary = [ text_gray_500, hover [ text_gray_900 ] ], primary = [ text_white, bg_indigo_600, hover [ bg_indigo_700 ] ] } model


leftLinks : LeftLinksTheme -> LeftLinksModel -> Html msg
leftLinks theme model =
    header [ css [ theme.bg ] ]
        [ nav [ css [ max_w_7xl, mx_auto, px_4, lg [ px_8 ], sm [ px_6 ] ], ariaLabel "Top" ]
            [ div [ css [ w_full, py_6, flex, items_center, justify_between, border_b, border_indigo_500, lg [ border_none ] ] ]
                [ div [ css [ flex, items_center ] ]
                    [ a [ href model.brand.link.url ] [ span [ css [ sr_only ] ] [ text model.brand.link.text ], img [ css [ h_10, w_auto ], src model.brand.img.src, alt model.brand.img.alt ] [] ]
                    , div [ css [ hidden, ml_10, space_x_8, lg [ block ] ] ]
                        (model.links |> List.map (\link -> a [ href link.url, css ([ text_base, font_medium ] ++ theme.links) ] [ text link.text ]))
                    ]
                , div [ css [ ml_10, space_x_4 ] ]
                    [ a [ href model.secondary.url, css ([ inline_block, py_2, px_4, border, border_transparent, rounded_md, text_base, font_medium ] ++ theme.secondary) ] [ text model.secondary.text ]
                    , a [ href model.primary.url, css ([ inline_block, py_2, px_4, border, border_transparent, rounded_md, text_base, font_medium ] ++ theme.primary) ] [ text model.primary.text ]
                    ]
                ]
            , div [ css [ py_4, flex, flex_wrap, justify_center, space_x_6, lg [ hidden ] ] ]
                (model.links |> List.map (\link -> a [ href link.url, css ([ text_base, font_medium ] ++ theme.links) ] [ text link.text ]))
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
    chapter "Header"
        |> renderComponentList
            [ ( "rightLinksIndigo", rightLinksIndigo (rightLinksModel logoWhite) )
            , ( "rightLinksWhite", rightLinksWhite (rightLinksModel logoIndigo) )
            , ( "rightLinks", rightLinks { bg = bg_white, links = [] } (rightLinksModel logoIndigo) )
            , ( "leftLinksIndigo", leftLinksIndigo (leftLinksModel logoWhite) )
            , ( "leftLinksWhite", leftLinksWhite (leftLinksModel logoIndigo) )
            , ( "leftLinks", leftLinks { bg = bg_white, links = [], secondary = [], primary = [] } (leftLinksModel logoIndigo) )
            ]
