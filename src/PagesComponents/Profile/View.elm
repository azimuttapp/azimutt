module PagesComponents.Profile.View exposing (viewProfile)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Dict
import Html exposing (Html, a, aside, button, div, form, h1, h2, header, img, input, label, li, main_, nav, p, span, text, textarea, ul)
import Html.Attributes exposing (action, alt, attribute, class, for, href, id, method, name, placeholder, rows, src, style, tabindex, type_, value)
import Html.Events exposing (onClick, onSubmit)
import Libs.Bool as Bool
import Libs.Html.Attributes exposing (ariaChecked, ariaControls, ariaCurrent, ariaDescribedby, ariaExpanded, ariaHaspopup, ariaHidden, ariaLabelledby, ariaOrientation, css, role, styles)
import Libs.Tailwind as Tw exposing (Color, bg_50, bg_500, bg_700, bg_800, bg_900, border_500, border_800, focus, focusWithin, groupHover, hover, lg, placeholder_100, ring_500, ring_offset_900, sm, text_100, text_200, text_500, text_700)
import PagesComponents.Profile.Models exposing (Model, Msg(..))
import Shared
import Svg exposing (path, svg)
import Svg.Attributes as Svg



-- from https://tailwindui.com/components/application-ui/page-examples/settings-screens


viewProfile : Shared.Model -> Model -> List (Html Msg)
viewProfile _ model =
    let
        color : Color
        color =
            Tw.primary
    in
    [ div []
        [ div [ css [ bg_700 color, "relative pb-32 overflow-hidden" ] ]
            [ navbar color model
            , headerTexture model.mobileMenuOpen
            , headerTitle
            ]
        , main_ [ class "relative -mt-32" ]
            [ div [ class "max-w-screen-xl mx-auto pb-6 px-4 sm:px-6 lg:pb-16 lg:px-8" ]
                [ div [ class "bg-white rounded-lg shadow overflow-hidden" ]
                    [ div [ class "divide-y divide-gray-200 lg:grid lg:grid-cols-12 lg:divide-y-0 lg:divide-x" ]
                        [ menus Tw.teal
                        , form [ class "divide-y divide-gray-200 lg:col-span-9", action "#", method "POST", onSubmit (Noop "submit-form") ]
                            [ profileForm color
                            , privacyForm color model
                            , formButtons color
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]


navbar : Color -> Model -> Html Msg
navbar color model =
    nav [ css [ Bool.cond model.mobileMenuOpen (bg_900 color) "bg-transparent", border_500 color, "relative z-10 border-b border-opacity-25 lg:bg-transparent lg:border-none" ] ]
        [ div [ class "max-w-7xl mx-auto px-2 sm:px-4 lg:px-8" ]
            [ div [ css [ "relative h-16 flex items-center justify-between", lg [ border_800 color, "border-b" ] ] ]
                [ div [ class "px-2 flex items-center lg:px-0" ]
                    [ div [ class "flex-shrink-0" ]
                        [ img [ class "block h-8 w-auto", src "https://tailwindui.com/img/logos/workflow-mark-teal-400.svg", alt "Workflow" ] []
                        ]
                    , div [ class "hidden lg:block lg:ml-6 lg:space-x-4" ]
                        [ div [ class "flex" ]
                            [ navbarMenuDesktop color "#" "Dashboard" True
                            , navbarMenuDesktop color "#" "Jobs" False
                            , navbarMenuDesktop color "#" "Applicants" False
                            , navbarMenuDesktop color "#" "Company" False
                            ]
                        ]
                    ]
                , div [ class "flex-1 px-2 flex justify-center lg:ml-6 lg:justify-end" ]
                    [ div [ class "max-w-lg w-full lg:max-w-xs" ]
                        [ label [ for "search", class "sr-only" ] [ text "Search" ]
                        , div [ css [ text_100 color, "relative focus-within:text-gray-400" ] ]
                            [ div [ class "pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center" ]
                                [ Icon.solid Search ""
                                ]
                            , input [ type_ "search", name "search", id "search", placeholder "Search", css [ bg_700 color, placeholder_100 color, "block w-full bg-opacity-50 py-2 pl-10 pr-3 border border-transparent rounded-md leading-5", focus [ "outline-none bg-white ring-white border-white placeholder-gray-500 text-gray-900" ], sm [ "text-sm" ] ] ] []
                            ]
                        ]
                    ]
                , div [ class "flex lg:hidden" ] [ mobileMenuButton color model.mobileMenuOpen ]
                , div [ class "hidden lg:block lg:ml-4" ]
                    [ div [ class "flex items-center" ]
                        [ button [ type_ "button", css [ text_200 color, "flex-shrink-0 rounded-full p-1", hover [ bg_800 color, "text-white" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ] ]
                            [ span [ class "sr-only" ] [ text "View notifications" ]
                            , Icon.outline Bell ""
                            ]
                        , profileDropdown color model.profileDropdownOpen
                        ]
                    ]
                ]
            ]
        , div [ css [ Bool.cond model.mobileMenuOpen "" "hidden", bg_900 color, "lg:hidden" ], id "mobile-menu" ]
            [ div [ class "pt-2 pb-3 px-2 space-y-1" ]
                [ navbarMenuMobile color "#" "Dashboard" True
                , navbarMenuMobile color "#" "Jobs" False
                , navbarMenuMobile color "#" "Applicants" False
                , navbarMenuMobile color "#" "Company" False
                ]
            , div [ css [ border_800 color, "pt-4 pb-3 border-t" ] ]
                [ div [ class "flex items-center px-4" ]
                    [ div [ class "flex-shrink-0" ]
                        [ img [ class "rounded-full h-10 w-10", src "https://images.unsplash.com/photo-1517365830460-955ce3ccd263?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=4&w=320&h=320&q=80", alt "" ] []
                        ]
                    , div [ class "ml-3" ]
                        [ div [ class "text-base font-medium text-white" ] [ text "Debbie Lewis" ]
                        , div [ css [ text_200 color, "text-sm font-medium" ] ] [ text "debbielewis@example.com" ]
                        ]
                    , button [ type_ "button", css [ text_200 color, "ml-auto flex-shrink-0 rounded-full p-1", hover [ bg_800 color, "text-white" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ] ]
                        [ span [ class "sr-only" ] [ text "View notifications" ]
                        , Icon.outline Bell ""
                        ]
                    ]
                , div [ class "mt-3 px-2" ]
                    [ a [ href "#", css [ text_200 color, "block rounded-md py-2 px-3 text-base font-medium", hover [ bg_800 color, "text-white" ] ] ] [ text "Your Profile" ]
                    , a [ href "#", css [ text_200 color, "block rounded-md py-2 px-3 text-base font-medium", hover [ bg_800 color, "text-white" ] ] ] [ text "Settings" ]
                    , a [ href "#", css [ text_200 color, "block rounded-md py-2 px-3 text-base font-medium", hover [ bg_800 color, "text-white" ] ] ] [ text "Sign out" ]
                    ]
                ]
            ]
        ]


mobileMenuButton : Color -> Bool -> Html Msg
mobileMenuButton color mobileMenuOpen =
    button
        [ type_ "button"
        , onClick ToggleMobileMenu
        , css [ text_200 color, "p-2 rounded-md inline-flex items-center justify-center", hover [ bg_800 color, "text-white" ], focus [ "outline-none ring-2 ring-inset ring-white" ] ]
        , ariaControls "mobile-menu"
        , ariaExpanded False
        ]
        [ span [ class "sr-only" ] [ text "Open main menu" ]
        , Icon.outline Menu (Bool.cond mobileMenuOpen "hidden" "block")
        , Icon.outline X (Bool.cond mobileMenuOpen "block" "hidden")
        ]


profileDropdown : Color -> Bool -> Html Msg
profileDropdown color profileDropdownOpen =
    div [ class "relative flex-shrink-0 ml-4" ]
        [ div []
            [ button
                [ type_ "button", id "user-menu-button", onClick ToggleProfileDropdown, css [ "rounded-full flex text-sm text-white", focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ], ariaExpanded False, ariaHaspopup True ]
                [ span [ class "sr-only" ] [ text "Open user menu" ]
                , img [ class "rounded-full h-8 w-8", src "https://images.unsplash.com/photo-1517365830460-955ce3ccd263?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=4&w=320&h=320&q=80", alt "" ] []
                ]
            ]
        , div
            [ role "menu"
            , ariaOrientation "vertical"
            , ariaLabelledby "user-menu-button"
            , tabindex -1
            , css
                [ Bool.cond profileDropdownOpen
                    "transition ease-in duration-75 transform scale-100 opacity-100"
                    "transition ease-out duration-100 transform scale-95 opacity-0 pointer-events-none"
                , "origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
                ]
            ]
            [ a [ href "#", id "user-menu-item-0", role "menuitem", tabindex -1, class "block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100" ] [ text "Your Profile" ]
            , a [ href "#", id "user-menu-item-1", role "menuitem", tabindex -1, class "block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100" ] [ text "Settings" ]
            , a [ href "#", id "user-menu-item-2", role "menuitem", tabindex -1, class "block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100" ] [ text "Sign out" ]
            ]
        ]


navbarMenuDesktop : Color -> String -> String -> Bool -> Html msg
navbarMenuDesktop color url label active =
    a [ href url, css [ Bool.cond active "bg-black bg-opacity-25" (hover [ bg_800 color ]), "rounded-md py-2 px-3 text-sm font-medium text-white" ] ] [ text label ]


navbarMenuMobile : Color -> String -> String -> Bool -> Html msg
navbarMenuMobile color url label active =
    a [ href url, css [ Bool.cond active "bg-black bg-opacity-25" (hover [ bg_800 color ]), "block rounded-md py-2 px-3 text-base font-medium text-white" ] ] [ text label ]


headerTexture : Bool -> Html msg
headerTexture mobileMenuOpen =
    div [ ariaHidden True, css [ Bool.cond mobileMenuOpen "bottom-0" "inset-y-0", "absolute inset-x-0 left-1/2 transform -translate-x-1/2 w-full overflow-hidden lg:inset-y-0" ] ]
        [ div [ class "absolute inset-0 flex" ]
            [ div [ class "h-full w-1/2", style "background-color" "#0a527b" ] []
            , div [ class "h-full w-1/2", style "background-color" "#065d8c" ] []
            ]
        , div [ class "relative flex justify-center" ]
            [ svg [ Svg.class "flex-shrink-0", Svg.width "1750", Svg.height "308", Svg.viewBox "0 0 1750 308" ]
                [ path [ Svg.d "M284.161 308H1465.84L875.001 182.413 284.161 308z", Svg.fill "#0369a1" ] [] -- sky700
                , path [ Svg.d "M1465.84 308L16.816 0H1750v308h-284.16z", Svg.fill "#065d8c" ] []
                , path [ Svg.d "M1733.19 0L284.161 308H0V0h1733.19z", Svg.fill "#0a527b" ] []
                , path [ Svg.d "M875.001 182.413L1733.19 0H16.816l858.185 182.413z", Svg.fill "#0a4f76" ] []
                ]
            ]
        ]


headerTitle : Html msg
headerTitle =
    header [ class "relative py-10" ]
        [ div [ class "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" ]
            [ h1 [ class "text-3xl font-bold text-white" ]
                [ text "Settings" ]
            ]
        ]


menus : Color -> Html msg
menus color =
    aside [ class "py-6 lg:col-span-3" ]
        [ nav [ class "space-y-1" ]
            [ menuLink color "#" UserCircle "Profile" True
            , menuLink color "#" Cog "Account" False
            , menuLink color "#" Key "Password" False
            , menuLink color "#" Bell "Notifications" False
            , menuLink color "#" CreditCard "Billing" False
            , menuLink color "#" ViewGridAdd "Integrations" False
            ]
        ]


menuLink : Color -> String -> Icon -> String -> Bool -> Html msg
menuLink color url icon label active =
    if active then
        a [ href url, css [ bg_50 color, border_500 color, text_700 color, "group border-l-4 px-3 py-2 flex items-center text-sm font-medium", hover [ bg_50 color, text_700 color ] ], ariaCurrent "page" ]
            [ Icon.outline icon (styles [ text_500 color, groupHover [ text_500 color ], "-ml-1 mr-3" ])
            , span [ class "truncate" ] [ text label ]
            ]

    else
        a [ href url, css [ "border-transparent text-gray-900 hover:bg-gray-50 hover:text-gray-900", "group border-l-4 px-3 py-2 flex items-center text-sm font-medium" ] ]
            [ Icon.outline icon "text-gray-400 group-hover:text-gray-500 -ml-1 mr-3"
            , span [ class "truncate" ] [ text label ]
            ]


profileForm : Color -> Html msg
profileForm color =
    div [ class "py-6 px-4 sm:p-6 lg:pb-8" ]
        [ div []
            [ h2 [ class "text-lg leading-6 font-medium text-gray-900" ]
                [ text "Profile" ]
            , p [ class "mt-1 text-sm text-gray-500" ]
                [ text "This information will be displayed publicly so be careful what you share." ]
            ]
        , div [ class "mt-6 flex flex-col lg:flex-row" ]
            [ div [ class "flex-grow space-y-6" ]
                [ div []
                    [ label [ for "username", class "block text-sm font-medium text-gray-700" ]
                        [ text "Username" ]
                    , div [ class "mt-1 rounded-md shadow-sm flex" ]
                        [ span [ class "bg-gray-50 border border-r-0 border-gray-300 rounded-l-md px-3 inline-flex items-center text-gray-500 sm:text-sm" ]
                            [ text "workcation.com/" ]
                        , input [ type_ "text", name "username", id "username", value "deblewis", attribute "autocomplete" "username", css [ "flex-grow block w-full min-w-0 rounded-none rounded-r-md border-gray-300 sm:text-sm", focus [ ring_500 color, border_500 color ] ] ] []
                        ]
                    ]
                , div []
                    [ label [ for "about", class "block text-sm font-medium text-gray-700" ]
                        [ text "About" ]
                    , div [ class "mt-1" ]
                        [ textarea [ id "about", name "about", rows 3, css [ "shadow-sm mt-1 block w-full border border-gray-300 rounded-md sm:text-sm", focus [ ring_500 color, border_500 color ] ] ] []
                        ]
                    , p [ class "mt-2 text-sm text-gray-500" ]
                        [ text "Brief description for your profile. URLs are hyperlinked." ]
                    ]
                ]
            , div [ class "mt-6 flex-grow lg:mt-0 lg:ml-6 lg:flex-grow-0 lg:flex-shrink-0" ]
                [ p [ class "text-sm font-medium text-gray-700", ariaHidden True ]
                    [ text "Photo" ]
                , div [ class "mt-1 lg:hidden" ]
                    [ div [ class "flex items-center" ]
                        [ div [ class "flex-shrink-0 inline-block rounded-full overflow-hidden h-12 w-12", ariaHidden True ]
                            [ img [ class "rounded-full h-full w-full", src "https://images.unsplash.com/photo-1517365830460-955ce3ccd263?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=4&w=320&h=320&q=80", alt "" ] []
                            ]
                        , div [ class "ml-5 rounded-md shadow-sm" ]
                            [ div [ css [ "group relative border border-gray-300 rounded-md py-2 px-3 flex items-center justify-center hover:bg-gray-50", focusWithin [ ring_500 color, "ring-offset-2 ring-2" ] ] ]
                                [ label [ for "mobile-user-photo", class "relative text-sm leading-4 font-medium text-gray-700 pointer-events-none" ]
                                    [ span [] [ text "Change" ]
                                    , span [ class "sr-only" ] [ text "user photo" ]
                                    ]
                                , input [ type_ "file", name "user-photo", id "mobile-user-photo", class "absolute w-full h-full opacity-0 cursor-pointer border-gray-300 rounded-md" ] []
                                ]
                            ]
                        ]
                    ]
                , div [ class "hidden relative rounded-full overflow-hidden lg:block" ]
                    [ img [ class "relative rounded-full w-40 h-40", src "https://images.unsplash.com/photo-1517365830460-955ce3ccd263?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=4&w=320&h=320&q=80", alt "" ] []
                    , label [ for "desktop-user-photo", class "absolute inset-0 w-full h-full bg-black bg-opacity-75 flex items-center justify-center text-sm font-medium text-white opacity-0 hover:opacity-100 focus-within:opacity-100" ]
                        [ span [] [ text "Change" ]
                        , span [ class "sr-only" ] [ text "user photo" ]
                        , input [ type_ "file", name "user-photo", id "desktop-user-photo", class "absolute inset-0 w-full h-full opacity-0 cursor-pointer border-gray-300 rounded-md" ] []
                        ]
                    ]
                ]
            ]
        , div [ class "mt-6 grid grid-cols-12 gap-6" ]
            [ div [ class "col-span-12 sm:col-span-6" ]
                [ label [ for "first-name", class "block text-sm font-medium text-gray-700" ]
                    [ text "First name" ]
                , input [ type_ "text", name "first-name", id "first-name", attribute "autocomplete" "given-name", css [ "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 sm:text-sm", focus [ ring_500 color, border_500 color, "outline-none" ] ] ] []
                ]
            , div [ class "col-span-12 sm:col-span-6" ]
                [ label [ for "last-name", class "block text-sm font-medium text-gray-700" ]
                    [ text "Last name" ]
                , input [ type_ "text", name "last-name", id "last-name", attribute "autocomplete" "family-name", css [ "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 sm:text-sm", focus [ ring_500 color, border_500 color, "outline-none" ] ] ] []
                ]
            , div [ class "col-span-12" ]
                [ label [ for "url", class "block text-sm font-medium text-gray-700" ]
                    [ text "URL" ]
                , input [ type_ "text", name "url", id "url", css [ "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 sm:text-sm", focus [ ring_500 color, border_500 color, "outline-none" ] ] ] []
                ]
            , div [ class "col-span-12 sm:col-span-6" ]
                [ label [ for "company", class "block text-sm font-medium text-gray-700" ]
                    [ text "Company" ]
                , input [ type_ "text", name "company", id "company", attribute "autocomplete" "organization", css [ "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 sm:text-sm", focus [ ring_500 color, border_500 color, "outline-none" ] ] ] []
                ]
            ]
        ]


privacyForm : Color -> Model -> Html Msg
privacyForm color model =
    div [ class "pt-6 divide-y divide-gray-200" ]
        [ div [ class "px-4 sm:px-6" ]
            [ div []
                [ h2 [ class "text-lg leading-6 font-medium text-gray-900" ]
                    [ text "Privacy" ]
                , p [ class "mt-1 text-sm text-gray-500" ]
                    [ text "Ornare eu a volutpat eget vulputate. Fringilla commodo amet." ]
                ]
            , ul [ role "list", class "mt-2 divide-y divide-gray-200" ]
                [ privacyToggle color 1 "Available to hire" "Nulla amet tempus sit accumsan. Aliquet turpis sed sit lacinia." model
                , privacyToggle color 2 "Make account private" "Pharetra morbi dui mi mattis tellus sollicitudin cursus pharetra." model
                , privacyToggle color 3 "Allow commenting" "Integer amet, nunc hendrerit adipiscing nam. Elementum ame" model
                , privacyToggle color 4 "Allow mentions" "Adipiscing est venenatis enim molestie commodo eu gravid" model
                ]
            ]
        ]


privacyToggle : Color -> Int -> String -> String -> Model -> Html Msg
privacyToggle color index label description model =
    let
        htmlId : String
        htmlId =
            "privacy-option-" ++ String.fromInt index

        value : Bool
        value =
            model.toggles |> Dict.get label |> Maybe.withDefault False
    in
    li [ class "py-4 flex items-center justify-between" ]
        [ div [ class "flex flex-col" ]
            [ p [ class "text-sm font-medium text-gray-900", id (htmlId ++ "-label") ]
                [ text label ]
            , p [ class "text-sm text-gray-500", id (htmlId ++ "-description") ]
                [ text description ]
            ]
        , button [ type_ "button", role "switch", onClick (TogglePrivacy label), ariaChecked True, ariaLabelledby (htmlId ++ "-label"), ariaDescribedby (htmlId ++ "-description"), css [ Bool.cond value (bg_500 color) "bg-gray-200", "ml-4 relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200", focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ] ] ]
            [ span [ ariaHidden True, css [ Bool.cond value "translate-x-5" "translate-x-0", "inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0 transition ease-in-out duration-200" ] ] []
            ]
        ]


formButtons : Color -> Html msg
formButtons color =
    div [ class "mt-4 py-4 px-4 flex justify-end sm:px-6" ]
        [ button [ type_ "button", css [ "bg-white border border-gray-300 rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-gray-700 hover:bg-gray-50", focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ] ] ]
            [ text "Cancel" ]
        , button [ type_ "submit", css [ bg_700 color, "ml-5 border border-transparent rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-white", hover [ bg_800 color ], focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ] ] ]
            [ text "Save" ]
        ]
