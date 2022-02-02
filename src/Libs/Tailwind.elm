module Libs.Tailwind exposing (TwClass, active, batch, bg, bg_100, bg_200, bg_300, bg_50, bg_500, bg_600, bg_700, border_400, border_500, disabled, focus, focusRing, focusWithin, focusWithinRing, hover, lg, md, ring_500, sm, stroke_500, text_300, text_400, text_500, text_600, text_700, text_800, xl, xxl)

import Libs.Models.Color exposing (Color, ColorLevel)


type alias TwClass =
    String



-- BAD HELPERS
-- will have to replace them as they make tailwind class generation quite hard :(


focusRing : ( Color, ColorLevel ) -> ( Color, ColorLevel ) -> TwClass
focusRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    "outline-none ring-2 ring-offset-2 " ++ ring ringColor ringLevel ++ " " ++ ringOffset offsetColor offsetLevel |> focus


focusWithinRing : ( Color, ColorLevel ) -> ( Color, ColorLevel ) -> TwClass
focusWithinRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    "outline-none ring-2 ring-offset-2 " ++ ring ringColor ringLevel ++ " " ++ ringOffset offsetColor offsetLevel |> focusWithin


bg : Color -> ColorLevel -> TwClass
bg color level =
    "bg-" ++ color ++ "-" ++ String.fromInt level


ring : Color -> ColorLevel -> TwClass
ring color level =
    "ring-" ++ color ++ "-" ++ String.fromInt level


ringOffset : Color -> ColorLevel -> TwClass
ringOffset color level =
    "ring-offset-" ++ color ++ "-" ++ String.fromInt level


batch : List TwClass -> TwClass
batch classes =
    classes |> List.map String.trim |> List.filter (\v -> v /= "") |> String.join " "



-- SYNTAX HELPERS
-- must be handled by tailwind.config.js `transform`


sm : TwClass -> TwClass
sm =
    addState "sm"


md : TwClass -> TwClass
md =
    addState "md"


lg : TwClass -> TwClass
lg =
    addState "lg"


xl : TwClass -> TwClass
xl =
    addState "xl"


xxl : TwClass -> TwClass
xxl =
    addState "2xl"


hover : TwClass -> TwClass
hover =
    addState "hover"


focus : TwClass -> TwClass
focus =
    addState "focus"


active : TwClass -> TwClass
active =
    addState "active"


disabled : TwClass -> TwClass
disabled =
    addState "disabled"


focusWithin : TwClass -> TwClass
focusWithin =
    addState "focus-within"


addState : String -> TwClass -> TwClass
addState state classes =
    classes |> String.split " " |> List.map String.trim |> List.filter (\c -> c /= "") |> List.map (\c -> state ++ ":" ++ c) |> String.join " "



-- DYNAMIC CLASSES
-- must be added to tailwind.config.js `safelist`


bg_50 : Color -> TwClass
bg_50 color =
    "bg-" ++ color ++ "-50"


bg_100 : Color -> TwClass
bg_100 color =
    "bg-" ++ color ++ "-100"


bg_200 : Color -> TwClass
bg_200 color =
    "bg-" ++ color ++ "-200"


bg_300 : Color -> TwClass
bg_300 color =
    "bg-" ++ color ++ "-300"


bg_500 : Color -> TwClass
bg_500 color =
    "bg-" ++ color ++ "-500"


bg_600 : Color -> TwClass
bg_600 color =
    "bg-" ++ color ++ "-600"


bg_700 : Color -> TwClass
bg_700 color =
    "bg-" ++ color ++ "-700"


border_400 : Color -> TwClass
border_400 color =
    "border-" ++ color ++ "-400"


border_500 : Color -> TwClass
border_500 color =
    "border-" ++ color ++ "-500"


ring_500 : Color -> TwClass
ring_500 color =
    "ring-" ++ color ++ "-500"


stroke_500 : Color -> TwClass
stroke_500 color =
    "stroke-" ++ color ++ "-500"


text_300 : Color -> TwClass
text_300 color =
    "text-" ++ color ++ "-300"


text_400 : Color -> TwClass
text_400 color =
    "text-" ++ color ++ "-400"


text_500 : Color -> TwClass
text_500 color =
    "text-" ++ color ++ "-500"


text_600 : Color -> TwClass
text_600 color =
    "text-" ++ color ++ "-600"


text_700 : Color -> TwClass
text_700 color =
    "text-" ++ color ++ "-700"


text_800 : Color -> TwClass
text_800 color =
    "text-" ++ color ++ "-800"
