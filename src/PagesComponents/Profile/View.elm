module PagesComponents.Profile.View exposing (viewProfile)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Gen.Route as Route
import Html exposing (Html, a, aside, button, div, h1, h2, header, img, input, label, main_, nav, p, span, text, textarea)
import Html.Attributes exposing (alt, attribute, class, disabled, for, href, id, name, placeholder, rows, src, tabindex, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Lazy as Lazy
import Libs.Bool as Bool
import Libs.Html.Attributes exposing (ariaControls, ariaCurrent, ariaExpanded, ariaHaspopup, ariaHidden, ariaLabelledby, ariaOrientation, css, role, styles)
import Libs.Maybe as Maybe
import Libs.Tailwind as Tw exposing (Color, TwClass, bg_50, bg_700, bg_800, bg_900, border_500, border_800, focus, focusWithin, groupHover, hover, lg, ring_500, ring_offset_900, text_200, text_500, text_700)
import Models.User as User exposing (User)
import PagesComponents.Profile.Models exposing (Model, Msg(..))
import Router
import Services.Toasts as Toasts
import Shared
import Url exposing (Url)


viewProfile : Url -> Shared.Model -> Model -> List (Html Msg)
viewProfile currentUrl shared model =
    let
        color : Color
        color =
            Tw.primary
    in
    [ div []
        [ div [ css [ bg_700 color, "relative pb-32 overflow-hidden" ] ]
            [ navbar color currentUrl model
            , headerTitle
            ]
        , main_ [ class "relative -mt-32" ]
            [ div [ class "max-w-screen-xl mx-auto pb-6 px-4 sm:px-6 lg:pb-16 lg:px-8" ]
                [ div [ class "bg-white rounded-lg shadow overflow-hidden" ]
                    [ model.user
                        |> Maybe.mapOrElse
                            (\user ->
                                div [ class "divide-y divide-gray-200 lg:grid lg:grid-cols-12 lg:divide-y-0 lg:divide-x" ]
                                    [ asideMenus color
                                    , div [ class "divide-y divide-gray-200 lg:col-span-9" ]
                                        [ profileForm color user
                                        , formButtons color model.updating shared.user model.user
                                        ]
                                    ]
                            )
                            (div [ class "py-6 px-4 sm:p-6 lg:pb-8" ]
                                [ h2 [ class "text-lg leading-6 font-medium text-gray-900" ]
                                    [ text "Needs to be signed in" ]
                                , a [ href (Router.login currentUrl), class "inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-full shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" ]
                                    [ text "Sign in" ]
                                , div [ class "pb-80" ] []
                                ]
                            )
                    ]
                ]
            ]
        ]
    , Lazy.lazy2 Toasts.view Toast model.toasts
    ]


type alias LinkAction =
    { label : String, url : String }


type alias MsgAction =
    { label : String, msg : Msg }


type Action
    = Link LinkAction
    | Message MsgAction


navbar : Color -> Url -> Model -> Html Msg
navbar color currentUrl model =
    let
        menuLinks : List LinkAction
        menuLinks =
            [ { label = "Dashboard", url = Route.toHref Route.Projects } ]

        profileLinks : List Action
        profileLinks =
            [ Link { label = "Your profile", url = Route.toHref Route.Profile }

            --, { label = "Settings", url = "#" }
            , Message { label = "Logout", msg = DoLogout }
            ]
    in
    nav [ css [ Bool.cond model.mobileMenuOpen (bg_900 color) "bg-transparent", border_500 color, "relative z-10 border-b border-opacity-25 lg:bg-transparent lg:border-none" ] ]
        [ div [ class "max-w-7xl mx-auto px-2 sm:px-4 lg:px-8" ]
            [ div [ css [ "relative h-16 flex items-center justify-between", lg [ border_800 color, "border-b" ] ] ]
                [ div [ class "px-2 flex items-center lg:px-0" ]
                    [ a [ href (Route.toHref Route.Home_), class "flex flex-shrink-0" ]
                        [ img [ class "block h-8 w-auto", src "/logo.png", alt "Azimutt" ] []
                        , span [ css [ "ml-3 text-2xl text-white font-medium hidden", lg [ "block" ] ] ] [ text "Azimutt" ]
                        ]
                    , div [ class "hidden lg:block lg:ml-6 lg:space-x-4" ]
                        [ div [ class "flex" ]
                            (menuLinks |> List.map (\l -> navbarMenuDesktop color l.url l.label False))
                        ]
                    ]

                --, navbarSearch color
                , div [ class "flex lg:hidden" ] [ mobileMenuButton color model.mobileMenuOpen ]
                , div [ class "hidden lg:block lg:ml-4" ]
                    [ div [ class "flex items-center" ]
                        --[ button [ type_ "button", css [ text_200 color, "flex-shrink-0 rounded-full p-1", hover [ bg_800 color, "text-white animate-wobble-t" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ] ]
                        --    [ span [ class "sr-only" ] [ text "View notifications" ]
                        --    , Icon.outline Bell ""
                        --    ]
                        [ profileDropdown color currentUrl model.user profileLinks model.profileDropdownOpen
                        ]
                    ]
                ]
            ]
        , div [ css [ Bool.cond model.mobileMenuOpen "" "hidden", bg_900 color, "lg:hidden" ], id "mobile-menu" ]
            [ div [ class "pt-2 pb-3 px-2 space-y-1" ] (menuLinks |> List.map (\l -> navbarMenuMobile color l.url l.label False))
            , div [ css [ border_800 color, "pt-4 pb-3 border-t" ] ]
                (model.user
                    |> Maybe.mapOrElse
                        (\user ->
                            [ div [ class "flex items-center px-4" ]
                                [ div [ class "flex-shrink-0" ]
                                    [ img [ class "rounded-full h-10 w-10", src (user |> User.avatar), alt user.name ] []
                                    ]
                                , div [ class "ml-3" ]
                                    [ div [ class "text-base font-medium text-white" ] [ text user.name ]
                                    , div [ css [ text_200 color, "text-sm font-medium" ] ] [ text user.email ]
                                    ]

                                --, button [ type_ "button", css [ text_200 color, "ml-auto flex-shrink-0 rounded-full p-1", hover [ bg_800 color, "text-white" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ] ]
                                --    [ span [ class "sr-only" ] [ text "View notifications" ]
                                --    , Icon.outline Bell ""
                                --    ]
                                ]
                            , div [ class "mt-3 px-2" ]
                                (profileLinks
                                    |> List.map
                                        (\l ->
                                            case l of
                                                Link { url, label } ->
                                                    a [ href url, css [ text_200 color, "block rounded-md py-2 px-3 text-base font-medium", hover [ bg_800 color, "text-white" ] ] ] [ text label ]

                                                Message { msg, label } ->
                                                    button [ onClick msg, css [ text_200 color, "block rounded-md py-2 px-3 text-base font-medium text-left w-full", hover [ bg_800 color, "text-white" ] ] ] [ text label ]
                                        )
                                )
                            ]
                        )
                        [ div [ class "flex items-center px-4" ]
                            [ a [ href (Router.login currentUrl), css [ text_200 color, "flex w-full block rounded-md py-2 px-3 text-base font-medium", hover [ bg_800 color, "text-white" ] ] ]
                                [ Icon.outline Icon.User ""
                                , span [ class "ml-1" ] [ text "Sign in" ]
                                ]

                            --, button [ type_ "button", css [ text_200 color, "ml-auto flex-shrink-0 rounded-full p-1", hover [ bg_800 color, "text-white" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ] ]
                            --    [ span [ class "sr-only" ] [ text "View notifications" ]
                            --    , Icon.outline Bell "ml-1"
                            --    ]
                            ]
                        ]
                )
            ]
        ]



--navbarSearch : Color -> Html msg
--navbarSearch color =
--    div [ class "flex-1 px-2 flex justify-center lg:ml-6 lg:justify-end" ]
--        [ div [ class "max-w-lg w-full lg:max-w-xs" ]
--            [ label [ for "search", class "sr-only" ] [ text "Search" ]
--            , div [ css [ text_100 color, "relative focus-within:text-gray-400" ] ]
--                [ div [ class "pointer-events-none absolute inset-y-0 left-0 pl-3 flex items-center" ]
--                    [ Icon.solid Search ""
--                    ]
--                , input [ type_ "search", name "search", id "search", placeholder "Search", css [ bg_700 color, placeholder_100 color, "block w-full bg-opacity-50 py-2 pl-10 pr-3 border border-transparent rounded-md leading-5", focus [ "outline-none bg-white ring-white border-white placeholder-gray-500 text-gray-900" ], sm [ "text-sm" ] ] ] []
--                ]
--            ]
--        ]


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


profileDropdown : Color -> Url -> Maybe User -> List Action -> Bool -> Html Msg
profileDropdown color currentUrl user profileLinks profileDropdownOpen =
    user
        |> Maybe.mapOrElse
            (\u ->
                div [ class "relative flex-shrink-0 mx-1" ]
                    [ button
                        [ type_ "button", id "user-menu-button", onClick ToggleProfileDropdown, css [ text_200 color, "flex-shrink-0 rounded-full flex", hover [ bg_800 color, "text-white animate-jello-h" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ], ariaExpanded False, ariaHaspopup True ]
                        [ span [ class "sr-only text-sm text-white" ] [ text "Open user menu" ]
                        , img [ src (u |> User.avatar), alt u.name, css [ "rounded-full h-8 w-8" ] ] []
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
                        (profileLinks
                            |> List.indexedMap
                                (\i l ->
                                    case l of
                                        Link { url, label } ->
                                            a [ href url, id ("user-menu-item-" ++ String.fromInt i), role "menuitem", tabindex -1, class "block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100" ] [ text label ]

                                        Message { msg, label } ->
                                            button [ onClick msg, id ("user-menu-item-" ++ String.fromInt i), role "menuitem", tabindex -1, class "block py-2 px-4 text-sm text-gray-700 hover:bg-gray-100 text-left w-full" ] [ text label ]
                                )
                        )
                    ]
            )
            (div [ class "flex-shrink-0 mx-1" ]
                [ a
                    [ href (Router.login currentUrl), id "user-menu-button", onClick ToggleProfileDropdown, css [ text_200 color, "flex-shrink-0 rounded-full p-1 flex", hover [ bg_800 color, "text-white animate-flip-h" ], focus [ bg_900 color, ring_offset_900 color, "outline-none ring-2 ring-offset-2 ring-white" ] ], ariaExpanded False, ariaHaspopup True ]
                    [ span [ class "sr-only text-sm text-white" ] [ text "Open user menu" ]
                    , Icon.outline Icon.User ""
                    ]
                ]
            )


navbarMenuDesktop : Color -> String -> String -> Bool -> Html msg
navbarMenuDesktop color url label active =
    a [ href url, css [ Bool.cond active "bg-black bg-opacity-25" (hover [ bg_800 color ]), "rounded-md py-2 px-3 text-sm font-medium text-white" ] ] [ text label ]


navbarMenuMobile : Color -> String -> String -> Bool -> Html msg
navbarMenuMobile color url label active =
    a [ href url, css [ Bool.cond active "bg-black bg-opacity-25" (hover [ bg_800 color ]), "block rounded-md py-2 px-3 text-base font-medium text-white" ] ] [ text label ]



--headerTexture : Bool -> Html msg
--headerTexture mobileMenuOpen =
--    div [ ariaHidden True, css [ Bool.cond mobileMenuOpen "bottom-0" "inset-y-0", "absolute inset-x-0 left-1/2 transform -translate-x-1/2 w-full overflow-hidden lg:inset-y-0" ] ]
--        [ div [ class "absolute inset-0 flex" ]
--            [ div [ class "h-full w-1/2", style "background-color" "#0a527b" ] []
--            , div [ class "h-full w-1/2", style "background-color" "#065d8c" ] []
--            ]
--        , div [ class "relative flex justify-center" ]
--            [ svg [ Svg.class "flex-shrink-0", Svg.width "1750", Svg.height "308", Svg.viewBox "0 0 1750 308" ]
--                [ path [ Svg.d "M284.161 308H1465.84L875.001 182.413 284.161 308z", Svg.fill "#0369a1" ] [] -- sky700
--                , path [ Svg.d "M1465.84 308L16.816 0H1750v308h-284.16z", Svg.fill "#065d8c" ] []
--                , path [ Svg.d "M1733.19 0L284.161 308H0V0h1733.19z", Svg.fill "#0a527b" ] []
--                , path [ Svg.d "M875.001 182.413L1733.19 0H16.816l858.185 182.413z", Svg.fill "#0a4f76" ] []
--                ]
--            ]
--        ]


headerTitle : Html msg
headerTitle =
    header [ class "relative py-10" ]
        [ div [ class "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" ]
            [ h1 [ class "text-3xl font-bold text-white" ]
                [ text "Profile" ]
            ]
        ]


asideMenus : Color -> Html msg
asideMenus color =
    let
        active : String
        active =
            "Profile"

        menus : List { url : String, icon : Icon, label : String }
        menus =
            [ { icon = UserCircle, label = "Profile", url = Route.toHref Route.Profile }

            --, { icon = Cog, label = "Account", url = "#" }
            --, { icon = Key, label = "Password", url = "#" }
            --, { icon = Bell, label = "Notifications", url = "#" }
            --, { icon = CreditCard, label = "Billing", url = "#" }
            --, { icon = ViewGridAdd, label = "Integrations", url = "#" }
            ]
    in
    aside [ class "py-6 lg:col-span-3" ]
        [ nav [ class "space-y-1" ]
            (menus |> List.map (\m -> menuLink color m.url m.icon m.label (m.label == active)))
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


profileForm : Color -> User -> Html Msg
profileForm color user =
    div [ class "py-6 px-4 sm:p-6 lg:pb-8" ]
        [ div []
            [ h2 [ class "text-lg leading-6 font-medium text-gray-900" ]
                [ text "Profile" ]
            , p [ class "mt-1 text-sm text-gray-500" ]
                [ text "This information will be displayed publicly (at some point) so be careful what you share." ]
            ]
        , div [ class "mt-6 flex flex-col lg:flex-row" ]
            [ div [ class "flex-grow space-y-6" ]
                [ div []
                    [ label [ for "username", class "block text-sm font-medium text-gray-700" ]
                        [ text "Username" ]
                    , div [ class "mt-1 rounded-md shadow-sm flex" ]
                        [ span [ class "bg-gray-50 border border-r-0 border-gray-300 rounded-l-md px-3 inline-flex items-center text-gray-500 sm:text-sm" ]
                            [ text "azimutt.app/" ]
                        , input [ type_ "text", name "username", id "username", value user.username, onInput UpdateUsername, attribute "autocomplete" "username", css [ "flex-grow block w-full min-w-0 rounded-none rounded-r-md border-gray-300 sm:text-sm", focus [ ring_500 color, border_500 color ] ] ] []
                        ]
                    ]
                , div []
                    [ label [ for "bio", class "block text-sm font-medium text-gray-700" ] [ text "Bio" ]
                    , div [ class "mt-1" ]
                        [ textarea [ name "bio", id "bio", value (user.bio |> Maybe.withDefault ""), onInput UpdateBio, rows 3, css [ "shadow-sm mt-1 block w-full border border-gray-300 rounded-md sm:text-sm", focus [ ring_500 color, border_500 color ] ] ] []
                        ]
                    , p [ class "mt-2 text-sm text-gray-500" ]
                        [ text "Present yourself in a few words." ]
                    ]
                ]
            , div [ class "mt-6 flex-grow lg:mt-0 lg:ml-6 lg:flex-grow-0 lg:flex-shrink-0" ]
                [ p [ class "text-sm font-medium text-gray-700", ariaHidden True ]
                    [ text "Photo" ]
                , div [ class "mt-1 lg:hidden" ]
                    [ div [ class "flex items-center" ]
                        [ div [ class "flex-shrink-0 inline-block rounded-full overflow-hidden h-12 w-12", ariaHidden True ]
                            [ img [ class "rounded-full h-full w-full", src (user |> User.avatar), alt user.name ] []
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
                    [ img [ class "relative rounded-full w-40 h-40", src (user |> User.avatar), alt user.name ] []
                    , label [ for "desktop-user-photo", class "absolute inset-0 w-full h-full bg-black bg-opacity-75 flex items-center justify-center text-sm font-medium text-white opacity-0 hover:opacity-100 focus-within:opacity-100" ]
                        [ span [] [ text "Change" ]
                        , span [ class "sr-only" ] [ text "user photo" ]
                        , input [ type_ "file", name "user-photo", id "desktop-user-photo", class "absolute inset-0 w-full h-full opacity-0 cursor-pointer border-gray-300 rounded-md" ] []
                        ]
                    ]
                ]
            ]
        , div [ class "mt-6 grid grid-cols-12 gap-6" ]
            [ inputText color False "name" "Name" "" user.name UpdateName "col-span-12 sm:col-span-6"
            , inputText color True "email" "Email" "" user.email Noop "col-span-12"
            , inputText color False "website" "Website" "ex: https://azimutt.app" (user.website |> Maybe.withDefault "") UpdateWebsite "col-span-12"
            , inputText color False "location" "Location" "ex: Paris, France" (user.location |> Maybe.withDefault "") UpdateLocation "col-span-12 sm:col-span-6"
            , inputText color False "company" "Company" "ex: Azimutt" (user.company |> Maybe.withDefault "") UpdateCompany "col-span-12 sm:col-span-6"
            , inputText color False "github" "Github username" "ex: azimuttapp" (user.github |> Maybe.withDefault "") UpdateGithub "col-span-12 sm:col-span-6"
            , inputText color False "twitter" "Twitter username" "ex: azimuttapp" (user.twitter |> Maybe.withDefault "") UpdateTwitter "col-span-12 sm:col-span-6"
            ]
        ]


inputText : Color -> Bool -> String -> String -> String -> String -> (String -> msg) -> TwClass -> Html msg
inputText color inputDisabled inputName inputLabel inputPlaceholder inputValue inputUpdate styles =
    div [ class styles ]
        [ label [ for inputName, class "block text-sm font-medium text-gray-700" ] [ text inputLabel ]
        , input [ type_ "text", name inputName, id inputName, placeholder inputPlaceholder, value inputValue, onInput inputUpdate, disabled inputDisabled, attribute "autocomplete" inputName, css [ "mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 sm:text-sm", focus [ ring_500 color, border_500 color, "outline-none" ], Tw.disabled [ "bg-slate-50 text-slate-500 border-slate-200 shadow-none" ] ] ] []
        ]



--inputToggle : Color -> Int -> String -> String -> Bool -> msg -> Html msg
--inputToggle color index label description value update =
--    let
--        htmlId : String
--        htmlId =
--            "privacy-option-" ++ String.fromInt index
--    in
--    li [ class "py-4 flex items-center justify-between" ]
--        [ div [ class "flex flex-col" ]
--            [ p [ class "text-sm font-medium text-gray-900", id (htmlId ++ "-label") ]
--                [ text label ]
--            , p [ class "text-sm text-gray-500", id (htmlId ++ "-description") ]
--                [ text description ]
--            ]
--        , button [ type_ "button", role "switch", onClick update, ariaChecked True, ariaLabelledby (htmlId ++ "-label"), ariaDescribedby (htmlId ++ "-description"), css [ Bool.cond value (bg_500 color) "bg-gray-200", "ml-4 relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200", focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ] ] ]
--            [ span [ ariaHidden True, css [ Bool.cond value "translate-x-5" "translate-x-0", "inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0 transition ease-in-out duration-200" ] ] []
--            ]
--        ]


formButtons : Color -> Bool -> Maybe User -> Maybe User -> Html Msg
formButtons color updating initial current =
    div [ class "mt-4 py-4 px-4 sm:px-6 flex justify-between" ]
        [ button [ type_ "button", onClick DeleteAccount, css [ bg_700 Tw.red, "invisible border border-transparent rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-white", hover [ bg_800 Tw.red ], focus [ ring_500 Tw.red, "outline-none ring-2 ring-offset-2" ], Tw.disabled [ "opacity-50" ] ] ]
            [ text "Delete account" ]
        , div [ class " flex justify-end" ]
            [ button [ type_ "button", disabled (initial == current), onClick ResetUser, css [ "bg-white border border-gray-300 rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-gray-700 hover:bg-gray-50", focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ], Tw.disabled [ "opacity-50" ] ] ]
                [ text "Reset" ]
            , if updating then
                button [ type_ "button", disabled True, css [ bg_700 color, "ml-5 border border-transparent rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-white", hover [ bg_800 color ], focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ], Tw.disabled [ "opacity-50" ] ] ]
                    [ Icon.loading "animate-spin mr-3", text "Save" ]

              else
                button [ type_ "button", disabled (initial == current), onClick (current |> Maybe.mapOrElse UpdateUser (Noop "no-user-to-update")), css [ bg_700 color, "ml-5 border border-transparent rounded-md shadow-sm py-2 px-4 inline-flex justify-center text-sm font-medium text-white", hover [ bg_800 color ], focus [ ring_500 color, "outline-none ring-2 ring-offset-2" ], Tw.disabled [ "opacity-50" ] ] ]
                    [ text "Save" ]
            ]
        ]
