module Components.Slices.FeatureSideBySide exposing (Description, Model, Position(..), Quote, doc, imageSlice, imageSwapSlice)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css exposing (Style, hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, blockquote, div, footer, h2, img, p, span, text)
import Html.Styled.Attributes exposing (alt, class, css, href, src)
import Libs.Html.Styled.Attributes exposing (track)
import Libs.Maybe as M
import Libs.Models exposing (Image, TrackedLink)
import Tailwind.Breakpoints exposing (lg, md, sm)
import Tailwind.Utilities exposing (absolute, bg_gradient_to_r, border, border_gray_200, border_t, border_transparent, col_start_1, col_start_2, flex, flex_shrink_0, font_extrabold, font_medium, from_green_600, from_green_700, gap_24, grid, grid_cols_2, grid_flow_col_dense, h_12, h_6, h_full, inline_flex, items_center, justify_center, left_0, m_0, max_w_7xl, max_w_none, max_w_xl, mt_0, mt_12, mt_16, mt_3, mt_4, mt_6, mt_8, mx_0, mx_auto, neg_ml_16, neg_ml_48, neg_mr_16, neg_mr_48, overflow_hidden, pb_32, pl_4, pl_6, pr_4, pr_6, pt_6, px_0, px_4, px_6, px_8, py_2, py_32, relative, right_0, ring_1, ring_black, ring_opacity_5, rounded_full, rounded_md, rounded_xl, shadow_sm, shadow_xl, space_x_3, text_3xl, text_base, text_gray_500, text_gray_700, text_gray_900, text_lg, text_white, to_indigo_600, to_indigo_700, tracking_tight, w_12, w_6, w_auto, w_full)


type alias Model msg =
    { image : Image
    , imagePosition : Position
    , icon : Maybe Icon
    , description : Description msg
    , cta : Maybe TrackedLink
    , quote : Maybe Quote
    }


type Position
    = Left
    | Right


type alias Description msg =
    { title : String, content : List (Html msg) }


type alias Quote =
    { text : String, author : String, avatar : Image }


imageSlice : Model msg -> Html msg
imageSlice model =
    slice model imageLeft imageRight


imageSwapSlice : Image -> Model msg -> Html msg
imageSwapSlice swap model =
    slice model (imageLeftSwap swap) (imageRightSwap swap)


slice : Model msg -> (Style -> Image -> Html msg) -> (Style -> Image -> Html msg) -> Html msg
slice model buildImageLeft buildImageRight =
    div [ css [ pb_32, relative, overflow_hidden ] ]
        [ div [ css [ lg [ mx_auto, max_w_7xl, px_8, grid, grid_cols_2, grid_flow_col_dense, gap_24 ] ] ]
            (case model.imagePosition of
                Left ->
                    [ details col_start_2 model, buildImageLeft col_start_1 model.image ]

                Right ->
                    [ details col_start_1 model, buildImageRight col_start_2 model.image ]
            )
        ]


imageLeft : Style -> Image -> Html msg
imageLeft position image =
    div [ css [ mt_12, sm [ mt_16 ], lg [ mt_0, position ] ] ]
        [ div [ css [ pr_4, neg_ml_48, sm [ pr_6 ], md [ neg_ml_16 ], lg [ px_0, m_0, relative, h_full ] ] ]
            [ img [ css [ w_full, rounded_xl, shadow_xl, ring_1, ring_black, ring_opacity_5, lg [ absolute, right_0, h_full, w_auto, max_w_none ] ], src image.src, alt image.alt ] []
            ]
        ]


imageRight : Style -> Image -> Html msg
imageRight position image =
    div [ css [ mt_12, sm [ mt_16 ], lg [ mt_0, position ] ] ]
        [ div [ css [ pl_4, neg_mr_48, sm [ pl_6 ], md [ neg_mr_16 ], lg [ px_0, m_0, relative, h_full ] ] ]
            [ img [ css [ w_full, rounded_xl, shadow_xl, ring_1, ring_black, ring_opacity_5, lg [ absolute, left_0, h_full, w_auto, max_w_none ] ], src image.src, alt image.alt ] []
            ]
        ]


imageLeftSwap : Image -> Style -> Image -> Html msg
imageLeftSwap swap position base =
    div [ css [ mt_12, sm [ mt_16 ], lg [ mt_0, position ] ] ]
        [ div [ css [ pr_4, neg_ml_48, sm [ pr_6 ], md [ neg_ml_16 ], lg [ px_0, m_0, relative, h_full ] ] ]
            [ span [ class "img-swipe" ]
                [ img [ css [ w_full, rounded_xl, shadow_xl, ring_1, ring_black, ring_opacity_5, lg [ absolute, right_0, h_full, w_auto, max_w_none ] ], src base.src, alt base.alt, class "img-default" ] []
                , img [ css [ w_full, rounded_xl, shadow_xl, ring_1, ring_black, ring_opacity_5, lg [ absolute, right_0, h_full, w_auto, max_w_none ] ], src swap.src, alt swap.alt, class "img-hover" ] []
                ]
            ]
        ]


imageRightSwap : Image -> Style -> Image -> Html msg
imageRightSwap swap position base =
    div [ css [ mt_12, sm [ mt_16 ], lg [ mt_0, position ] ] ]
        [ div [ css [ pl_4, neg_mr_48, sm [ pl_6 ], md [ neg_mr_16 ], lg [ px_0, m_0, relative, h_full ] ] ]
            [ span [ class "img-swipe" ]
                [ img [ css [ w_full, rounded_xl, shadow_xl, ring_1, ring_black, ring_opacity_5, lg [ absolute, left_0, h_full, w_auto, max_w_none ] ], src base.src, alt base.alt, class "img-default" ] []
                , img [ css [ w_full, rounded_xl, shadow_xl, ring_1, ring_black, ring_opacity_5, lg [ absolute, left_0, h_full, w_auto, max_w_none ] ], src swap.src, alt swap.alt, class "img-hover" ] []
                ]
            ]
        ]


details : Style -> Model msg -> Html msg
details position model =
    div [ css [ px_4, max_w_xl, mx_auto, sm [ px_6 ], lg [ py_32, max_w_none, mx_0, px_0, position ] ] ]
        (List.filterMap identity
            [ model.icon |> Maybe.map featureIcon
            , Just model.description |> Maybe.map featureDescription
            , model.cta |> Maybe.map featureCta
            , model.quote |> Maybe.map featureQuote
            ]
        )


featureIcon : Icon -> Html msg
featureIcon icon =
    span [ css [ h_12, w_12, rounded_md, flex, items_center, justify_center, bg_gradient_to_r, from_green_600, to_indigo_600 ] ] [ Icon.view icon [ text_white ] ]


featureDescription : Description msg -> Html msg
featureDescription d =
    div [ css [ mt_6 ] ]
        [ h2 [ css [ text_3xl, font_extrabold, tracking_tight, text_gray_900 ] ] [ text d.title ]
        , p [ css [ mt_4, text_lg, text_gray_500 ] ] d.content
        ]


featureCta : TrackedLink -> Html msg
featureCta cta =
    div [ css [ mt_6 ] ]
        [ a
            ([ href cta.url
             , css [ inline_flex, px_4, py_2, border, border_transparent, text_base, font_medium, rounded_md, shadow_sm, text_white, bg_gradient_to_r, from_green_600, to_indigo_600, hover [ text_white, from_green_700, to_indigo_700 ] ]
             ]
                ++ (cta.track |> M.mapOrElse track [])
            )
            [ text cta.text ]
        ]


featureQuote : Quote -> Html msg
featureQuote quote =
    div [ css [ mt_8, border_t, border_gray_200, pt_6 ] ]
        [ blockquote []
            [ div []
                [ p [ css [ text_base, text_gray_500 ] ]
                    [ text ("“" ++ quote.text ++ "”") ]
                ]
            , footer [ css [ mt_3 ] ]
                [ div [ css [ flex, items_center, space_x_3 ] ]
                    [ div [ css [ flex_shrink_0 ] ]
                        [ img [ src quote.avatar.src, alt quote.avatar.alt, css [ h_6, w_6, rounded_full ] ] [] ]
                    , div [ css [ text_base, font_medium, text_gray_700 ] ]
                        [ text quote.author ]
                    ]
                ]
            ]
        ]



-- DOCUMENTATION


dsModelFull : Model msg
dsModelFull =
    { image = { src = "https://tailwindui.com/img/component-images/inbox-app-screenshot-2.jpg", alt = "Customer profile user interface" }
    , imagePosition = Right
    , icon = Just Sparkles
    , description =
        { title = "Better understand your customers"
        , content = [ text "Semper curabitur ullamcorper posuere nunc sed. Ornare iaculis bibendum malesuada faucibus lacinia porttitor. Pulvinar laoreet sagittis viverra duis. In venenatis sem arcu pretium pharetra at. Lectus viverra dui tellus ornare pharetra." ]
        }
    , cta = Just { url = Route.toHref Route.App, text = "Get started", track = Nothing }
    , quote =
        Just
            { text = "Cras velit quis eros eget rhoncus lacus ultrices sed diam. Sit orci risus aenean curabitur donec aliquet. Mi venenatis in euismod ut."
            , author = "Marcia Hill, Digital Marketing Manager"
            , avatar = { src = "https://images.unsplash.com/photo-1509783236416-c9ad59bae472?ixlib=rb-=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=8&w=1024&h=1024&q=80", alt = "Georges" }
            }
    }


dsSwapImage : Image
dsSwapImage =
    { src = "https://tailwindui.com/img/component-images/top-nav-with-multi-column-layout-screenshot.jpg", alt = "Basic text" }


doc : Chapter x
doc =
    chapter "FeatureSideBySide"
        |> renderComponentList
            [ ( "imageSlice", imageSlice dsModelFull )
            , ( "imageSlice, imagePosition left", imageSlice { dsModelFull | imagePosition = Left } )
            , ( "imageSlice, no quote", imageSlice { dsModelFull | quote = Nothing } )
            , ( "imageSlice, no quote, no cta", imageSlice { dsModelFull | cta = Nothing, quote = Nothing } )
            , ( "imageSlice, no quote, no cta, no icon", imageSlice { dsModelFull | icon = Nothing, cta = Nothing, quote = Nothing } )
            , ( "imageSwapSlice", imageSwapSlice dsSwapImage dsModelFull )
            , ( "imageSwapSlice, imagePosition left", imageSwapSlice dsSwapImage { dsModelFull | imagePosition = Left } )
            ]
