module Components.Atoms.Icon exposing (arrowCircleDown, arrowsExpand, beaker, chatAlt2, check, cloudUpload, cog, collection, colorSwatch, cross, doc, documentSearch, github, inbox, lightBulb, lightningBolt, link, lockClosed, menu, photograph, refresh, server, shieldCheck, sparkles, twitter)

import Css exposing (Style)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html)
import Libs.Html.Styled.Attributes exposing (ariaHidden)
import Svg.Styled exposing (path, svg)
import Svg.Styled.Attributes exposing (clipRule, css, d, fill, fillRule, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox)
import Tailwind.Utilities exposing (h_6, w_6)



-- sorted alphabetically, see https://heroicons.com


arrowCircleDown : List Style -> Html msg
arrowCircleDown styles =
    -- Heroicon name: outline/arrow-circle-down
    outlineIcon styles "M15 13l-3 3m0 0l-3-3m3 3V8m0 13a9 9 0 110-18 9 9 0 010 18z"


arrowsExpand : List Style -> Html msg
arrowsExpand styles =
    -- Heroicon name: outline/arrows-expand
    outlineIcon styles "M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"


beaker : List Style -> Html msg
beaker styles =
    -- Heroicon name: outline/beaker
    outlineIcon styles "M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"


chatAlt2 : List Style -> Html msg
chatAlt2 styles =
    -- Heroicon name: outline/chat-alt-2
    outlineIcon styles "M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z"


check : List Style -> Html msg
check styles =
    -- Heroicon name: outline/check
    outlineIcon styles "M5 13l4 4L19 7"


cloudUpload : List Style -> Html msg
cloudUpload styles =
    -- Heroicon name: outline/cloud-upload
    outlineIcon styles "M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"


cog : List Style -> Html msg
cog styles =
    -- Heroicon name: outline/cog
    svg [ css ([ h_6, w_6 ] ++ styles), fill "none", viewBox "0 0 24 24", stroke "currentColor", ariaHidden True ]
        [ path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" ] []
        , path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d "M15 12a3 3 0 11-6 0 3 3 0 016 0z" ] []
        ]


collection : List Style -> Html msg
collection styles =
    -- Heroicon name: outline/collection
    outlineIcon styles "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"


colorSwatch : List Style -> Html msg
colorSwatch styles =
    -- Heroicon name: outline/color-swatch
    outlineIcon styles "M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"


cross : List Style -> Html msg
cross styles =
    -- Heroicon name: outline/x
    outlineIcon styles "M6 18L18 6M6 6l12 12"


documentSearch : List Style -> Html msg
documentSearch styles =
    outlineIcon styles "M10 21h7a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v11m0 5l4.879-4.879m0 0a3 3 0 104.243-4.242 3 3 0 00-4.243 4.242z"


github : List Style -> Html msg
github styles =
    solidIcon styles "M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"


inbox : List Style -> Html msg
inbox styles =
    outlineIcon styles "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"


lightBulb : List Style -> Html msg
lightBulb styles =
    -- Heroicon name: outline/light-bulb
    outlineIcon styles "M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"


lightningBolt : List Style -> Html msg
lightningBolt styles =
    -- Heroicon name: outline/lightning-bolt
    outlineIcon styles "M13 10V3L4 14h7v7l9-11h-7z"


link : List Style -> Html msg
link styles =
    outlineIcon styles "M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"


lockClosed : List Style -> Html msg
lockClosed styles =
    -- Heroicon name: outline/lock-closed
    outlineIcon styles "M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"


menu : List Style -> Html msg
menu styles =
    -- Heroicon name: outline/menu
    outlineIcon styles "M4 6h16M4 12h16M4 18h16"


photograph : List Style -> Html msg
photograph styles =
    outlineIcon styles "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"


refresh : List Style -> Html msg
refresh styles =
    -- Heroicon name: outline/refresh
    outlineIcon styles "M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"


shieldCheck : List Style -> Html msg
shieldCheck styles =
    -- Heroicon name: outline/shield-check
    outlineIcon styles "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"


server : List Style -> Html msg
server styles =
    -- Heroicon name: outline/server
    outlineIcon styles "M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"


sparkles : List Style -> Html msg
sparkles styles =
    -- Heroicon name: outline/sparkles
    outlineIcon styles "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"


twitter : List Style -> Html msg
twitter styles =
    solidIcon styles "M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84"


outlineIcon : List Style -> String -> Html msg
outlineIcon styles draw =
    svg [ css ([ h_6, w_6 ] ++ styles), fill "none", viewBox "0 0 24 24", stroke "currentColor", ariaHidden True ]
        [ path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d draw ] []
        ]


solidIcon : List Style -> String -> Html msg
solidIcon styles draw =
    svg [ css ([ h_6, w_6 ] ++ styles), fill "currentColor", viewBox "0 0 24 24", ariaHidden True ]
        [ path [ fillRule "evenodd", clipRule "evenodd", d draw ] []
        ]


doc : Chapter x
doc =
    chapter "Icon"
        |> renderComponentList
            [ ( "arrowCircleDown", arrowCircleDown [] )
            , ( "arrowsExpand", arrowsExpand [] )
            , ( "beaker", beaker [] )
            , ( "chatAlt2", chatAlt2 [] )
            , ( "check", check [] )
            , ( "cloudUpload", cloudUpload [] )
            , ( "cog", cog [] )
            , ( "collection", collection [] )
            , ( "colorSwatch", colorSwatch [] )
            , ( "cross", cross [] )
            , ( "documentSearch", documentSearch [] )
            , ( "github", github [] )
            , ( "inbox", inbox [] )
            , ( "lightBulb", lightBulb [] )
            , ( "lightningBolt", lightningBolt [] )
            , ( "link", link [] )
            , ( "lockClosed", lockClosed [] )
            , ( "menu", menu [] )
            , ( "photograph", photograph [] )
            , ( "refresh", refresh [] )
            , ( "shieldCheck", shieldCheck [] )
            , ( "server", server [] )
            , ( "sparkles", sparkles [] )
            , ( "twitter", twitter [] )
            ]
