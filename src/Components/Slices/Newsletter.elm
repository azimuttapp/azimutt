module Components.Slices.Newsletter exposing (Form, Model, basicSlice, centered, doc, formDoc, small)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html exposing (Html, a, button, div, form, h2, input, label, p, text)
import Html.Attributes exposing (action, attribute, class, for, href, id, method, name, placeholder, rel, required, target, type_)
import Libs.Html.Attributes exposing (css)
import Libs.Tailwind as Tw exposing (focus, focus_ring_500, hover, lg, sm)


type alias Model msg =
    { form : Form
    , title : String
    , description : String
    , legalText : List (Html msg)
    }


type alias Form =
    { method : String
    , url : String
    , placeholder : String
    , cta : String
    }


basicSlice : Model msg -> Html msg
basicSlice model =
    div [ class "bg-white" ]
        [ div [ css [ "max-w-7xl mx-auto py-24 px-4", sm [ "px-6" ], lg [ "py-32 px-8 flex items-center" ] ] ]
            [ div [ css [ lg [ "w-0 flex-1" ] ] ]
                [ h2 [ css [ "text-3xl font-extrabold text-gray-900", sm [ "text-4xl" ] ] ] [ text model.title ]
                , p [ class "mt-3 max-w-3xl text-lg text-gray-500" ] [ text model.description ]
                ]
            , div [ css [ "mt-8", lg [ "mt-0 ml-8" ] ] ]
                [ form [ method model.form.method, action model.form.url, target "_blank", rel "noopener", css [ sm [ "flex" ] ] ]
                    [ label [ for "newsletter-email", class "sr-only" ] [ text model.form.placeholder ]
                    , input [ type_ "email", name "member[email]", id "newsletter-email", placeholder model.form.placeholder, attribute "autocomplete" "email", required True, css [ "w-full px-5 py-3 border border-gray-300 shadow-sm placeholder-gray-400 rounded-md", focus [ "ring-1 ring-indigo-500 border-indigo-500" ], sm [ "max-w-xs" ] ] ] []
                    , div [ css [ "mt-3 rounded-md shadow", sm [ "mt-0 ml-3 flex-shrink-0" ] ] ]
                        [ button [ type_ "submit", css [ "w-full flex items-center justify-center py-3 px-5 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600", hover [ "bg-indigo-700" ], focus_ring_500 Tw.indigo ] ]
                            [ text model.form.cta ]
                        ]
                    ]
                , p [ class "mt-3 text-sm text-gray-500" ] model.legalText
                ]
            ]
        ]


centered : Form -> Html msg
centered model =
    div [ class "max-w-prose mx-auto" ]
        [ form [ method model.method, action model.url, target "_blank", rel "noopener", css [ "justify-center", sm [ "flex" ] ] ]
            [ input [ type_ "email", name "member[email]", id "newsletter-email", placeholder model.placeholder, attribute "autocomplete" "email", required True, css [ "appearance-none w-full px-5 py-3 border border-gray-300 text-base leading-6 rounded-md text-gray-900 bg-white placeholder-gray-500 transition duration-150 ease-in-out", focus [ "outline-none border-blue-300" ], sm [ "max-w-xs" ] ] ] []
            , div [ css [ "mt-3 rounded-md shadow", sm [ "mt-0 ml-3 flex-shrink-0" ] ] ]
                [ button [ css [ "w-full flex items-center justify-center px-5 py-3 border border-transparent text-base leading-6 font-medium rounded-md text-white bg-indigo-600 transition duration-150 ease-in-out", hover [ "bg-indigo-500" ], focus [ "outline-none" ] ] ]
                    [ text model.cta ]
                ]
            ]
        ]


small : Form -> Html msg
small model =
    form [ method model.method, action model.url, target "_blank", rel "noopener", css [ "mt-6 flex flex-col", sm [ "flex-row" ], lg [ "mt-0 justify-end" ] ] ]
        [ div []
            [ label [ for "newsletter-email", class "sr-only" ] [ text model.placeholder ]
            , input [ type_ "email", name "member[email]", id "newsletter-email", attribute "autocomplete" "email", required True, css [ "appearance-none w-full px-4 py-2 border border-gray-300 text-base rounded-md text-gray-900 bg-white placeholder-gray-500", focus [ "outline-none ring-indigo-500 border-indigo-500" ], lg [ "max-w-xs" ] ], placeholder model.placeholder ] []
            ]
        , div [ css [ "mt-2 flex-shrink-0 w-full flex rounded-md shadow-sm", sm [ "mt-0 ml-3 w-auto inline-flex" ] ] ]
            [ button [ type_ "submit", css [ "w-full bg-indigo-600 px-4 py-2 border border-transparent rounded-md flex items-center justify-center text-base font-medium text-white", hover [ "bg-indigo-700" ], focus_ring_500 Tw.indigo, sm [ "w-auto inline-flex" ] ] ]
                [ text model.cta ]
            ]
        ]



-- DOCUMENTATION


formDoc : Form
formDoc =
    { method = "get", url = "#", placeholder = "Enter your email", cta = "Notify me" }


modelDoc : Model msg
modelDoc =
    { form = formDoc
    , title = "Sign up for our newsletter"
    , description = "Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui Lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat fugiat."
    , legalText = [ text "We care about the protection of your data. Read our ", a [ href "#", class "font-medium underline" ] [ text "Privacy Policy." ] ]
    }


doc : Chapter x
doc =
    chapter "Newsletter"
        |> renderComponentList
            [ ( "basicSlice", basicSlice modelDoc )
            , ( "centered", centered modelDoc.form )
            , ( "small", small modelDoc.form )
            ]
