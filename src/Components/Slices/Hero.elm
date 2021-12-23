module Components.Slices.Hero exposing (Model, backgroundImageSlice, basicSlice, doc)

import Components.Atoms.Dots as Dots
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import Css exposing (focus, hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, button, div, h1, img, main_, nav, p, span, text)
import Html.Styled.Attributes exposing (alt, css, href, src, type_)
import Libs.Html.Styled.Attributes exposing (ariaExpanded, ariaHidden, ariaLabel)
import Libs.Models exposing (Image)
import Libs.Models.Color as Color
import Tailwind.Breakpoints exposing (lg, md, sm, xl)
import Tailwind.Utilities exposing (absolute, bg_blue_600, bg_blue_800, bg_gradient_to_r, bg_gray_100, bg_gray_50, bg_white, block, border, border_transparent, bottom_0, flex, flex_1, font_extrabold, font_medium, from_green_200, gap_5, grid_cols_1, h_10, h_1over2, h_8, h_full, hidden, inline, inline_flex, inline_grid, inset_0, inset_x_0, inset_y_0, items_center, justify_between, justify_center, left_0, left_full, max_w_3xl, max_w_7xl, max_w_lg, max_w_md, mix_blend_multiply, mt_10, mt_16, mt_24, mt_3, mt_5, mt_6, mt_8, mx_auto, neg_mr_2, neg_translate_x_1over2, neg_translate_x_1over4, neg_translate_y_1over2, neg_translate_y_3over4, object_cover, origin_top_right, outline_none, overflow_hidden, p_2, pb_16, pb_24, pt_4, pt_6, px_10, px_4, px_5, px_6, px_8, py_16, py_24, py_3, py_32, py_4, relative, right_full, ring_1, ring_2, ring_black, ring_indigo_500, ring_inset, ring_opacity_5, rounded_2xl, rounded_lg, rounded_md, shadow, shadow_md, shadow_xl, space_y_0, space_y_4, sr_only, text_4xl, text_5xl, text_6xl, text_base, text_blue_600, text_center, text_gray_400, text_gray_500, text_gray_900, text_indigo_100, text_lg, text_white, text_xl, to_indigo_700, top_0, tracking_tight, transform, transition, translate_x_1over2, translate_x_1over4, translate_y_1over4, w_auto, w_full)


basicSlice : Html msg
basicSlice =
    div [ css [ relative, bg_gray_50, overflow_hidden ] ]
        [ div [ css [ hidden, sm [ block, absolute, inset_y_0, h_full, w_full ] ], ariaHidden True ]
            [ div [ css [ relative, h_full, max_w_7xl, mx_auto ] ]
                [ Dots.dots "f210dbf6-a58d-4871-961e-36d5016a0f49" 404 784 [ right_full, translate_y_1over4, translate_x_1over4, lg [ translate_x_1over2 ] ]
                , Dots.dots "5d0dd344-b041-4d26-bec4-8d33ea57ec9b" 404 784 [ left_full, neg_translate_y_3over4, neg_translate_x_1over4, lg [ neg_translate_x_1over2 ], md [ neg_translate_y_1over2 ] ]
                ]
            ]
        , div [ css [ relative, pt_6, pb_16, sm [ pb_24 ] ] ]
            [ div []
                [ div [ css [ max_w_7xl, mx_auto, px_4, sm [ px_6 ] ] ]
                    [ nav [ css [ relative, flex, items_center, justify_between, md [ justify_center ], sm [ h_10 ] ], ariaLabel "Global" ]
                        [ div [ css [ flex, items_center, flex_1, md [ absolute, inset_y_0, left_0 ] ] ]
                            [ div [ css [ flex, items_center, justify_between, w_full, md [ w_auto ] ] ]
                                [ a [ href "#" ]
                                    [ span [ css [ sr_only ] ] [ text "Workflow" ]
                                    , img [ src "/logo.svg", alt "", css [ h_8, w_auto, sm [ h_10 ] ] ] []
                                    ]
                                , div [ css [ neg_mr_2, flex, items_center, md [ hidden ] ] ]
                                    [ button [ type_ "button", css [ bg_gray_50, rounded_md, p_2, inline_flex, items_center, justify_center, text_gray_400, focus [ outline_none, ring_2, ring_inset, ring_indigo_500 ], hover [ text_gray_500, bg_gray_100 ] ], ariaExpanded False ]
                                        [ span [ css [ sr_only ] ] [ text "Open main menu" ]
                                        , Icon.outline Menu []
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , div [ css [ absolute, top_0, inset_x_0, p_2, transition, transform, origin_top_right, md [ hidden ] ] ]
                    [ div [ css [ rounded_lg, shadow_md, bg_white, ring_1, ring_black, ring_opacity_5, overflow_hidden ] ]
                        [ div [ css [ px_5, pt_4, flex, items_center, justify_between ] ]
                            [ div []
                                [ img [ src "/logo.svg", alt "Azimutt logo", css [ h_8, w_auto ] ] []
                                ]
                            , div [ css [ neg_mr_2 ] ]
                                [ button [ type_ "button", css [ bg_white, rounded_md, p_2, inline_flex, items_center, justify_center, text_gray_400, focus [ outline_none, ring_2, ring_inset, ring_indigo_500 ], hover [ text_gray_500, bg_gray_100 ] ] ]
                                    [ span [ css [ sr_only ] ]
                                        [ text "Close menu" ]
                                    , Icon.outline X []
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            , main_ [ css [ mt_16, mx_auto, max_w_7xl, px_4, sm [ mt_24 ] ] ]
                [ div [ css [ text_center ] ]
                    [ h1 [ css [ text_4xl, tracking_tight, font_extrabold, text_gray_900, md [ text_6xl ], sm [ text_5xl ] ] ]
                        [ span [ css [ block, xl [ inline ] ] ]
                            [ text "Explore your " ]
                        , span [ css [ block, text_blue_600, xl [ inline ] ] ]
                            [ text "database schema" ]
                        ]
                    , p [ css [ mt_3, max_w_md, mx_auto, text_base, text_gray_500, md [ mt_5, text_xl, max_w_3xl ], sm [ text_lg ] ] ]
                        [ text "Easily visualize your database schema and see how everything fits together." ]
                    , div [ css [ mt_5, max_w_md, mx_auto, md [ mt_8 ], sm [ flex, justify_center ] ] ]
                        [ div [ css [ rounded_md, shadow ] ]
                            [ a [ href (Route.toHref Route.App), css [ w_full, flex, items_center, justify_center, px_8, py_3, border, border_transparent, text_base, font_medium, rounded_md, text_white, bg_blue_600, hover [ bg_blue_800 ], md [ py_4, text_lg, px_10 ] ] ]
                                [ text "Get started" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


type alias Model msg =
    { bg : Image, title : String, content : List (Html msg), cta : Html msg }


backgroundImageSlice : Model msg -> Html msg
backgroundImageSlice model =
    div [ css [ relative ] ]
        [ div [ css [ absolute, inset_x_0, bottom_0, h_1over2 ] ] []
        , div [ css [ max_w_7xl, mx_auto, lg [ px_8 ], sm [ px_6 ] ] ]
            [ div [ css [ relative, shadow_xl, sm [ rounded_2xl, overflow_hidden ] ] ]
                [ div [ css [ absolute, inset_0 ] ]
                    [ img [ src model.bg.src, alt model.bg.alt, css [ h_full, w_full, object_cover ] ] []
                    , div [ css [ absolute, inset_0, bg_gradient_to_r, from_green_200, to_indigo_700, mix_blend_multiply ] ] []
                    ]
                , div [ css [ relative, px_4, py_16, lg [ py_32, px_8 ], sm [ px_6, py_24 ] ] ]
                    [ h1 [ css [ text_4xl, font_extrabold, tracking_tight, lg [ text_6xl ], sm [ text_5xl ] ] ]
                        [ span [ css [ block, text_white ] ] [ text model.title ]
                        ]
                    , p [ css [ mt_6, max_w_lg, text_xl, text_indigo_100 ] ] model.content
                    , div [ css [ mt_10 ] ]
                        [ div [ css [ space_y_4, sm [ space_y_0, inline_grid, grid_cols_1, gap_5 ] ] ] [ model.cta ]
                        ]
                    ]
                ]
            ]
        ]



-- DOCUMENTATION


docModel : Model msg
docModel =
    { bg = { src = "https://images.unsplash.com/photo-1521737852567-6949f3f9f2b5?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=2830&q=80&sat=-100", alt = "People working on laptops" }
    , title = "Take control of your customer support"
    , content = [ text "Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat fugiat aliqua." ]
    , cta = Link.white5 Color.indigo [ href "#" ] [ text "Get started" ]
    }


doc : Chapter x
doc =
    chapter "Hero"
        |> renderComponentList
            [ ( "basicSlice", basicSlice )
            , ( "backgroundImageSlice", backgroundImageSlice docModel )
            ]
