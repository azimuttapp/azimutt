module PagesComponents.Login.View exposing (viewLogin)

import Components.Atoms.Icon as Icon
import Gen.Route as Route
import Html exposing (Html, a, button, div, form, h2, img, input, label, p, span, text)
import Html.Attributes exposing (action, alt, attribute, class, for, href, id, method, name, required, src, type_)
import PagesComponents.Login.Models exposing (Model, Msg)


viewLogin : Model -> List (Html Msg)
viewLogin _ =
    [ div [ class "min-h-full flex flex-col justify-center py-12 sm:px-6 lg:px-8" ]
        [ div [ class "sm:mx-auto sm:w-full sm:max-w-md" ]
            [ a [ href (Route.toHref Route.Home_) ] [ img [ class "mx-auto h-12 w-auto", src "/logo.png", alt "Workflow" ] [] ]
            , h2 [ class "mt-6 text-center text-3xl font-extrabold text-gray-900" ] [ text "Sign in to your account" ]
            , p [ class "mt-2 text-center text-sm text-gray-600" ]
                [ text "Or"
                , a [ href "#", class "font-medium text-indigo-600 hover:text-indigo-500" ] [ text " start your 14-day free trial" ]
                ]
            ]
        , div [ class "mt-8 sm:mx-auto sm:w-full sm:max-w-md" ]
            [ div [ class "bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10" ]
                [ form [ class "space-y-6", action "#", method "POST" ]
                    [ div []
                        [ label [ for "email", class "block text-sm font-medium text-gray-700" ] [ text "Email address" ]
                        , div [ class "mt-1" ]
                            [ input [ id "email", name "email", type_ "email", attribute "autocomplete" "email", required True, class "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ] []
                            ]
                        ]
                    , div []
                        [ label [ for "password", class "block text-sm font-medium text-gray-700" ] [ text "Password" ]
                        , div [ class "mt-1" ]
                            [ input [ id "password", name "password", type_ "password", attribute "autocomplete" "current-password", required True, class "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" ] []
                            ]
                        ]
                    , div [ class "flex items-center justify-between" ]
                        [ div [ class "flex items-center" ]
                            [ input [ id "remember-me", name "remember-me", type_ "checkbox", class "h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded" ] []
                            , label [ for "remember-me", class "ml-2 block text-sm text-gray-900" ] [ text "Remember me" ]
                            ]
                        , div [ class "text-sm" ]
                            [ a [ href "#", class "font-medium text-indigo-600 hover:text-indigo-500" ] [ text "Forgot your password?" ]
                            ]
                        ]
                    , div []
                        [ button [ type_ "submit", class "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" ]
                            [ text "Sign in" ]
                        ]
                    ]
                , div [ class "mt-6" ]
                    [ div [ class "relative" ]
                        [ div [ class "absolute inset-0 flex items-center" ] [ div [ class "w-full border-t border-gray-300" ] [] ]
                        , div [ class "relative flex justify-center text-sm" ] [ span [ class "px-2 bg-white text-gray-500" ] [ text "Or continue with" ] ]
                        ]
                    , div [ class "mt-6 grid grid-cols-3 gap-3" ]
                        [ div []
                            [ a [ href "#", class "w-full inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50" ]
                                [ span [ class "sr-only" ] [ text "Sign in with Facebook" ]
                                , Icon.facebook ""
                                ]
                            ]
                        , div []
                            [ a [ href "#", class "w-full inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50" ]
                                [ span [ class "sr-only" ] [ text "Sign in with Twitter" ]
                                , Icon.twitter ""
                                ]
                            ]
                        , div []
                            [ a [ href "#", class "w-full inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50" ]
                                [ span [ class "sr-only" ] [ text "Sign in with GitHub" ]
                                , Icon.github ""
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
