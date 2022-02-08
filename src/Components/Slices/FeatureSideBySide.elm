module Components.Slices.FeatureSideBySide exposing (Description, Model, Position(..), Quote, doc, imageSlice, imageSwapSlice)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html, a, blockquote, div, footer, h2, img, p, span, text)
import Html.Attributes exposing (alt, class, href, src)
import Libs.Bool as B
import Libs.Html.Attributes exposing (css, track)
import Libs.Maybe as M
import Libs.Models exposing (Image, TrackedLink)
import Libs.Tailwind exposing (hover, lg, md, sm)


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


slice : Model msg -> (Image -> Html msg) -> (Image -> Html msg) -> Html msg
slice model buildImageLeft buildImageRight =
    div [ css [ "pb-32 relative overflow-hidden" ] ]
        [ div [ css [ lg [ "mx-auto max-w-7xl px-8 grid grid-cols-2 grid-flow-col-dense gap-24" ] ] ]
            [ details model.imagePosition model, B.cond (model.imagePosition == Left) buildImageLeft buildImageRight model.image ]
        ]


imageLeft : Image -> Html msg
imageLeft image =
    div [ css [ "mt-12", sm [ "mt-16" ], lg [ "col-start-1" ] ] ]
        [ div [ css [ "pr-4 -ml-48", sm [ "pr-6" ], md [ "-ml-16" ], lg [ "px-0 m-0 relative h-full" ] ] ]
            [ img [ css [ "w-full rounded-xl shadow-xl ring-1 ring-black ring-opacity-5", lg [ "absolute right-0 h-full w-auto max-w-none" ] ], src image.src, alt image.alt ] []
            ]
        ]


imageRight : Image -> Html msg
imageRight image =
    div [ css [ "mt-12", sm [ "mt-16" ], lg [ "col-start-2" ] ] ]
        [ div [ css [ "pl-4 -mr-48", sm [ "pl-6" ], md [ "-mr-16" ], lg [ "px-0 m-0 relative h-full" ] ] ]
            [ img [ css [ "w-full rounded-xl shadow-xl ring-1 ring-black ring-opacity-5", lg [ "absolute left-0 h-full w-auto max-w-none" ] ], src image.src, alt image.alt ] []
            ]
        ]


imageLeftSwap : Image -> Image -> Html msg
imageLeftSwap swap base =
    div [ css [ "mt-12", sm [ "mt-16" ], lg [ "col-start-1" ] ] ]
        [ div [ css [ "pr-4 -ml-48", sm [ "pr-6" ], md [ "-ml-16" ], lg [ "px-0 m-0 relative h-full" ] ] ]
            [ span [ class "img-swipe" ]
                [ img [ css [ "w-full rounded-xl shadow-xl ring-1 ring-black ring-opacity-5", lg [ "absolute right-0 h-full w-auto max-w-none" ] ], src base.src, alt base.alt, class "img-default" ] []
                , img [ css [ "w-full rounded-xl shadow-xl ring-1 ring-black ring-opacity-5", lg [ "absolute right-0 h-full w-auto max-w-none" ] ], src swap.src, alt swap.alt, class "img-hover" ] []
                ]
            ]
        ]


imageRightSwap : Image -> Image -> Html msg
imageRightSwap swap base =
    div [ css [ "mt-12", sm [ "mt-16" ], lg [ "col-start-2" ] ] ]
        [ div [ css [ "pl-4 -mr-48", sm [ "pl-6" ], md [ "-mr-16" ], lg [ "px-0 m-0 relative h-full" ] ] ]
            [ span [ class "img-swipe" ]
                [ img [ css [ "w-full rounded-xl shadow-xl ring-1 ring-black ring-opacity-5", lg [ "absolute left-0 h-full w-auto max-w-none" ] ], src base.src, alt base.alt, class "img-default" ] []
                , img [ css [ "w-full rounded-xl shadow-xl ring-1 ring-black ring-opacity-5", lg [ "absolute left-0 h-full w-auto max-w-none" ] ], src swap.src, alt swap.alt, class "img-hover" ] []
                ]
            ]
        ]


details : Position -> Model msg -> Html msg
details position model =
    div [ css [ "px-4 max-w-xl mx-auto", sm [ "px-6" ], lg [ "py-32 max-w-none mx-0 px-0", B.cond (position == Right) "col-start-1" "col-start-2" ] ] ]
        (List.filterMap identity
            [ model.icon |> Maybe.map featureIcon
            , Just model.description |> Maybe.map featureDescription
            , model.cta |> Maybe.map featureCta
            , model.quote |> Maybe.map featureQuote
            ]
        )


featureIcon : Icon -> Html msg
featureIcon icon =
    span [ css [ "h-12 w-12 rounded-md flex items-center justify-center bg-gradient-to-r from-green-600 to-indigo-600" ] ] [ Icon.outline icon "text-white" ]


featureDescription : Description msg -> Html msg
featureDescription d =
    div [ css [ "mt-6" ] ]
        [ h2 [ css [ "text-3xl font-extrabold tracking-tight text-gray-900" ] ] [ text d.title ]
        , p [ css [ "mt-4 text-lg text-gray-500" ] ] d.content
        ]


featureCta : TrackedLink -> Html msg
featureCta cta =
    div [ css [ "mt-6" ] ]
        [ a
            ([ href cta.url
             , css [ "inline-flex px-4 py-2 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-gradient-to-r from-green-600 to-indigo-600", hover [ "text-white from-green-700 to-indigo-700" ] ]
             ]
                ++ (cta.track |> M.mapOrElse track [])
            )
            [ text cta.text ]
        ]


featureQuote : Quote -> Html msg
featureQuote quote =
    div [ css [ "mt-8 border-t border-gray-200 pt-6" ] ]
        [ blockquote []
            [ div []
                [ p [ css [ "text-base text-gray-500" ] ]
                    [ text ("“" ++ quote.text ++ "”") ]
                ]
            , footer [ css [ "mt-3" ] ]
                [ div [ css [ "flex items-center space-x-3" ] ]
                    [ div [ css [ "flex-shrink-0" ] ]
                        [ img [ src quote.avatar.src, alt quote.avatar.alt, css [ "h-6 w-6 rounded-full" ] ] [] ]
                    , div [ css [ "text-base font-medium text-gray-700" ] ]
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
    , cta = Just { url = "#", text = "Get started", track = Nothing }
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
