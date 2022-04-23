module Libs.Tailwind exposing (Color, ColorLevel, TwClass, active, all, amber, batch, bg_100, bg_200, bg_300, bg_50, bg_500, bg_600, bg_700, black, blue, border_400, border_500, cyan, decodeColor, default, disabled, emerald, encodeColor, extractColor, fill_500, focus, focusWithin, focus_ring_500, focus_ring_offset_600, focus_ring_within_600, from, fuchsia, gray, green, hover, indigo, levels, lg, lime, list, md, orange, pink, primary, purple, red, ring_200, ring_500, ring_600, ring_offset_600, rose, sky, sm, stroke_500, teal, text_300, text_400, text_500, text_600, text_700, text_800, violet, white, xl, xxl, yellow)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as List
import Libs.Maybe as Maybe


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
bg_50 (Color color) =
    "bg-" ++ color ++ "-50"


bg_100 : Color -> TwClass
bg_100 (Color color) =
    "bg-" ++ color ++ "-100"


bg_200 : Color -> TwClass
bg_200 (Color color) =
    "bg-" ++ color ++ "-200"


bg_300 : Color -> TwClass
bg_300 (Color color) =
    "bg-" ++ color ++ "-300"


bg_500 : Color -> TwClass
bg_500 (Color color) =
    "bg-" ++ color ++ "-500"


bg_600 : Color -> TwClass
bg_600 (Color color) =
    "bg-" ++ color ++ "-600"


bg_700 : Color -> TwClass
bg_700 (Color color) =
    "bg-" ++ color ++ "-700"


border_400 : Color -> TwClass
border_400 (Color color) =
    "border-" ++ color ++ "-400"


border_500 : Color -> TwClass
border_500 (Color color) =
    "border-" ++ color ++ "-500"


fill_500 : Color -> TwClass
fill_500 (Color color) =
    "fill-" ++ color ++ "-500"


ring_200 : Color -> TwClass
ring_200 (Color color) =
    "ring-" ++ color ++ "-200"


ring_500 : Color -> TwClass
ring_500 (Color color) =
    "ring-" ++ color ++ "-500"


ring_600 : Color -> TwClass
ring_600 (Color color) =
    "ring-" ++ color ++ "-600"


ring_offset_600 : Color -> TwClass
ring_offset_600 (Color color) =
    "ring-offset-" ++ color ++ "-600"


stroke_500 : Color -> TwClass
stroke_500 (Color color) =
    "stroke-" ++ color ++ "-500"


text_300 : Color -> TwClass
text_300 (Color color) =
    "text-" ++ color ++ "-300"


text_400 : Color -> TwClass
text_400 (Color color) =
    "text-" ++ color ++ "-400"


text_500 : Color -> TwClass
text_500 (Color color) =
    "text-" ++ color ++ "-500"


text_600 : Color -> TwClass
text_600 (Color color) =
    "text-" ++ color ++ "-600"


text_700 : Color -> TwClass
text_700 (Color color) =
    "text-" ++ color ++ "-700"


text_800 : Color -> TwClass
text_800 (Color color) =
    "text-" ++ color ++ "-800"



-- Color definition


type Color
    = Color String


type alias ColorLevel =
    Int


list : List Color
list =
    [ indigo, violet, purple, fuchsia, pink, rose, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue ]


all : List Color
all =
    list ++ [ primary, default, black, white, gray ]


from : String -> Maybe Color
from value =
    all |> List.find (\(Color c) -> c == value)


default : Color
default =
    Color "default"


primary : Color
primary =
    Color "primary"


black : Color
black =
    Color "black"


white : Color
white =
    Color "white"


gray : Color
gray =
    Color "gray"


red : Color
red =
    Color "red"


orange : Color
orange =
    Color "orange"


amber : Color
amber =
    Color "amber"


yellow : Color
yellow =
    Color "yellow"


lime : Color
lime =
    Color "lime"


green : Color
green =
    Color "green"


emerald : Color
emerald =
    Color "emerald"


teal : Color
teal =
    Color "teal"


cyan : Color
cyan =
    Color "cyan"


sky : Color
sky =
    Color "sky"


blue : Color
blue =
    Color "blue"


indigo : Color
indigo =
    Color "indigo"


violet : Color
violet =
    Color "violet"


purple : Color
purple =
    Color "purple"


fuchsia : Color
fuchsia =
    Color "fuchsia"


pink : Color
pink =
    Color "pink"


rose : Color
rose =
    Color "rose"


levels : List ColorLevel
levels =
    [ 50, 100, 200, 300, 400, 500, 600, 700, 800, 900 ]


encodeColor : Color -> Value
encodeColor (Color color) =
    Encode.string color


decodeColor : Decode.Decoder Color
decodeColor =
    Decode.string |> Decode.andThen (\name -> all |> List.find (\(Color c) -> c == name) |> Maybe.mapOrElse Decode.succeed (Decode.fail ("Unknown color: '" ++ name ++ "'")))


extractColor : Color -> String
extractColor (Color color) =
    -- FIXME this function should be removed when possible
    color
