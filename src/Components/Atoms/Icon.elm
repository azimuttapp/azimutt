module Components.Atoms.Icon exposing (arrowCircleDown, arrowCircleRight, arrowRight, arrowsExpand, beaker, bell, chatAlt2, check, clipboardCheck, clipboardCopy, cloudUpload, code, cog, collection, colorSwatch, doc, document, documentAdd, documentDownload, documentDuplicate, documentRemove, documentReport, documentSearch, dotsHorizontal, dotsVertical, download, duplicate, exclamation, exclamationCircle, externalLink, eye, eyeOff, filter, fingerPrint, gift, github, hand, heart, inbox, informationCircle, key, lightBulb, lightningBolt, link, locationMarker, lockClosed, mail, mailSolid, menu, phone, phoneSolid, photograph, play, plus, plusSm, refresh, search, searchSolid, server, shieldCheck, sparkles, table, tag, template, terminal, thumbDown, thumbUp, ticket, trash, trendingUp, twitter, upload, user, userCircle, userGroup, viewBoards, viewGrid, x)

import Css exposing (Style)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html)
import Libs.Html.Styled.Attributes exposing (ariaHidden, role)
import Svg.Styled exposing (path, svg)
import Svg.Styled.Attributes exposing (clipRule, css, d, fill, fillRule, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox)
import Tailwind.Utilities exposing (h_5, h_6, w_5, w_6)



-- sorted alphabetically, see https://heroicons.com and https://simpleicons.org


arrowCircleDown : List Style -> Html msg
arrowCircleDown =
    icon Outline [ "M15 13l-3 3m0 0l-3-3m3 3V8m0 13a9 9 0 110-18 9 9 0 010 18z" ]


arrowCircleRight : List Style -> Html msg
arrowCircleRight =
    icon Outline [ "M13 9l3 3m0 0l-3 3m3-3H8m13 0a9 9 0 11-18 0 9 9 0 0118 0z" ]


arrowsExpand : List Style -> Html msg
arrowsExpand =
    icon Outline [ "M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" ]


arrowRight : List Style -> Html msg
arrowRight =
    icon Outline [ "M14 5l7 7m0 0l-7 7m7-7H3" ]


beaker : List Style -> Html msg
beaker =
    icon Outline [ "M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" ]


bell : List Style -> Html msg
bell =
    icon Outline [ "M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" ]


chatAlt2 : List Style -> Html msg
chatAlt2 =
    icon Outline [ "M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" ]


check : List Style -> Html msg
check =
    icon Outline [ "M5 13l4 4L19 7" ]


clipboardCheck : List Style -> Html msg
clipboardCheck =
    icon Outline [ "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" ]


clipboardCopy : List Style -> Html msg
clipboardCopy =
    icon Outline [ "M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" ]


cloudUpload : List Style -> Html msg
cloudUpload =
    icon Outline [ "M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" ]


code : List Style -> Html msg
code =
    icon Outline [ "M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" ]


cog : List Style -> Html msg
cog =
    icon Outline [ "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z", "M15 12a3 3 0 11-6 0 3 3 0 016 0z" ]


collection : List Style -> Html msg
collection =
    icon Outline [ "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" ]


colorSwatch : List Style -> Html msg
colorSwatch =
    icon Outline [ "M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" ]


document : List Style -> Html msg
document =
    icon Outline [ "M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" ]


documentAdd : List Style -> Html msg
documentAdd =
    icon Outline [ "M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" ]


documentDownload : List Style -> Html msg
documentDownload =
    icon Outline [ "M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" ]


documentDuplicate : List Style -> Html msg
documentDuplicate =
    icon Outline [ "M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" ]


documentRemove : List Style -> Html msg
documentRemove =
    icon Outline [ "M9 13h6m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" ]


documentReport : List Style -> Html msg
documentReport =
    icon Outline [ "M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" ]


documentSearch : List Style -> Html msg
documentSearch =
    icon Outline [ "M10 21h7a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v11m0 5l4.879-4.879m0 0a3 3 0 104.243-4.242 3 3 0 00-4.243 4.242z" ]


dotsHorizontal : List Style -> Html msg
dotsHorizontal =
    icon Outline [ "M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z" ]


dotsVertical : List Style -> Html msg
dotsVertical =
    icon Outline [ "M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" ]


download : List Style -> Html msg
download =
    icon Outline [ "M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" ]


duplicate : List Style -> Html msg
duplicate =
    icon Outline [ "M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" ]


exclamationCircle : List Style -> Html msg
exclamationCircle =
    icon Outline [ "M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" ]


exclamation : List Style -> Html msg
exclamation =
    icon Outline [ "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" ]


externalLink : List Style -> Html msg
externalLink =
    icon Outline [ "M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" ]


eye : List Style -> Html msg
eye =
    icon Outline [ "M15 12a3 3 0 11-6 0 3 3 0 016 0z", "M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" ]


eyeOff : List Style -> Html msg
eyeOff =
    icon Outline [ "M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" ]


filter : List Style -> Html msg
filter =
    icon Outline [ "M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" ]


fingerPrint : List Style -> Html msg
fingerPrint =
    icon Outline [ "M12 11c0 3.517-1.009 6.799-2.753 9.571m-3.44-2.04l.054-.09A13.916 13.916 0 008 11a4 4 0 118 0c0 1.017-.07 2.019-.203 3m-2.118 6.844A21.88 21.88 0 0015.171 17m3.839 1.132c.645-2.266.99-4.659.99-7.132A8 8 0 008 4.07M3 15.364c.64-1.319 1-2.8 1-4.364 0-1.457.39-2.823 1.07-4" ]


gift : List Style -> Html msg
gift =
    icon Outline [ "M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7" ]


github : List Style -> Html msg
github =
    icon Social [ "M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" ]


hand : List Style -> Html msg
hand =
    icon Outline [ "M7 11.5V14m0-2.5v-6a1.5 1.5 0 113 0m-3 6a1.5 1.5 0 00-3 0v2a7.5 7.5 0 0015 0v-5a1.5 1.5 0 00-3 0m-6-3V11m0-5.5v-1a1.5 1.5 0 013 0v1m0 0V11m0-5.5a1.5 1.5 0 013 0v3m0 0V11" ]


heart : List Style -> Html msg
heart =
    icon Outline [ "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" ]


inbox : List Style -> Html msg
inbox =
    icon Outline [ "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" ]


informationCircle : List Style -> Html msg
informationCircle =
    icon Outline [ "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" ]


key : List Style -> Html msg
key =
    icon Outline [ "M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" ]


lightBulb : List Style -> Html msg
lightBulb =
    icon Outline [ "M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" ]


lightningBolt : List Style -> Html msg
lightningBolt =
    icon Outline [ "M13 10V3L4 14h7v7l9-11h-7z" ]


link : List Style -> Html msg
link =
    icon Outline [ "M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" ]


locationMarker : List Style -> Html msg
locationMarker =
    icon Outline [ "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z", "M15 11a3 3 0 11-6 0 3 3 0 016 0z" ]


lockClosed : List Style -> Html msg
lockClosed =
    icon Outline [ "M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" ]


mail : List Style -> Html msg
mail =
    icon Outline [ "M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" ]


mailSolid : List Style -> Html msg
mailSolid =
    icon Solid [ "M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z", "M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z" ]


menu : List Style -> Html msg
menu =
    icon Outline [ "M4 6h16M4 12h16M4 18h16" ]


phone : List Style -> Html msg
phone =
    icon Outline [ "M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" ]


phoneSolid : List Style -> Html msg
phoneSolid =
    icon Solid [ "M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z" ]


photograph : List Style -> Html msg
photograph =
    icon Outline [ "M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" ]


play : List Style -> Html msg
play =
    icon Outline [ "M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z", "M21 12a9 9 0 11-18 0 9 9 0 0118 0z" ]


plus : List Style -> Html msg
plus =
    icon Outline [ "M12 4v16m8-8H4" ]


plusSm : List Style -> Html msg
plusSm =
    icon Outline [ "M12 6v6m0 0v6m0-6h6m-6 0H6" ]


refresh : List Style -> Html msg
refresh =
    icon Outline [ "M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" ]


search : List Style -> Html msg
search =
    icon Outline [ "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" ]


searchSolid : List Style -> Html msg
searchSolid =
    icon Solid [ "M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" ]


server : List Style -> Html msg
server =
    icon Outline [ "M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" ]


shieldCheck : List Style -> Html msg
shieldCheck =
    icon Outline [ "M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" ]


sparkles : List Style -> Html msg
sparkles =
    icon Outline [ "M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" ]


table : List Style -> Html msg
table =
    icon Outline [ "M3 10h18M3 14h18m-9-4v8m-7 0h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" ]


tag : List Style -> Html msg
tag =
    icon Outline [ "M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" ]


template : List Style -> Html msg
template =
    icon Outline [ "M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z" ]


terminal : List Style -> Html msg
terminal =
    icon Outline [ "M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" ]


thumbDown : List Style -> Html msg
thumbDown =
    icon Outline [ "M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2m5-10h2a2 2 0 012 2v6a2 2 0 01-2 2h-2.5" ]


thumbUp : List Style -> Html msg
thumbUp =
    icon Outline [ "M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" ]


ticket : List Style -> Html msg
ticket =
    icon Outline [ "M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z" ]


trash : List Style -> Html msg
trash =
    icon Outline [ "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" ]


trendingUp : List Style -> Html msg
trendingUp =
    icon Outline [ "M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" ]


twitter : List Style -> Html msg
twitter =
    icon Social [ "M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z" ]


upload : List Style -> Html msg
upload =
    icon Outline [ "M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" ]


user : List Style -> Html msg
user =
    icon Outline [ "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" ]


userCircle : List Style -> Html msg
userCircle =
    icon Outline [ "M5.121 17.804A13.937 13.937 0 0112 16c2.5 0 4.847.655 6.879 1.804M15 10a3 3 0 11-6 0 3 3 0 016 0zm6 2a9 9 0 11-18 0 9 9 0 0118 0z" ]


userGroup : List Style -> Html msg
userGroup =
    icon Outline [ "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" ]


viewBoards : List Style -> Html msg
viewBoards =
    icon Outline [ "M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" ]


viewGrid : List Style -> Html msg
viewGrid =
    icon Outline [ "M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" ]


x : List Style -> Html msg
x =
    icon Outline [ "M6 18L18 6M6 6l12 12" ]


zoomIn : List Style -> Html msg
zoomIn =
    icon Outline [ "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" ]


zoomOut : List Style -> Html msg
zoomOut =
    icon Outline [ "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM13 10H7" ]



-- HELPERS


type IconStyle
    = Solid
    | Outline
    | Social


icon : IconStyle -> List String -> List Style -> Html msg
icon style lines styles =
    case style of
        Solid ->
            svg [ css ([ h_5, w_5 ] ++ styles), viewBox "0 0 20 20", fill "currentColor", ariaHidden True ]
                (lines |> List.map (\line -> path [ fillRule "evenodd", clipRule "evenodd", d line ] []))

        Outline ->
            svg [ css ([ h_6, w_6 ] ++ styles), viewBox "0 0 24 24", fill "none", stroke "currentColor", ariaHidden True ]
                (lines |> List.map (\line -> path [ strokeLinecap "round", strokeLinejoin "round", strokeWidth "2", d line ] []))

        Social ->
            svg [ css ([ h_6, w_6 ] ++ styles), viewBox "0 0 24 24", fill "currentColor", role "img", ariaHidden True ]
                (lines |> List.map (\line -> path [ d line ] []))



-- DOCUMENTATION


doc : Chapter x
doc =
    chapter "Icon"
        |> renderComponentList
            (List.map (Tuple.mapSecond (\f -> f []))
                [ ( "arrowCircleDown", arrowCircleDown )
                , ( "arrowCircleRight", arrowCircleRight )
                , ( "arrowsExpand", arrowsExpand )
                , ( "arrowRight", arrowRight )
                , ( "beaker", beaker )
                , ( "bell", bell )
                , ( "chatAlt2", chatAlt2 )
                , ( "check", check )
                , ( "clipboardCheck", clipboardCheck )
                , ( "clipboardCopy", clipboardCopy )
                , ( "cloudUpload", cloudUpload )
                , ( "code", code )
                , ( "cog", cog )
                , ( "collection", collection )
                , ( "colorSwatch", colorSwatch )
                , ( "document", document )
                , ( "documentAdd", documentAdd )
                , ( "documentDownload", documentDownload )
                , ( "documentDuplicate", documentDuplicate )
                , ( "documentRemove", documentRemove )
                , ( "documentReport", documentReport )
                , ( "documentSearch", documentSearch )
                , ( "dotsHorizontal", dotsHorizontal )
                , ( "dotsVertical", dotsVertical )
                , ( "download", download )
                , ( "duplicate", duplicate )
                , ( "exclamationCircle", exclamationCircle )
                , ( "exclamation", exclamation )
                , ( "externalLink", externalLink )
                , ( "eye", eye )
                , ( "eyeOff", eyeOff )
                , ( "filter", filter )
                , ( "fingerPrint", fingerPrint )
                , ( "gift", gift )
                , ( "github", github )
                , ( "hand", hand )
                , ( "heart", heart )
                , ( "inbox", inbox )
                , ( "informationCircle", informationCircle )
                , ( "key", key )
                , ( "lightBulb", lightBulb )
                , ( "lightningBolt", lightningBolt )
                , ( "link", link )
                , ( "locationMarker", locationMarker )
                , ( "lockClosed", lockClosed )
                , ( "mail", mail )
                , ( "mailSolid", mailSolid )
                , ( "menu", menu )
                , ( "phone", phone )
                , ( "phoneSolid", phoneSolid )
                , ( "photograph", photograph )
                , ( "play", play )
                , ( "plus", plus )
                , ( "plusSm", plusSm )
                , ( "refresh", refresh )
                , ( "search", search )
                , ( "searchSolid", searchSolid )
                , ( "shieldCheck", shieldCheck )
                , ( "server", server )
                , ( "sparkles", sparkles )
                , ( "table", table )
                , ( "tag", tag )
                , ( "template", template )
                , ( "terminal", terminal )
                , ( "thumbDown", thumbDown )
                , ( "thumbUp", thumbUp )
                , ( "ticket", ticket )
                , ( "trash", trash )
                , ( "trendingUp", trendingUp )
                , ( "twitter", twitter )
                , ( "upload", upload )
                , ( "user", user )
                , ( "userCircle", userCircle )
                , ( "userGroup", userGroup )
                , ( "viewBoards", viewBoards )
                , ( "viewGrid", viewGrid )
                , ( "x", x )
                , ( "zoomIn", zoomIn )
                , ( "zoomOut", zoomOut )
                ]
            )
