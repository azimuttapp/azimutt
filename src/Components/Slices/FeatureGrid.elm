module Components.Slices.FeatureGrid exposing (CardItemModel, CardModel, cardSlice, coloredSlice, doc)

import Components.Atoms.Icon as Icon
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, br, div, h2, h3, p, span, text)
import Html.Styled.Attributes exposing (class, css, href)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (bg_clip_text, bg_gradient_to_r, bg_gray_50, bg_opacity_10, bg_white, flex, flow_root, font_extrabold, font_medium, font_semibold, from_green_600, from_green_800, gap_8, gap_x_6, gap_x_8, gap_y_12, gap_y_16, grid, grid_cols_1, grid_cols_2, grid_cols_3, h_12, inline_flex, items_center, justify_center, max_w_3xl, max_w_4xl, max_w_7xl, max_w_md, max_w_prose, mt_12, mt_16, mt_2, mt_4, mt_5, mt_6, mt_8, mx_auto, neg_mt_6, p_3, pb_24, pb_8, pt_20, pt_24, pt_6, px_4, px_6, px_8, py_16, py_24, py_32, relative, rounded_lg, rounded_md, shadow_lg, text_3xl, text_4xl, text_base, text_center, text_gray_500, text_gray_900, text_lg, text_purple_200, text_transparent, text_white, text_xl, to_indigo_600, to_indigo_700, tracking_tight, tracking_wider, uppercase, w_12)


coloredSlice : Html msg
coloredSlice =
    div [ css [ bg_gradient_to_r, from_green_800, to_indigo_700 ] ]
        [ div [ css [ max_w_4xl, mx_auto, px_4, py_16, sm [ px_6, pt_20, pb_24 ], lg [ max_w_7xl, pt_24, px_8 ] ] ]
            [ h2 [ css [ text_3xl, font_extrabold, text_white, tracking_tight ] ]
                [ text "Explore your SQL schema like never before" ]
            , p [ css [ mt_4, max_w_3xl, text_lg, text_purple_200 ] ]
                [ text "Your new weapons to dig into your schema:" ]
            , div [ css [ mt_12, grid, grid_cols_1, gap_x_6, gap_y_12, text_white, lg [ mt_16, grid_cols_3, gap_x_8, gap_y_16 ], sm [ grid_cols_2 ] ] ]
                [ item (Icon.inbox 6 [])
                    "Partial display"
                    [ text """Maybe the less impressive but most useful feature when you work with a schema with 20, 40 or even 400 or 1000 tables!
                              Seeing only what you need is vital to understand how it works. This is true for tables but also for columns and relations!""" ]
                , item (Icon.documentSearch 6 [])
                    "Search"
                    [ text """Search is awesome, don't know where to start? Just type a few words and you will have related tables and columns ranked by relevance.
                              Looking at table and column names, but also comments, keys or relations.""" ]
                , item (Icon.photograph 6 [])
                    "Layouts"
                    [ text """Your database is probably supporting many use cases, why not save them and move from one to an other ?
                              Layouts are here for that: select tables and columns related to a feature and save them as a layout. So you can easily switch between them.""" ]
                , item (Icon.link 6 [])
                    "Relation exploration"
                    [ text """Start from a table and look at its relations to display more.
                              Outgoing, of course (foreign keys), but incoming ones also (foreign keys from other tables)!""" ]
                , item (Icon.link 6 [])
                    "Relation search"
                    [ text """Did you ever ask how to join two tables ?
                              Azimutt can help showing all the possible paths between two tables. But also between a table and a column!""" ]
                , item (Icon.link 6 [])
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


type alias CardModel msg =
    { header : String
    , title : String
    , description : String
    , cards : List (CardItemModel msg)
    }


type alias CardItemModel msg =
    { icon : Html msg
    , title : String
    , description : List (Html msg)
    }


cardSlice : CardModel msg -> Html msg
cardSlice model =
    div [ css [ relative, bg_white, py_16, lg [ py_32 ], sm [ py_24 ] ] ]
        [ div [ css [ mx_auto, max_w_md, px_4, text_center, lg [ px_8, max_w_7xl ], sm [ max_w_3xl, px_6 ] ] ]
            [ h2 [ css [ text_base, font_semibold, tracking_wider, uppercase, bg_gradient_to_r, from_green_600, to_indigo_600, bg_clip_text, text_transparent ] ] [ text model.header ]
            , p [ css [ mt_2, text_3xl, font_extrabold, text_gray_900, tracking_tight, sm [ text_4xl ] ] ] [ text model.title ]
            , p [ css [ mt_5, max_w_prose, mx_auto, text_xl, text_gray_500 ] ] [ text model.description ]
            , div [ css [ mt_12 ] ]
                [ div [ css [ grid, grid_cols_1, gap_8, lg [ grid_cols_3 ], sm [ grid_cols_2 ] ] ]
                    (model.cards |> List.map card)
                ]
            ]
        ]


card : CardItemModel msg -> Html msg
card model =
    div [ css [ pt_6 ] ]
        [ div [ css [ flow_root, bg_gray_50, rounded_lg, px_6, pb_8 ] ]
            [ div [ css [ neg_mt_6 ] ]
                [ div []
                    [ span [ css [ inline_flex, items_center, justify_center, p_3, rounded_md, shadow_lg, bg_gradient_to_r, from_green_600, to_indigo_600 ] ] [ model.icon ]
                    ]
                , h3 [ css [ mt_8, text_lg, font_medium, text_gray_900, tracking_tight ] ] [ text model.title ]
                , p [ css [ mt_5, text_base, text_gray_500 ] ] model.description
                ]
            ]
        ]



-- DOCUMENTATION


cardModel : CardModel msg
cardModel =
    { header = "Deploy faster"
    , title = "Everything you need to deploy your app"
    , description = "Phasellus lorem quam molestie id quisque diam aenean nulla in. Accumsan in quis quis nunc, ullamcorper malesuada. Eleifend condimentum id viverra nulla."
    , cards =
        [ { icon = Icon.cloudUpload 6 [ text_white ], title = "Push to Deploy", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Icon.lockClosed 6 [ text_white ], title = "SSL Certificates", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Icon.refresh 6 [ text_white ], title = "Simple Queues", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Icon.shieldCheck 6 [ text_white ], title = "Advanced Security", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Icon.cog 6 [ text_white ], title = "Powerful API", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Icon.server 6 [ text_white ], title = "Database Backups", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        ]
    }


doc : Chapter x
doc =
    chapter "FeatureGrid"
        |> renderComponentList
            [ ( "coloredSlice", coloredSlice )
            , ( "cardsSlice", cardSlice cardModel )
            ]
