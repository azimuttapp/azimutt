module Components.Slices.Hero exposing (Model, backgroundImageSlice, basicSlice, doc)

import Components.Atoms.Dots as Dots
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Gen.Route as Route
import Html exposing (Html, a, button, div, h1, img, main_, nav, p, span, text)
import Html.Attributes exposing (alt, href, src, type_)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHidden, ariaLabel, css)
import Libs.Models exposing (Image)
import Libs.Models.Color as Color
import Libs.Tailwind exposing (focus, hover, lg, md, sm, xl)


basicSlice : Html msg
basicSlice =
    div [ css [ "relative bg-gray-50 overflow-hidden" ] ]
        [ div [ css [ "hidden", sm [ "block absolute inset-y-0 h-full w-full" ] ], ariaHidden True ]
            [ div [ css [ "relative h-full max-w-7xl mx-auto" ] ]
                [ Dots.dots "f210dbf6-a58d-4871-961e-36d5016a0f49" 404 784 "right-full translate-y-1/4 translate-x-1/4 lg:translate-x-1/2"
                , Dots.dots "5d0dd344-b041-4d26-bec4-8d33ea57ec9b" 404 784 "left-full -translate-y-3/4 -translate-x-1/4 lg:-translate-x-1/2 md:-translate-y-1/2"
                ]
            ]
        , div [ css [ "relative pt-6 pb-16", sm [ "pb-24" ] ] ]
            [ div []
                [ div [ css [ "max-w-7xl mx-auto px-4", sm [ "px-6" ] ] ]
                    [ nav [ css [ "relative flex items-center justify-between", sm [ "h-10" ], md [ "justify-center" ] ], ariaLabel "Global" ]
                        [ div [ css [ "flex items-center flex-1", md [ "absolute inset-y-0 left-0" ] ] ]
                            [ div [ css [ "flex items-center justify-between w-full", md [ "w-auto" ] ] ]
                                [ a [ href "#" ]
                                    [ span [ css [ "sr-only" ] ] [ text "Workflow" ]
                                    , img [ src "/logo.svg", alt "", css [ "h-8 w-auto", sm [ "h-10" ] ] ] []
                                    ]
                                , div [ css [ "-mr-2 flex items-center", md [ "hidden" ] ] ]
                                    [ button [ type_ "button", css [ "bg-gray-50 rounded-md p-2 inline-flex items-center justify-center text-gray-400", hover [ "text-gray-500 bg-gray-100" ], focus [ "outline-none ring-2 ring-inset ring-indigo-500" ] ], ariaExpanded False ]
                                        [ span [ css [ "sr-only" ] ] [ text "Open main menu" ]
                                        , Icon.outline Menu ""
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , div [ css [ "absolute top-0 inset-x-0 p-2 transition transform origin-top-right", md [ "hidden" ] ] ]
                    [ div [ css [ "rounded-lg shadow-md bg-white ring-1 ring-black ring-opacity-5 overflow-hidden" ] ]
                        [ div [ css [ "px-5 pt-4 flex items-center justify-between" ] ]
                            [ div []
                                [ img [ src "/logo.svg", alt "Azimutt logo", css [ "h-8 w-auto" ] ] []
                                ]
                            , div [ css [ "-mr-2" ] ]
                                [ button [ type_ "button", css [ "bg-white rounded-md p-2 inline-flex items-center justify-center text-gray-400", hover [ "text-gray-500 bg-gray-100" ], focus [ "outline-none ring-2 ring-inset ring-indigo-500" ] ] ]
                                    [ span [ css [ "sr-only" ] ]
                                        [ text "Close menu" ]
                                    , Icon.outline X ""
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            , main_ [ css [ "mt-16 mx-auto max-w-7xl px-4", sm [ "mt-24" ] ] ]
                [ div [ css [ "text-center" ] ]
                    [ h1 [ css [ "text-4xl tracking-tight font-extrabold text-gray-900", sm [ "text-5xl" ], md [ "text-6xl" ] ] ]
                        [ span [ css [ "block", xl [ "inline" ] ] ]
                            [ text "Explore your " ]
                        , span [ css [ "block text-blue-600", xl [ "inline" ] ] ]
                            [ text "database schema" ]
                        ]
                    , p [ css [ "mt-3 max-w-md mx-auto text-base text-gray-500", sm [ "text-lg" ], md [ "mt-5 text-xl max-w-3xl" ] ] ]
                        [ text "Easily visualize your database schema and see how everything fits together." ]
                    , div [ css [ "mt-5 max-w-md mx-auto", sm [ "flex justify-center" ], md [ "mt-8" ] ] ]
                        [ div [ css [ "rounded-md shadow" ] ]
                            [ a [ href (Route.toHref Route.App), css [ "w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600", hover [ "bg-blue-800" ], md [ "py-4 text-lg px-10" ] ] ]
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
    div [ css [ "relative" ] ]
        [ div [ css [ "absolute inset-x-0 bottom-0 h-1/2" ] ] []
        , div [ css [ "max-w-7xl mx-auto", sm [ "px-6" ], lg [ "px-8" ] ] ]
            [ div [ css [ "relative shadow-xl", sm [ "rounded-2xl overflow-hidden" ] ] ]
                [ div [ css [ "absolute inset-0" ] ]
                    [ img [ src model.bg.src, alt model.bg.alt, css [ "h-full w-full object-cover" ] ] []
                    , div [ css [ "absolute inset-0 bg-gradient-to-r from-green-200 to-indigo-700 mix-blend-multiply" ] ] []
                    ]
                , div [ css [ "relative px-4 py-16", sm [ "px-6 py-24" ], lg [ "py-32 px-8" ] ] ]
                    [ h1 [ css [ "text-4xl font-extrabold tracking-tight", sm [ "text-5xl" ], lg [ "text-6xl" ] ] ]
                        [ span [ css [ "block text-white" ] ] [ text model.title ]
                        ]
                    , p [ css [ "mt-6 max-w-lg text-xl text-indigo-100" ] ] model.content
                    , div [ css [ "mt-10" ] ]
                        [ div [ css [ "space-y-4", sm [ "space-y-0 inline-grid grid-cols-1 gap-5" ] ] ] [ model.cta ]
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
