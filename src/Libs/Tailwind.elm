module Libs.Tailwind exposing (TwClass, active, batch, bg_100, bg_200, bg_300, bg_400, bg_50, bg_500, bg_600, bg_700, border_300, border_400, border_500, border_700, border_b_200, disabled, focus, focusRing, focusWithin, focusWithinRing, hover, lg, md, placeholder_200, placeholder_400, ring_500, ring_offset_600, sm, stroke_400, stroke_500, text_100, text_200, text_300, text_400, text_500, text_600, text_700, text_800, text_900, xl, xxl)

import Libs.Models.Color exposing (Color, ColorLevel)


type alias TwClass =
    String


focusRing : ( Color, ColorLevel ) -> ( Color, ColorLevel ) -> TwClass
focusRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    "outline-none ring-2 ring-offset-2 " ++ ring ringColor ringLevel ++ " " ++ ringOffset offsetColor offsetLevel |> focus


focusWithinRing : ( Color, ColorLevel ) -> ( Color, ColorLevel ) -> TwClass
focusWithinRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    "outline-none ring-2 ring-offset-2 " ++ ring ringColor ringLevel ++ " " ++ ringOffset offsetColor offsetLevel |> focusWithin


ring : Color -> ColorLevel -> TwClass
ring color level =
    "ring-" ++ color.name ++ "-" ++ String.fromInt level


ringOffset : Color -> ColorLevel -> TwClass
ringOffset color level =
    "ring-offset-" ++ color.name ++ "-" ++ String.fromInt level


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
    "bg-" ++ color.name ++ "-50"


bg_100 : Color -> TwClass
bg_100 color =
    "bg-" ++ color.name ++ "-100"


bg_200 : Color -> TwClass
bg_200 color =
    "bg-" ++ color.name ++ "-200"


bg_300 : Color -> TwClass
bg_300 color =
    "bg-" ++ color.name ++ "-300"


bg_400 : Color -> TwClass
bg_400 color =
    "bg-" ++ color.name ++ "-400"


bg_500 : Color -> TwClass
bg_500 color =
    "bg-" ++ color.name ++ "-500"


bg_600 : Color -> TwClass
bg_600 color =
    "bg-" ++ color.name ++ "-600"


bg_700 : Color -> TwClass
bg_700 color =
    "bg-" ++ color.name ++ "-700"


border_300 : Color -> TwClass
border_300 color =
    "border-" ++ color.name ++ "-300"


border_400 : Color -> TwClass
border_400 color =
    "border-" ++ color.name ++ "-400"


border_500 : Color -> TwClass
border_500 color =
    "border-" ++ color.name ++ "-500"


border_700 : Color -> TwClass
border_700 color =
    "border-" ++ color.name ++ "-700"


border_b_200 : Color -> TwClass
border_b_200 color =
    "border-b-" ++ color.name ++ "-200"


placeholder_200 : Color -> TwClass
placeholder_200 color =
    "placeholder-" ++ color.name ++ "-200"


placeholder_400 : Color -> TwClass
placeholder_400 color =
    "placeholder-" ++ color.name ++ "-400"


ring_500 : Color -> TwClass
ring_500 color =
    "ring-" ++ color.name ++ "-500"


ring_offset_600 : Color -> TwClass
ring_offset_600 color =
    "ring-offset-" ++ color.name ++ "-600"


stroke_400 : Color -> TwClass
stroke_400 color =
    "stroke-" ++ color.name ++ "-400"


stroke_500 : Color -> TwClass
stroke_500 color =
    "stroke-" ++ color.name ++ "-500"


text_100 : Color -> TwClass
text_100 color =
    "text-" ++ color.name ++ "-100"


text_200 : Color -> TwClass
text_200 color =
    "text-" ++ color.name ++ "-200"


text_300 : Color -> TwClass
text_300 color =
    "text-" ++ color.name ++ "-300"


text_400 : Color -> TwClass
text_400 color =
    "text-" ++ color.name ++ "-400"


text_500 : Color -> TwClass
text_500 color =
    "text-" ++ color.name ++ "-500"


text_600 : Color -> TwClass
text_600 color =
    "text-" ++ color.name ++ "-600"


text_700 : Color -> TwClass
text_700 color =
    "text-" ++ color.name ++ "-700"


text_800 : Color -> TwClass
text_800 color =
    "text-" ++ color.name ++ "-800"


text_900 : Color -> TwClass
text_900 color =
    "text-" ++ color.name ++ "-900"
