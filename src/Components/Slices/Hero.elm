module Components.Slices.Hero exposing (Model, backgroundImageSlice, basicSlice, doc)

import Components.Atoms.Dots as Dots
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Atoms.Link as Link
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Gen.Route as Route
import Html exposing (Html, a, button, div, h1, img, main_, nav, p, span, text)
import Html.Attributes exposing (alt, href, src, type_)
import Html.Styled exposing (fromUnstyled, toUnstyled)
import Libs.Html.Attributes exposing (ariaExpanded, ariaHidden, ariaLabel, classes)
import Libs.Models exposing (Image)
import Libs.Models.Color as Color
import Libs.Tailwind exposing (focus, hover, lg, md, sm, xl)


basicSlice : Html msg
basicSlice =
    div [ classes [ "relative bg-gray-50 overflow-hidden" ] ]
        [ div [ classes [ "hidden", sm "block absolute inset-y-0 h-full w-full" ], ariaHidden True ]
            [ div [ classes [ "relative h-full max-w-7xl mx-auto" ] ]
                [ Dots.dots "f210dbf6-a58d-4871-961e-36d5016a0f49" 404 784 "right-full translate-y-1/4 translate-x-1/4 lg:translate-x-1/2"
                , Dots.dots "5d0dd344-b041-4d26-bec4-8d33ea57ec9b" 404 784 "left-full -translate-y-3/4 -translate-x-1/4 lg:-translate-x-1/2 md:-translate-y-1/2"
                ]
            ]
        , div [ classes [ "relative pt-6 pb-16", sm "pb-24" ] ]
            [ div []
                [ div [ classes [ "max-w-7xl mx-auto px-4", sm "px-6" ] ]
                    [ nav [ classes [ "relative flex items-center justify-between", md "justify-center", sm "h-10" ], ariaLabel "Global" ]
                        [ div [ classes [ "flex items-center flex-1", md "absolute inset-y-0 left-0" ] ]
                            [ div [ classes [ "flex items-center justify-between w-full", md "w-auto" ] ]
                                [ a [ href "#" ]
                                    [ span [ classes [ "sr-only" ] ] [ text "Workflow" ]
                                    , img [ src "/logo.svg", alt "", classes [ "h-8 w-auto", sm "h-10" ] ] []
                                    ]
                                , div [ classes [ "-mr-2 flex items-center", md "hidden" ] ]
                                    [ button [ type_ "button", classes [ "bg-gray-50 rounded-md p-2 inline-flex items-center justify-center text-gray-400", focus "outline-none ring-2 ring-inset ring-indigo-500", hover "text-gray-500 bg-gray-100" ], ariaExpanded False ]
                                        [ span [ classes [ "sr-only" ] ] [ text "Open main menu" ]
                                        , Icon.outline Menu [] |> toUnstyled
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                , div [ classes [ "absolute top-0 inset-x-0 p-2 transition transform origin-top-right", md "hidden" ] ]
                    [ div [ classes [ "rounded-lg shadow-md bg-white ring-1 ring-black ring-opacity-5 overflow-hidden" ] ]
                        [ div [ classes [ "px-5 pt-4 flex items-center justify-between" ] ]
                            [ div []
                                [ img [ src "/logo.svg", alt "Azimutt logo", classes [ "h-8 w-auto" ] ] []
                                ]
                            , div [ classes [ "-mr-2" ] ]
                                [ button [ type_ "button", classes [ "bg-white rounded-md p-2 inline-flex items-center justify-center text-gray-400", focus "outline-none ring-2 ring-inset ring-indigo-500", hover "text-gray-500 bg-gray-100" ] ]
                                    [ span [ classes [ "sr-only" ] ]
                                        [ text "Close menu" ]
                                    , Icon.outline X [] |> toUnstyled
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            , main_ [ classes [ "mt-16 mx-auto max-w-7xl px-4", sm "mt-24" ] ]
                [ div [ classes [ "text-center" ] ]
                    [ h1 [ classes [ "text-4xl tracking-tight font-extrabold text-gray-900", md "text-6xl", sm "text-5xl" ] ]
                        [ span [ classes [ "block", xl "inline" ] ]
                            [ text "Explore your " ]
                        , span [ classes [ "block text-blue-600", xl "inline" ] ]
                            [ text "database schema" ]
                        ]
                    , p [ classes [ "mt-3 max-w-md mx-auto text-base text-gray-500", md "mt-5 text-xl max-w-3xl", sm "text-lg" ] ]
                        [ text "Easily visualize your database schema and see how everything fits together." ]
                    , div [ classes [ "mt-5 max-w-md mx-auto", md "mt-8", sm "flex justify-center" ] ]
                        [ div [ classes [ "rounded-md shadow" ] ]
                            [ a [ href (Route.toHref Route.App), classes [ "w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600", hover "bg-blue-800", md "py-4 text-lg px-10" ] ]
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
    div [ classes [ "relative" ] ]
        [ div [ classes [ "absolute inset-x-0 bottom-0 h-1/2" ] ] []
        , div [ classes [ "max-w-7xl mx-auto", lg "px-8", sm "px-6" ] ]
            [ div [ classes [ "relative shadow-xl", sm "rounded-2xl overflow-hidden" ] ]
                [ div [ classes [ "absolute inset-0" ] ]
                    [ img [ src model.bg.src, alt model.bg.alt, classes [ "h-full w-full object-cover" ] ] []
                    , div [ classes [ "absolute inset-0 bg-gradient-to-r from-green-200 to-indigo-700 mix-blend-multiply" ] ] []
                    ]
                , div [ classes [ "relative px-4 py-16", lg "py-32 px-8", sm "px-6 py-24" ] ]
                    [ h1 [ classes [ "text-4xl font-extrabold tracking-tight", lg "text-6xl", sm "text-5xl" ] ]
                        [ span [ classes [ "block text-white" ] ] [ text model.title ]
                        ]
                    , p [ classes [ "mt-6 max-w-lg text-xl text-indigo-100" ] ] model.content
                    , div [ classes [ "mt-10" ] ]
                        [ div [ classes [ "space-y-4", sm "space-y-0 inline-grid grid-cols-1 gap-5" ] ] [ model.cta ]
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
            [ ( "basicSlice", basicSlice |> fromUnstyled )
            , ( "backgroundImageSlice", backgroundImageSlice docModel |> fromUnstyled )
            ]
