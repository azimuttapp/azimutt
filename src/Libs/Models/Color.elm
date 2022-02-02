module Libs.Models.Color exposing (Color, ColorLevel, all, amber, black, blue, cyan, decode, default, emerald, encode, fuchsia, gray, green, indigo, levels, lime, list, orange, pink, primary, purple, red, rose, sky, teal, violet, white, yellow)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as L
import Libs.Maybe as M



-- from https://tailwindcss.com/docs/customizing-colors#color-palette-reference


type alias Color =
    String


type alias ColorLevel =
    Int


list : List Color
list =
    [ indigo, violet, purple, fuchsia, pink, rose, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue ]


all : List Color
all =
    list ++ [ primary, default, black, white, gray ]


default : Color
default =
    "default"


primary : Color
primary =
    "primary"


black : Color
black =
    "black"


white : Color
white =
    "white"


gray : Color
gray =
    "gray"


red : Color
red =
    "red"


orange : Color
orange =
    "orange"


amber : Color
amber =
    "amber"


yellow : Color
yellow =
    "yellow"


lime : Color
lime =
    "lime"


green : Color
green =
    "green"


emerald : Color
emerald =
    "emerald"


teal : Color
teal =
    "teal"


cyan : Color
cyan =
    "cyan"


sky : Color
sky =
    "sky"


blue : Color
blue =
    "blue"


indigo : Color
indigo =
    "indigo"


violet : Color
violet =
    "violet"


purple : Color
purple =
    "purple"


fuchsia : Color
fuchsia =
    "fuchsia"


pink : Color
pink =
    "pink"


rose : Color
rose =
    "rose"


levels : List ColorLevel
levels =
    [ 50, 100, 200, 300, 400, 500, 600, 700, 800, 900 ]


encode : Color -> Value
encode color =
    Encode.string color


decode : Decode.Decoder Color
decode =
    Decode.string |> Decode.andThen (\name -> all |> L.find (\c -> c == name) |> M.mapOrElse Decode.succeed (Decode.fail ("Unknown color: '" ++ name ++ "'")))
