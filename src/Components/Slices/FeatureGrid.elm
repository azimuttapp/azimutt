module Components.Slices.FeatureGrid exposing (coloredSlice, doc)

import Components.Atoms.Icon as Icon
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, br, div, h2, h3, p, span, text)
import Html.Styled.Attributes exposing (class, css, href)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (bg_gradient_to_r, bg_opacity_10, bg_white, flex, font_extrabold, font_medium, from_green_800, gap_x_6, gap_x_8, gap_y_12, gap_y_16, grid, grid_cols_1, grid_cols_2, grid_cols_3, h_12, items_center, justify_center, max_w_3xl, max_w_4xl, max_w_7xl, mt_12, mt_16, mt_2, mt_4, mt_6, mx_auto, pb_24, pt_20, pt_24, px_4, px_6, px_8, py_16, rounded_md, text_3xl, text_base, text_lg, text_purple_200, text_white, to_indigo_700, tracking_tight, w_12)


coloredSlice : Html msg
coloredSlice =
    div [ css [ bg_gradient_to_r, from_green_800, to_indigo_700 ] ]
        [ div [ css [ max_w_4xl, mx_auto, px_4, py_16, sm [ px_6, pt_20, pb_24 ], lg [ max_w_7xl, pt_24, px_8 ] ] ]
            [ h2 [ css [ text_3xl, font_extrabold, text_white, tracking_tight ] ]
                [ text "Explore your SQL schema like never before" ]
            , p [ css [ mt_4, max_w_3xl, text_lg, text_purple_200 ] ]
                [ text "Your new weapons to dig into your schema:" ]
            , div [ css [ mt_12, grid, grid_cols_1, gap_x_6, gap_y_12, text_white, lg [ mt_16, grid_cols_3, gap_x_8, gap_y_16 ], sm [ grid_cols_2 ] ] ]
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
            [ span [ css [ flex, items_center, justify_center, h_12, w_12, rounded_md, bg_white, bg_opacity_10 ] ] [ icon ] ]
        , div [ css [ mt_6 ] ]
            [ h3 [ css [ text_lg, font_medium, text_white ] ] [ text title ]
            , p [ css [ mt_2, text_base, text_purple_200 ] ] description
            ]
        ]


doc : Chapter x
doc =
    chapter "FeatureGrid"
        |> renderComponentList
            [ ( "coloredSlice", coloredSlice )
            ]
