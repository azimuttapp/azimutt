module Components.Atoms.Icon exposing (arrowCircleDown, arrowsExpand, beaker, bell, chatAlt2, check, cloudUpload, cog, collection, colorSwatch, cross, doc, documentSearch, github, inbox, lightBulb, lightningBolt, link, lockClosed, menu, photograph, refresh, search, server, shieldCheck, sparkles, twitter)

import Css exposing (Style)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html)
import Libs.Html.Styled.Attributes exposing (ariaHidden)
import Svg.Styled exposing (Attribute, path, svg)
import Svg.Styled.Attributes exposing (clipRule, css, d, fill, fillRule, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox)



-- sorted alphabetically, see https://heroicons.com


arrowCircleDown : Int -> List Style -> Html msg
arrowCircleDown =
    -- Heroicon name: outline/arrow-circle-down
    icon Outline [ "M15 13l-3 3m0 0l-3-3m3 3V8m0 13a9 9 0 110-18 9 9 0 010 18z" ]


arrowsExpand : Int -> List Style -> Html msg
arrowsExpand =
    -- Heroicon name: outline/arrows-expand
    icon Outline [ "M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" ]


beaker : Int -> List Style -> Html msg
beaker =
    -- Heroicon name: outline/beaker
    icon Outline [ "M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" ]


bell : Int -> List Style -> Html msg
bell =
    -- Heroicon name: outline/bell
    icon Outline [ "M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" ]


chatAlt2 : Int -> List Style -> Html msg
chatAlt2 =
    -- Heroicon name: outline/chat-alt-2
    icon Outline [ "M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" ]


check : Int -> List Style -> Html msg
check =
    -- Heroicon name: outline/check
    icon Outline [ "M5 13l4 4L19 7" ]


cloudUpload : Int -> List Style -> Html msg
cloudUpload =
    -- Heroicon name: outline/cloud-upload
    icon Outline [ "M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" ]


cog : Int -> List Style -> Html msg
cog =
    -- Heroicon name: outline/cog
    icon Outline [ "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z", "M15 12a3 3 0 11-6 0 3 3 0 016 0z" ]


collection : Int -> List Style -> Html msg
collection =
    -- Heroicon name: outline/collection
    icon Outline [ "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" ]


colorSwatch : Int -> List Style -> Html msg
colorSwatch =
    -- Heroicon name: outline/color-swatch
    icon Outline [ "M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" ]


cross : Int -> List Style -> Html msg
cross =
    -- Heroicon name: outline/x
    icon Outline [ "M6 18L18 6M6 6l12 12" ]


documentSearch : Int -> List Style -> Html msg
documentSearch =
    icon Outline [ "M10 21h7a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v11m0 5l4.879-4.879m0 0a3 3 0 104.243-4.242 3 3 0 00-4.243 4.242z" ]


github : Int -> List Style -> Html msg
github =
    icon Solid [ "M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" ]


inbox : Int -> List Style -> Html msg
inbox =
    icon Outline [ "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" ]


lightBulb : Int -> List Style -> Html msg
lightBulb =
    -- Heroicon name: outline/light-bulb
    icon Outline [ "M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" ]


lightningBolt : Int -> List Style -> Html msg
lightningBolt =
    -- Heroicon name: outline/lightning-bolt
    icon Outline [ "M13 10V3L4 14h7v7l9-11h-7z" ]


link : Int -> List Style -> Html msg
link =
    icon Outline [ "M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" ]


lockClosed : Int -> List Style -> Html msg
lockClosed =
    -- Heroicon name: outline/lock-closed
    icon Outline [ "M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" ]


menu : Int -> List Style -> Html msg
menu =
    -- Heroicon name: outline/menu
    icon Outline [ "M4 6h16M4 12h16M4 18h16" ]


photograph : Int -> List Style -> Html msg
photograph =
    icon Outline [ "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" ]


refresh : Int -> List Style -> Html msg
refresh =
    -- Heroicon name: outline/refresh
    icon Outline [ "M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" ]


search : Int -> List Style -> Html msg
search =
    -- Heroicon name: solid/search
    icon Solid [ "M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" ]


server : Int -> List Style -> Html msg
server =
    -- Heroicon name: outline/server
    icon Outline [ "M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" ]


shieldCheck : Int -> List Style -> Html msg
shieldCheck =
    -- Heroicon name: outline/shield-check
    icon Outline [ "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" ]


sparkles : Int -> List Style -> Html msg
sparkles =
    -- Heroicon name: outline/sparkles
    icon Outline [ "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" ]


twitter : Int -> List Style -> Html msg
twitter =
    icon Solid [ "M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" ]



-- HELPERS


type IconStyle
    = Solid
    | Outline


icon : IconStyle -> List String -> Int -> List Style -> Html msg
icon style lines size styles =
    let
        width : Style
        width =
            Css.property "width" (String.fromFloat (0.25 * toFloat size) ++ "rem")

        height : Style
        height =
            Css.property "height" (String.fromFloat (0.25 * toFloat size) ++ "rem")

        box : Attribute msg
        box =
            viewBox ("0 0 " ++ String.fromInt (size * 4) ++ " " ++ String.fromInt (size * 4))
    in
    case style of
        Solid ->
            svg [ css ([ width, height ] ++ styles), box, fill "currentColor", ariaHidden True ]
                (lines |> List.map (\line -> path [ fillRule "evenodd", clipRule "evenodd", d line ] []))

        Outline ->
            svg [ css ([ width, height ] ++ styles), box, fill "none", stroke "currentColor", ariaHidden True ]
                (lines |> List.map (\line -> path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d line ] []))



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Icon"
        |> renderComponentList
            (List.map (Tuple.mapSecond (\f -> f 6 []))
                [ ( "arrowCircleDown", arrowCircleDown )
                , ( "arrowsExpand", arrowsExpand )
                , ( "beaker", beaker )
                , ( "bell", bell )
                , ( "chatAlt2", chatAlt2 )
                , ( "check", check )
                , ( "cloudUpload", cloudUpload )
                , ( "cog", cog )
                , ( "collection", collection )
                , ( "colorSwatch", colorSwatch )
                , ( "cross", cross )
                , ( "documentSearch", documentSearch )
                , ( "github", github )
                , ( "inbox", inbox )
                , ( "lightBulb", lightBulb )
                , ( "lightningBolt", lightningBolt )
                , ( "link", link )
                , ( "lockClosed", lockClosed )
                , ( "menu", menu )
                , ( "photograph", photograph )
                , ( "refresh", refresh )
                , ( "search", search )
                , ( "shieldCheck", shieldCheck )
                , ( "server", server )
                , ( "sparkles", sparkles )
                , ( "twitter", twitter )
                ]
            )
