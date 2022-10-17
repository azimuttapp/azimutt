module Components.Molecules.Avatar exposing (doc, xsWithIcon)

import Components.Atoms.Icon as Icon exposing (Icon)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, div, img, span)
import Html.Attributes exposing (alt, class, src, style)
import Libs.Tailwind exposing (TwClass)


xsWithIcon : String -> String -> Icon -> TwClass -> Html msg
xsWithIcon url name icon styles =
    span [ class ("relative inline-block " ++ styles) ]
        [ img [ class "h-6 w-6 rounded-full", src url, alt name ] []
        , span [ class "absolute block text-gray-700", style "bottom" "-6px", style "right" "-6px" ] [ Icon.solid icon "h-4 w-4" ]
        ]


demo : Html msg
demo =
    div []
        [ span [ class "relative inline-block" ]
            [ img [ class "h-6 w-6 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute block text-gray-500", style "bottom" "-6px", style "right" "-6px" ] [ Icon.outline Icon.Folder "h-4 w-4" ]
            ]
        , span [ class "relative inline-block" ]
            [ img [ class "h-6 w-6 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute block text-gray-500", style "bottom" "-6px", style "right" "-6px" ] [ Icon.outline Icon.Cloud "h-4 w-4" ]
            ]
        ]


all : Html msg
all =
    div []
        [ span [ class "relative inline-block" ]
            [ img [ class "h-6 w-6 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute bottom-0 right-0 block h-1.5 w-1.5 rounded-full bg-gray-300 ring-2 ring-white" ] []
            ]
        , span [ class "relative inline-block" ]
            [ img [ class "h-8 w-8 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute bottom-0 right-0 block h-2 w-2 rounded-full bg-red-400 ring-2 ring-white" ] []
            ]
        , span [ class "relative inline-block" ]
            [ img [ class "h-10 w-10 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute bottom-0 right-0 block h-2.5 w-2.5 rounded-full bg-green-400 ring-2 ring-white" ] []
            ]
        , span [ class "relative inline-block" ]
            [ img [ class "h-12 w-12 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute bottom-0 right-0 block h-3 w-3 rounded-full bg-gray-300 ring-2 ring-white" ] []
            ]
        , span [ class "relative inline-block" ]
            [ img [ class "h-14 w-14 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute bottom-0 right-0 block h-3.5 w-3.5 rounded-full bg-red-400 ring-2 ring-white" ] []
            ]
        , span [ class "relative inline-block" ]
            [ img [ class "h-16 w-16 rounded-full", src "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80", alt "" ] []
            , span [ class "absolute bottom-0 right-0 block h-4 w-4 rounded-full bg-green-400 ring-2 ring-white" ] []
            ]
        ]



-- DOCUMENTATION


sampleUrl : String
sampleUrl =
    "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80"


doc : Chapter x
doc =
    Chapter.chapter "Avatar"
        |> Chapter.renderComponentList
            [ ( "xsWithIcon", xsWithIcon sampleUrl "" Icon.Fire "" )
            , ( "demo", demo )
            , ( "all", all )
            ]
