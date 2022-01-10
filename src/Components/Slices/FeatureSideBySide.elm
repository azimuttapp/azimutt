module Components.Slices.FeatureSideBySide exposing (Description, Model, Position(..), Quote, doc, imageSlice, imageSwapSlice)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html.Styled exposing (Html, a, blockquote, div, footer, h2, img, p, span, text)
import Html.Styled.Attributes exposing (alt, class, css, href, src)
import Libs.Html.Styled.Attributes exposing (track)
import Libs.Maybe as M
import Libs.Models exposing (Image, TrackedLink)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


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


slice : Model msg -> (Css.Style -> Image -> Html msg) -> (Css.Style -> Image -> Html msg) -> Html msg
slice model buildImageLeft buildImageRight =
    div [ css [ Tw.pb_32, Tw.relative, Tw.overflow_hidden ] ]
        [ div [ css [ Bp.lg [ Tw.mx_auto, Tw.max_w_7xl, Tw.px_8, Tw.grid, Tw.grid_cols_2, Tw.grid_flow_col_dense, Tw.gap_24 ] ] ]
            (case model.imagePosition of
                Left ->
                    [ details Tw.col_start_2 model, buildImageLeft Tw.col_start_1 model.image ]

                Right ->
                    [ details Tw.col_start_1 model, buildImageRight Tw.col_start_2 model.image ]
            )
        ]


imageLeft : Css.Style -> Image -> Html msg
imageLeft position image =
    div [ css [ Tw.mt_12, Bp.sm [ Tw.mt_16 ], Bp.lg [ Tw.mt_0, position ] ] ]
        [ div [ css [ Tw.pr_4, Tw.neg_ml_48, Bp.sm [ Tw.pr_6 ], Bp.md [ Tw.neg_ml_16 ], Bp.lg [ Tw.px_0, Tw.m_0, Tw.relative, Tw.h_full ] ] ]
            [ img [ css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.right_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ], src image.src, alt image.alt ] []
            ]
        ]


imageRight : Css.Style -> Image -> Html msg
imageRight position image =
    div [ css [ Tw.mt_12, Bp.sm [ Tw.mt_16 ], Bp.lg [ Tw.mt_0, position ] ] ]
        [ div [ css [ Tw.pl_4, Tw.neg_mr_48, Bp.sm [ Tw.pl_6 ], Bp.md [ Tw.neg_mr_16 ], Bp.lg [ Tw.px_0, Tw.m_0, Tw.relative, Tw.h_full ] ] ]
            [ img [ css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.left_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ], src image.src, alt image.alt ] []
            ]
        ]


imageLeftSwap : Image -> Css.Style -> Image -> Html msg
imageLeftSwap swap position base =
    div [ css [ Tw.mt_12, Bp.sm [ Tw.mt_16 ], Bp.lg [ Tw.mt_0, position ] ] ]
        [ div [ css [ Tw.pr_4, Tw.neg_ml_48, Bp.sm [ Tw.pr_6 ], Bp.md [ Tw.neg_ml_16 ], Bp.lg [ Tw.px_0, Tw.m_0, Tw.relative, Tw.h_full ] ] ]
            [ span [ class "img-swipe" ]
                [ img [ css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.right_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ], src base.src, alt base.alt, class "img-default" ] []
                , img [ css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.right_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ], src swap.src, alt swap.alt, class "img-hover" ] []
                ]
            ]
        ]


imageRightSwap : Image -> Css.Style -> Image -> Html msg
imageRightSwap swap position base =
    div [ css [ Tw.mt_12, Bp.sm [ Tw.mt_16 ], Bp.lg [ Tw.mt_0, position ] ] ]
        [ div [ css [ Tw.pl_4, Tw.neg_mr_48, Bp.sm [ Tw.pl_6 ], Bp.md [ Tw.neg_mr_16 ], Bp.lg [ Tw.px_0, Tw.m_0, Tw.relative, Tw.h_full ] ] ]
            [ span [ class "img-swipe" ]
                [ img [ css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.left_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ], src base.src, alt base.alt, class "img-default" ] []
                , img [ css [ Tw.w_full, Tw.rounded_xl, Tw.shadow_xl, Tw.ring_1, Tw.ring_black, Tw.ring_opacity_5, Bp.lg [ Tw.absolute, Tw.left_0, Tw.h_full, Tw.w_auto, Tw.max_w_none ] ], src swap.src, alt swap.alt, class "img-hover" ] []
                ]
            ]
        ]


details : Css.Style -> Model msg -> Html msg
details position model =
    div [ css [ Tw.px_4, Tw.max_w_xl, Tw.mx_auto, Bp.sm [ Tw.px_6 ], Bp.lg [ Tw.py_32, Tw.max_w_none, Tw.mx_0, Tw.px_0, position ] ] ]
        (List.filterMap identity
            [ model.icon |> Maybe.map featureIcon
            , Just model.description |> Maybe.map featureDescription
            , model.cta |> Maybe.map featureCta
            , model.quote |> Maybe.map featureQuote
            ]
        )


featureIcon : Icon -> Html msg
featureIcon icon =
    span [ css [ Tw.h_12, Tw.w_12, Tw.rounded_md, Tw.flex, Tw.items_center, Tw.justify_center, Tw.bg_gradient_to_r, Tw.from_green_600, Tw.to_indigo_600 ] ] [ Icon.outline icon [ Tw.text_white ] ]


featureDescription : Description msg -> Html msg
featureDescription d =
    div [ css [ Tw.mt_6 ] ]
        [ h2 [ css [ Tw.text_3xl, Tw.font_extrabold, Tw.tracking_tight, Tw.text_gray_900 ] ] [ text d.title ]
        , p [ css [ Tw.mt_4, Tw.text_lg, Tw.text_gray_500 ] ] d.content
        ]


featureCta : TrackedLink -> Html msg
featureCta cta =
    div [ css [ Tw.mt_6 ] ]
        [ a
            ([ href cta.url
             , css [ Tw.inline_flex, Tw.px_4, Tw.py_2, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.shadow_sm, Tw.text_white, Tw.bg_gradient_to_r, Tw.from_green_600, Tw.to_indigo_600, Css.hover [ Tw.text_white, Tw.from_green_700, Tw.to_indigo_700 ] ]
             ]
                ++ (cta.track |> M.mapOrElse track [])
            )
            [ text cta.text ]
        ]


featureQuote : Quote -> Html msg
featureQuote quote =
    div [ css [ Tw.mt_8, Tw.border_t, Tw.border_gray_200, Tw.pt_6 ] ]
        [ blockquote []
            [ div []
                [ p [ css [ Tw.text_base, Tw.text_gray_500 ] ]
                    [ text ("“" ++ quote.text ++ "”") ]
                ]
            , footer [ css [ Tw.mt_3 ] ]
                [ div [ css [ Tw.flex, Tw.items_center, Tw.space_x_3 ] ]
                    [ div [ css [ Tw.flex_shrink_0 ] ]
                        [ img [ src quote.avatar.src, alt quote.avatar.alt, css [ Tw.h_6, Tw.w_6, Tw.rounded_full ] ] [] ]
                    , div [ css [ Tw.text_base, Tw.font_medium, Tw.text_gray_700 ] ]
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
