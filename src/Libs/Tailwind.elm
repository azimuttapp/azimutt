module Libs.Tailwind exposing (TwClass, active, batch, bg_100, bg_200, bg_300, bg_50, bg_500, bg_600, bg_700, border_400, border_500, disabled, focus, focusWithin, focus_ring_500, focus_ring_offset_600, focus_ring_within_600, hover, lg, md, ring_500, ring_600, ring_offset_600, sm, stroke_500, text_300, text_400, text_500, text_600, text_700, text_800, xl, xxl)

import Libs.Models.Color exposing (Color, ColorLevel)


type alias TwClass =
    String



-- HELPERS


focus_ring_500 : Color -> TwClass
focus_ring_500 ringColor =
    focus [ "outline-none ring-2 ring-offset-2", ring_500 ringColor, "ring-offset-white" ]


focus_ring_within_600 : Color -> TwClass
focus_ring_within_600 ringColor =
    focusWithin [ "outline-none ring-2 ring-offset-2", ring_600 ringColor, "ring-offset-white" ]


focus_ring_offset_600 : Color -> TwClass
focus_ring_offset_600 ringOffsetColor =
    focus [ "outline-none ring-2 ring-offset-2", "ring-white", ring_offset_600 ringOffsetColor ]


batch : List TwClass -> TwClass
batch classes =
    classes |> List.map String.trim |> List.filter (\v -> v /= "") |> String.join " "



-- DYNAMIC STATE CLASSES
-- they are handled in tailwind.config.js `transform` with `expandDynamicStates`
-- this function expand them for tailwind parser, so it's really important to not break syntax


sm : List TwClass -> TwClass
sm =
    addState "sm"


md : List TwClass -> TwClass
md =
    addState "md"


lg : List TwClass -> TwClass
lg =
    addState "lg"


xl : List TwClass -> TwClass
xl =
    addState "xl"


xxl : List TwClass -> TwClass
xxl =
    addState "2xl"


hover : List TwClass -> TwClass
hover =
    addState "hover"


focus : List TwClass -> TwClass
focus =
    addState "focus"


active : List TwClass -> TwClass
active =
    addState "active"


disabled : List TwClass -> TwClass
disabled =
    addState "disabled"


focusWithin : List TwClass -> TwClass
focusWithin =
    addState "focus-within"


addState : String -> List TwClass -> TwClass
addState state classes =
    classes |> String.join " " |> String.split " " |> List.map String.trim |> List.filter (\c -> c /= "") |> List.map (\c -> state ++ ":" ++ c) |> String.join " "



-- DYNAMIC COLOR CLASSES
-- they are handled in tailwind.config.js `transform` with `expandDynamicColors`
-- this function expand them for tailwind parser, so it's really important to not break syntax


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


ring_600 : Color -> TwClass
ring_600 color =
    "ring-" ++ color ++ "-600"


ring_offset_600 : Color -> TwClass
ring_offset_600 color =
    "ring-offset-" ++ color ++ "-600"


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
