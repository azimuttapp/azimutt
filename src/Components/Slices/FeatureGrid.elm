module Components.Slices.FeatureGrid exposing (CardItemModel, CardModel, cardSlice, coloredSlice, doc)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, br, div, h2, h3, p, span, text)
import Html.Styled.Attributes exposing (class, css, href)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


coloredSlice : Html msg
coloredSlice =
    div [ css [ Tw.bg_gradient_to_r, Tw.from_green_800, Tw.to_indigo_700 ] ]
        [ div [ css [ Tw.max_w_4xl, Tw.mx_auto, Tw.px_4, Tw.py_16, Bp.sm [ Tw.px_6, Tw.pt_20, Tw.pb_24 ], Bp.lg [ Tw.max_w_7xl, Tw.pt_24, Tw.px_8 ] ] ]
            [ h2 [ css [ Tw.text_3xl, Tw.font_extrabold, Tw.text_white, Tw.tracking_tight ] ]
                [ text "Explore your SQL schema like never before" ]
            , p [ css [ Tw.mt_4, Tw.max_w_3xl, Tw.text_lg, Tw.text_purple_200 ] ]
                [ text "Your new weapons to dig into your schema:" ]
            , div [ css [ Tw.mt_12, Tw.grid, Tw.grid_cols_1, Tw.gap_x_6, Tw.gap_y_12, Tw.text_white, Bp.lg [ Tw.mt_16, Tw.grid_cols_3, Tw.gap_x_8, Tw.gap_y_16 ], Bp.sm [ Tw.grid_cols_2 ] ] ]
                [ item (Icon.outline Inbox [])
                    "Partial display"
                    [ text """Maybe the less impressive but most useful feature when you work with a schema with 20, 40 or even 400 or 1000 tables!
                              Seeing only what you need is vital to understand how it works. This is true for tables but also for columns and relations!""" ]
                , item (Icon.outline DocumentSearch [])
                    "Search"
                    [ text """Search is awesome, don't know where to start? Just type a few words and you will have related tables and columns ranked by relevance.
                              Looking at table and column names, but also comments, keys or relations.""" ]
                , item (Icon.outline Photograph [])
                    "Layouts"
                    [ text """Your database is probably supporting many use cases, why not save them and move from one to an other ?
                              Layouts are here for that: select tables and columns related to a feature and save them as a layout. So you can easily switch between them.""" ]
                , item (Icon.outline Link [])
                    "Relation exploration"
                    [ text """Start from a table and look at its relations to display more.
                              Outgoing, of course (foreign keys), but incoming ones also (foreign keys from other tables)!""" ]
                , item (Icon.outline Link [])
                    "Relation search"
                    [ text """Did you ever ask how to join two tables ?
                              Azimutt can help showing all the possible paths between two tables. But also between a table and a column!""" ]
                , item (Icon.outline Link [])
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


type alias CardModel msg =
    { header : String
    , title : String
    , description : String
    , cards : List (CardItemModel msg)
    }


type alias CardItemModel msg =
    { icon : Icon
    , title : String
    , description : List (Html msg)
    }


cardSlice : CardModel msg -> Html msg
cardSlice model =
    div [ css [ Tw.relative, Tw.bg_white, Tw.py_16, Bp.lg [ Tw.py_32 ], Bp.sm [ Tw.py_24 ] ] ]
        [ div [ css [ Tw.mx_auto, Tw.max_w_md, Tw.px_4, Tw.text_center, Bp.lg [ Tw.px_8, Tw.max_w_7xl ], Bp.sm [ Tw.max_w_3xl, Tw.px_6 ] ] ]
            [ h2 [ css [ Tw.text_base, Tw.font_semibold, Tw.tracking_wider, Tw.uppercase, Tw.bg_gradient_to_r, Tw.from_green_600, Tw.to_indigo_600, Tw.bg_clip_text, Tw.text_transparent ] ] [ text model.header ]
            , p [ css [ Tw.mt_2, Tw.text_3xl, Tw.font_extrabold, Tw.text_gray_900, Tw.tracking_tight, Bp.sm [ Tw.text_4xl ] ] ] [ text model.title ]
            , p [ css [ Tw.mt_5, Tw.max_w_prose, Tw.mx_auto, Tw.text_xl, Tw.text_gray_500 ] ] [ text model.description ]
            , div [ css [ Tw.mt_12 ] ]
                [ div [ css [ Tw.grid, Tw.grid_cols_1, Tw.gap_8, Bp.lg [ Tw.grid_cols_3 ], Bp.sm [ Tw.grid_cols_2 ] ] ]
                    (model.cards |> List.map card)
                ]
            ]
        ]


card : CardItemModel msg -> Html msg
card model =
    div [ css [ Tw.pt_6 ] ]
        [ div [ css [ Tw.flow_root, Tw.bg_gray_50, Tw.rounded_lg, Tw.px_6, Tw.pb_8 ] ]
            [ div [ css [ Tw.neg_mt_6 ] ]
                [ div []
                    [ span [ css [ Tw.inline_flex, Tw.items_center, Tw.justify_center, Tw.p_3, Tw.rounded_md, Tw.shadow_lg, Tw.bg_gradient_to_r, Tw.from_green_600, Tw.to_indigo_600 ] ] [ Icon.outline model.icon [ Tw.text_white ] ]
                    ]
                , h3 [ css [ Tw.mt_8, Tw.text_lg, Tw.font_medium, Tw.text_gray_900, Tw.tracking_tight ] ] [ text model.title ]
                , p [ css [ Tw.mt_5, Tw.text_base, Tw.text_gray_500 ] ] model.description
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
        [ { icon = CloudUpload, title = "Push to Deploy", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = LockClosed, title = "SSL Certificates", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Refresh, title = "Simple Queues", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = ShieldCheck, title = "Advanced Security", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Cog, title = "Powerful API", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        , { icon = Server, title = "Database Backups", description = [ text "Ac tincidunt sapien vehicula erat auctor pellentesque rhoncus. Et magna sit morbi lobortis." ] }
        ]
    }


doc : Chapter x
doc =
    chapter "FeatureGrid"
        |> renderComponentList
            [ ( "coloredSlice", coloredSlice )
            , ( "cardsSlice", cardSlice cardModel )
            ]
