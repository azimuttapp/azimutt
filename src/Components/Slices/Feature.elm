module Components.Slices.Feature exposing (featureChapter, featureListeSlice, featureSlice)

import Components.Atoms.Icon as Icon
import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, blockquote, br, div, footer, h2, h3, img, p, span, text)
import Html.Styled.Attributes exposing (alt, class, css, href, src)
import Libs.Html.Styled exposing (bText)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


featureSlice : Html msg
featureSlice =
    div [ css [ Tw.relative, Tw.pt_16, Tw.pb_32, Tw.overflow_hidden ] ]
        [ div [ css [ Bp.lg [ Tw.mx_auto, Tw.max_w_7xl, Tw.px_8, Tw.grid, Tw.grid_cols_2, Tw.grid_flow_col_dense, Tw.gap_24 ] ] ]
            [ div [ css [ Tw.px_4, Tw.max_w_xl, Tw.mx_auto, Bp.lg [ Tw.py_16, Tw.max_w_none, Tw.mx_0, Tw.px_0 ], Bp.sm [ Tw.px_6 ] ] ]
                [ div []
                    [ div [ css [ Tw.mt_6 ] ]
                        [ h2 [ css [ Tw.text_3xl, Tw.font_extrabold, Tw.tracking_tight, Tw.text_gray_900 ] ]
                            [ text "Explore your database schema" ]
                        , p [ css [ Tw.mt_4, Tw.text_lg, Tw.text_gray_500 ] ]
                            [ text """Not everyone has the opportunity to work on brand you application where you create everything, including the data model.
                                      Most of developers evolve and maintain existing applications with an already big schema, sometimes more than 50, 100 or even 500 tables.
                                      Finding the right tables and relations to work with can be hard, and sincerely, no tool really helps. Until now."""
                            , br [] []
                            , bText "Azimutt"
                            , text " allows you to explore your schema: search for relevant tables, follow the relations, hide less interesting columns and even find the paths between tables."
                            ]
                        , div [ css [ Tw.mt_6 ] ]
                            [ a [ href (Route.toHref Route.App), css [ Tw.inline_flex, Tw.bg_gradient_to_r, Tw.from_green_600, Tw.to_indigo_700, Tw.px_4, Tw.py_2, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.shadow_sm, Tw.text_white, Css.hover [ Tw.from_green_700, Tw.to_indigo_600, Tw.text_white ] ] ]
                                [ text "Get started" ]
                            ]
                        ]
                    ]
                , div [ css [ Tw.mt_8, Tw.border_t, Tw.border_gray_200, Tw.pt_6 ] ]
                    [ blockquote []
                        [ div []
                            [ p [ css [ Tw.text_base, Tw.text_gray_500 ] ]
                                [ text "“Using Azimutt is like having superpowers!”" ]
                            ]
                        , footer [ css [ Tw.mt_3 ] ]
                            [ div [ css [ Tw.flex, Tw.items_center, Tw.space_x_3 ] ]
                                [ div [ css [ Tw.flex_shrink_0 ] ]
                                    [ img [ src "https://loicknuchel.fr/assets/img/bg_header.jpg", alt "Loïc Knuchel picture", css [ Tw.h_6, Tw.w_6, Tw.rounded_full ] ] [] ]
                                , div [ css [ Tw.text_base, Tw.font_medium, Tw.text_gray_700 ] ]
                                    [ text "Loïc Knuchel, Principal Engineer @ Doctolib" ]
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ css [ Tw.mt_12, Bp.lg [ Tw.mt_0 ], Bp.sm [ Tw.mt_16 ] ] ]
                [ div [ css [ Tw.pl_4, Tw.neg_mr_48, Bp.lg [ Tw.px_0, Tw.m_0, Tw.relative, Tw.h_full ], Bp.md [ Tw.neg_mr_16 ], Bp.sm [ Tw.pl_6 ] ] ]
                    [ span [ class "img-swipe" ]
                        [ img [ src "/screenshot.png", alt "Azimutt screenshot", class "img-default", css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.left_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ] ] []
                        , img [ src "/screenshot-complex.png", alt "Azimutt screenshot", class "img-hover", css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.left_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ] ] []
                        ]
                    ]
                ]
            ]
        ]


featureListeSlice : Html msg
featureListeSlice =
    div [ css [ Tw.bg_gradient_to_r, Tw.from_green_800, Tw.to_indigo_700 ] ]
        [ div [ css [ Tw.max_w_4xl, Tw.mx_auto, Tw.px_4, Tw.py_16, Bp.lg [ Tw.max_w_7xl, Tw.pt_24, Tw.px_8 ], Bp.sm [ Tw.px_6, Tw.pt_20, Tw.pb_24 ] ] ]
            [ h2 [ css [ Tw.text_3xl, Tw.font_extrabold, Tw.text_white, Tw.tracking_tight ] ]
                [ text "Explore your SQL schema like never before" ]
            , p [ css [ Tw.mt_4, Tw.max_w_3xl, Tw.text_lg, Tw.text_purple_200 ] ]
                [ text "Your new weapons to dig into your schema:" ]
            , div [ css [ Tw.mt_12, Tw.grid, Tw.grid_cols_1, Tw.gap_x_6, Tw.gap_y_12, Tw.text_white, Bp.lg [ Tw.mt_16, Tw.grid_cols_3, Tw.gap_x_8, Tw.gap_y_16 ], Bp.sm [ Tw.grid_cols_2 ] ] ]
                [ item Icon.inbox
                    "Partial display"
                    [ text """Maybe the less impressive but most useful feature when you work with a schema with 20, 40 or even 400 or 1000 tables!
                              Seeing only what you need is vital to understand how it works. This is true for tables but also for columns and relations!""" ]
                , item Icon.documentSearch
                    "Search"
                    [ text """Search is awesome, don't know where to start? Just type a few words and you will have related tables and columns ranked by relevance.
                              Looking at table and column names, but also comments, keys or relations.""" ]
                , item Icon.photograph
                    "Layouts"
                    [ text """Your database is probably supporting many use cases, why not save them and move from one to an other ?
                              Layouts are here for that: select tables and columns related to a feature and save them as a layout. So you can easily switch between them.""" ]
                , item Icon.link
                    "Relation exploration"
                    [ text """Start from a table and look at its relations to display more.
                              Outgoing, of course (foreign keys), but incoming ones also (foreign keys from other tables)!""" ]
                , item Icon.link
                    "Relation search"
                    [ text """Did you ever ask how to join two tables ?
                              Azimutt can help showing all the possible paths between two tables. But also between a table and a column!""" ]
                , item Icon.link
                    "Lorem Ipsum"
                    [ text "You came this far ??? Awesome! You seem quite interested and ready to dig in ^^", br [] [], text """
                            The best you can do now is to """, a [ href (Route.toHref Route.App), class "link" ] [ text "try it out" ], text " right away :D" ]
                ]
            ]
        ]


item : Html msg -> String -> List (Html msg) -> Html msg
item icon title description =
    div []
        [ div []
            [ span [ css [ Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_12, Tw.w_12, Tw.rounded_md, Tw.bg_white, Tw.bg_opacity_10 ] ] [ icon ] ]
        , div [ css [ Tw.mt_6 ] ]
            [ h3 [ css [ Tw.text_lg, Tw.font_medium, Tw.text_white ] ] [ text title ]
            , p [ css [ Tw.mt_2, Tw.text_base, Tw.text_purple_200 ] ] description
            ]
        ]


featureChapter : Chapter x
featureChapter =
    chapter "Feature"
        |> renderComponentList
            [ ( "default", featureSlice )
            , ( "list", featureListeSlice )
            ]
