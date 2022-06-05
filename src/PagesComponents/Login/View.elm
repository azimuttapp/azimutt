module PagesComponents.Login.View exposing (viewLogin)

import Components.Atoms.Icon as Icon
import Conf
import Gen.Route as Route
import Html exposing (Html, a, b, button, div, h1, hr, img, input, nav, p, span, text)
import Html.Attributes exposing (alt, attribute, class, disabled, href, name, placeholder, required, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Lazy as Lazy
import Libs.Html exposing (bText, extLink)
import Libs.Html.Attributes exposing (css)
import PagesComponents.Login.Models exposing (Model, Msg(..))
import Ports exposing (LoginInfo(..))
import Services.Toasts as Toasts


viewLogin : Model -> List (Html Msg)
viewLogin model =
    [ div [ class "h-screen flex flex-col" ]
        [ nav [ class "sticky top-0 flex items-center justify-between mx-auto w-full max-w-7xl px-8 pt-6" ]
            [ logo, navCta ]
        , div [ class "mx-auto flex h-full max-w-screen-xl items-center justify-center px-8" ]
            [ div [ class "sm:text-center" ]
                [ heading
                , description
                , cta
                , magicLinkLogin model

                --, legal
                , hr [ class "mt-16 max-w-[75px] border-zinc-500 sm:mx-auto" ] []
                , footer
                ]
            ]
        ]
    , Lazy.lazy2 Toasts.view Toast model.toasts
    ]


logo : Html msg
logo =
    a [ href (Route.toHref Route.Home_), class "flex flex-shrink-0" ]
        [ img [ class "block h-8 w-auto", src "/logo.png", alt "Azimutt" ] []
        , span [ class "ml-3 text-2xl font-medium text-slate-600 hover:text-slate-900" ] [ text "Azimutt" ]
        ]


navCta : Html Msg
navCta =
    div [ class "flex items-center space-x-3 ml-3" ]
        [ extLink Conf.constants.azimuttRoadmap
            [ class "text-sm text-slate-600 hover:text-slate-900" ]
            [ text "Roadmap" ]
        , button [ onClick (Login Github), css [ "inline-flex items-center space-x-2 bg-primary-600 text-white text-xs rounded shadow-sm px-2.5 py-1 outline-none outline-0 transition transition-all ease-out duration-200 hover:bg-primary-800" ] ]
            [ Icon.github2 14
            , span [ class "truncate" ] [ text "Sign In with GitHub" ]
            ]
        ]


heading : Html msg
heading =
    h1 [ class "text-3xl" ]
        [ text "The database tool that "
        , b [ class "text-primary-700 whitespace-nowrap" ] [ text "empowers you" ]
        , text "."
        ]


description : Html msg
description =
    p [ class "text-slate-600 mb-10 mt-5 sm:mx-auto sm:max-w-2xl" ]
        [ text "Explore your database like ", bText "never before", text ". Search, follow relations, find path, save layouts, identify design smells and much more. Works well with thousands of tables." ]


cta : Html Msg
cta =
    div [ class "flex items-center space-x-2 sm:justify-center" ]
        [ button [ onClick (Login Github), class "inline-flex items-center space-x-2 bg-primary-600 text-white text-sm rounded shadow-sm px-4 py-2 outline-none outline-0 transition transition-all ease-out duration-200 hover:bg-primary-800" ]
            [ Icon.github2 20
            , span [ class "truncate" ] [ text "Sign In with GitHub" ]
            ]
        , a [ href (Route.toHref Route.Blog), class "inline-flex items-center space-x-2 bg-slate-100 text-slate-900 text-sm rounded shadow-sm px-4 py-2 outline-none outline-0 transition transition-all ease-out duration-200 hover:bg-slate-200" ]
            [ span [ class "truncate" ] [ text "Blog" ]
            ]
        ]


magicLinkLogin : Model -> Html Msg
magicLinkLogin model =
    if False then
        -- help for local dev multi-account
        div [ class "mt-5 flex items-center" ]
            [ input [ type_ "email", name "email", value model.email, onInput UpdateEmail, placeholder "ex: you@email.com", attribute "autocomplete" "email", required True, class "grow px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ] []
            , button [ disabled (model.email == ""), onClick (Login (MagicLink model.email)), class "flex-none ml-2 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-indigo-300" ]
                [ text "Sign in with magic link" ]
            ]

    else
        div [] []



--legal : Html msg
--legal =
--    div [ class "sm:text-center" ]
--        [ p [ class "text-slate-400 mt-8 mb-5 text-xs sm:mx-auto sm:max-w-sm" ]
--            [ text "By continuing, you agree to Azimutt's "
--            , a [ class "underline hover:text-slate-600", href "#" ] [ text "Terms of Service" ]
--            , text " and "
--            , a [ class "underline hover:text-slate-600", href "#" ] [ text "Privacy Policy" ]
--            , text ", and to receive periodic emails with updates."
--            ]
--        ]


footer : Html msg
footer =
    div [ class "sm:text-center" ]
        [ p [ class "mt-16 mb-5 text-slate-400 sm:mx-auto sm:max-w-2xl" ] [ text "You have specific needs regarding your database management?" ]
        , a [ class "text-slate-800", href ("mailto:" ++ Conf.constants.azimuttEmail) ] [ text "Let's talk!" ]
        ]
