module Components.Organisms.Header exposing (Brand, ExtLink, LeftLinksModel, LeftLinksTheme, RightLinksModel, RightLinksTheme, doc, leftLinks, leftLinksIndigo, leftLinksWhite, rightLinks, rightLinksIndigo, rightLinksWhite)

import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, div, header, img, nav, span, text)
import Html.Attributes exposing (alt, class, href, src)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (ariaLabel, css)
import Libs.Models exposing (Image, Link)
import Libs.Tailwind exposing (TwClass, batch, hover)


type alias RightLinksModel msg =
    { brand : Brand
    , links : List (ExtLink msg)
    }


type alias Brand =
    { img : Image, link : Link }


type alias ExtLink msg =
    { url : String, content : List (Html msg), external : Bool }


type alias RightLinksTheme =
    { bg : TwClass, text : TwClass }


rightLinksWhite : RightLinksModel msg -> Html msg
rightLinksWhite model =
    rightLinks { bg = "bg-white", text = batch [ "text-gray-500", hover [ "text-gray-900" ] ] } model


rightLinksIndigo : RightLinksModel msg -> Html msg
rightLinksIndigo model =
    rightLinks { bg = "bg-indigo-600", text = batch [ "text-white", hover [ "text-indigo-50" ] ] } model


rightLinks : RightLinksTheme -> RightLinksModel msg -> Html msg
rightLinks theme model =
    header [ class theme.bg ]
        [ div [ class "flex justify-between items-center max-w-7xl mx-auto px-4 py-6 lg:px-8 md:justify-start md:space-x-10 sm:px-6" ]
            [ a [ href model.brand.link.url, class "flex justify-start items-center font-medium lg:w-0 lg:flex-1" ]
                [ img [ src model.brand.img.src, alt model.brand.img.alt, class "h-8 w-auto sm:h-10" ] []
                , span [ css [ "ml-3 text-2xl", theme.text ] ] [ text model.brand.link.text ]
                ]
            , nav [ class "hidden space-x-10 md:flex" ]
                (model.links
                    |> List.map
                        (\l ->
                            if l.external then
                                extLink l.url [ css [ "text-base font-medium", theme.text ] ] l.content

                            else
                                a [ href l.url, css [ "text-base font-medium", theme.text ] ] l.content
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
    { bg : TwClass, links : TwClass, primary : TwClass, secondary : TwClass }


leftLinksIndigo : LeftLinksModel -> Html msg
leftLinksIndigo model =
    leftLinks { bg = "bg-indigo-600", links = batch [ "text-white", hover [ "text-indigo-50" ] ], secondary = batch [ "text-white bg-indigo-500", hover [ "bg-opacity-75" ] ], primary = batch [ "text-indigo-600 bg-white", hover [ "bg-indigo-50" ] ] } model


leftLinksWhite : LeftLinksModel -> Html msg
leftLinksWhite model =
    leftLinks { bg = "bg-white", links = batch [ "text-gray-500", hover [ "text-gray-900" ] ], secondary = batch [ "text-gray-500", hover [ "text-gray-900" ] ], primary = batch [ "text-white bg-indigo-600", hover [ "bg-indigo-700" ] ] } model


leftLinks : LeftLinksTheme -> LeftLinksModel -> Html msg
leftLinks theme model =
    header [ class theme.bg ]
        [ nav [ class "max-w-7xl mx-auto px-4 lg:px-8 sm:px-6", ariaLabel "Top" ]
            [ div [ class "w-full py-6 flex items-center justify-between border-b border-indigo-500 lg:border-none" ]
                [ div [ class "flex items-center" ]
                    [ a [ href model.brand.link.url ] [ span [ class "sr-only" ] [ text model.brand.link.text ], img [ class "h-10 w-auto", src model.brand.img.src, alt model.brand.img.alt ] [] ]
                    , div [ class "hidden ml-10 space-x-8 lg:block" ]
                        (model.links |> List.map (\link -> a [ href link.url, css [ "text-base font-medium", theme.links ] ] [ text link.text ]))
                    ]
                , div [ class "ml-10 space-x-4" ]
                    [ a [ href model.secondary.url, css [ "inline-block py-2 px-4 border border-transparent rounded-md text-base font-medium", theme.secondary ] ] [ text model.secondary.text ]
                    , a [ href model.primary.url, css [ "inline-block py-2 px-4 border border-transparent rounded-md text-base font-medium", theme.primary ] ] [ text model.primary.text ]
                    ]
                ]
            , div [ class "py-4 flex flex-wrap justify-center space-x-6 lg:hidden" ]
                (model.links |> List.map (\link -> a [ href link.url, css [ "text-base font-medium", theme.links ] ] [ text link.text ]))
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
        |> Chapter.renderComponentList
            [ ( "rightLinksIndigo", rightLinksIndigo (rightLinksModel logoWhite) )
            , ( "rightLinksWhite", rightLinksWhite (rightLinksModel logoIndigo) )
            , ( "rightLinks", rightLinks { bg = "bg-white", text = "" } (rightLinksModel logoIndigo) )
            , ( "leftLinksIndigo", leftLinksIndigo (leftLinksModel logoWhite) )
            , ( "leftLinksWhite", leftLinksWhite (leftLinksModel logoIndigo) )
            , ( "leftLinks", leftLinks { bg = "bg-white", links = "", secondary = "", primary = "" } (leftLinksModel logoIndigo) )
            ]
