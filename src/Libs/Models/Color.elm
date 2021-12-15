module Libs.Models.Color exposing (Color, HexColor, RgbColor, all, amber, bg, blue, border, border_b, cyan, decode, default, divide, emerald, encode, from, fuchsia, gray, green, hex, hexToRgb, indigo, lime, list, orange, pink, placeholder, purple, red, rgba, ring, ringOffset, rose, sky, teal, text, to, via, violet, yellow)

import Css exposing (Style)
import Css.Global
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.TwColor exposing (TwColorLevel(..))
import Libs.Regex as R



-- from https://tailwindcss.com/docs/customizing-colors#color-palette-reference


type alias Color =
    { name : String, l50 : HexColor, l100 : HexColor, l200 : HexColor, l300 : HexColor, l400 : HexColor, l500 : HexColor, l600 : HexColor, l700 : HexColor, l800 : HexColor, l900 : HexColor }


type alias HexColor =
    String


type alias RgbColor =
    { red : Int, green : Int, blue : Int }


type alias RgbaColor =
    { red : Int, green : Int, blue : Int, alpha : String }


list : List Color
list =
    [ red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose ]


all : List Color
all =
    list ++ [ slate, gray, zinc, neutral, stone ]


default : Color
default =
    slate


slate : Color
slate =
    { name = "slate", l50 = "#f8fafc", l100 = "#f1f5f9", l200 = "#e2e8f0", l300 = "#cbd5e1", l400 = "#94a3b8", l500 = "#64748b", l600 = "#475569", l700 = "#334155", l800 = "#1e293b", l900 = "#0f172a" }


gray : Color
gray =
    { name = "gray", l50 = "#f9fafb", l100 = "#f3f4f6", l200 = "#e5e7eb", l300 = "#d1d5db", l400 = "#9ca3af", l500 = "#6b7280", l600 = "#4b5563", l700 = "#374151", l800 = "#1f2937", l900 = "#111827" }


zinc : Color
zinc =
    { name = "zinc", l50 = "#fafafa", l100 = "#f4f4f5", l200 = "#e4e4e7", l300 = "#d4d4d8", l400 = "#a1a1aa", l500 = "#71717a", l600 = "#52525b", l700 = "#3f3f46", l800 = "#27272a", l900 = "#18181b" }


neutral : Color
neutral =
    { name = "neutral", l50 = "#fafafa", l100 = "#f5f5f5", l200 = "#e5e5e5", l300 = "#d4d4d4", l400 = "#a3a3a3", l500 = "#737373", l600 = "#525252", l700 = "#404040", l800 = "#262626", l900 = "#171717" }


stone : Color
stone =
    { name = "stone", l50 = "#fafaf9", l100 = "#f5f5f4", l200 = "#e7e5e4", l300 = "#d6d3d1", l400 = "#a8a29e", l500 = "#78716c", l600 = "#57534e", l700 = "#44403c", l800 = "#292524", l900 = "#1c1917" }


red : Color
red =
    { name = "red", l50 = "#fef2f2", l100 = "#fee2e2", l200 = "#fecaca", l300 = "#fca5a5", l400 = "#f87171", l500 = "#ef4444", l600 = "#dc2626", l700 = "#b91c1c", l800 = "#991b1b", l900 = "#7f1d1d" }


orange : Color
orange =
    { name = "orange", l50 = "#fff7ed", l100 = "#ffedd5", l200 = "#fed7aa", l300 = "#fdba74", l400 = "#fb923c", l500 = "#f97316", l600 = "#ea580c", l700 = "#c2410c", l800 = "#9a3412", l900 = "#7c2d12" }


amber : Color
amber =
    { name = "amber", l50 = "#fffbeb", l100 = "#fef3c7", l200 = "#fde68a", l300 = "#fcd34d", l400 = "#fbbf24", l500 = "#f59e0b", l600 = "#d97706", l700 = "#b45309", l800 = "#92400e", l900 = "#78350f" }


yellow : Color
yellow =
    { name = "yellow", l50 = "#fefce8", l100 = "#fef9c3", l200 = "#fef08a", l300 = "#fde047", l400 = "#facc15", l500 = "#eab308", l600 = "#ca8a04", l700 = "#a16207", l800 = "#854d0e", l900 = "#713f12" }


lime : Color
lime =
    { name = "lime", l50 = "#f7fee7", l100 = "#ecfccb", l200 = "#d9f99d", l300 = "#bef264", l400 = "#a3e635", l500 = "#84cc16", l600 = "#65a30d", l700 = "#4d7c0f", l800 = "#3f6212", l900 = "#365314" }


green : Color
green =
    { name = "green", l50 = "#f0fdf4", l100 = "#dcfce7", l200 = "#bbf7d0", l300 = "#86efac", l400 = "#4ade80", l500 = "#22c55e", l600 = "#16a34a", l700 = "#15803d", l800 = "#166534", l900 = "#14532d" }


emerald : Color
emerald =
    { name = "emerald", l50 = "#ecfdf5", l100 = "#d1fae5", l200 = "#a7f3d0", l300 = "#6ee7b7", l400 = "#34d399", l500 = "#10b981", l600 = "#059669", l700 = "#047857", l800 = "#065f46", l900 = "#064e3b" }


teal : Color
teal =
    { name = "teal", l50 = "#f0fdfa", l100 = "#ccfbf1", l200 = "#99f6e4", l300 = "#5eead4", l400 = "#2dd4bf", l500 = "#14b8a6", l600 = "#0d9488", l700 = "#0f766e", l800 = "#115e59", l900 = "#134e4a" }


cyan : Color
cyan =
    { name = "cyan", l50 = "#ecfeff", l100 = "#cffafe", l200 = "#a5f3fc", l300 = "#67e8f9", l400 = "#22d3ee", l500 = "#06b6d4", l600 = "#0891b2", l700 = "#0e7490", l800 = "#155e75", l900 = "#164e63" }


sky : Color
sky =
    { name = "sky", l50 = "#f0f9ff", l100 = "#e0f2fe", l200 = "#bae6fd", l300 = "#7dd3fc", l400 = "#38bdf8", l500 = "#0ea5e9", l600 = "#0284c7", l700 = "#0369a1", l800 = "#075985", l900 = "#0c4a6e" }


blue : Color
blue =
    { name = "blue", l50 = "#eff6ff", l100 = "#dbeafe", l200 = "#bfdbfe", l300 = "#93c5fd", l400 = "#60a5fa", l500 = "#3b82f6", l600 = "#2563eb", l700 = "#1d4ed8", l800 = "#1e40af", l900 = "#1e3a8a" }


indigo : Color
indigo =
    { name = "indigo", l50 = "#eef2ff", l100 = "#e0e7ff", l200 = "#c7d2fe", l300 = "#a5b4fc", l400 = "#818cf8", l500 = "#6366f1", l600 = "#4f46e5", l700 = "#4338ca", l800 = "#3730a3", l900 = "#312e81" }


violet : Color
violet =
    { name = "violet", l50 = "#f5f3ff", l100 = "#ede9fe", l200 = "#ddd6fe", l300 = "#c4b5fd", l400 = "#a78bfa", l500 = "#8b5cf6", l600 = "#7c3aed", l700 = "#6d28d9", l800 = "#5b21b6", l900 = "#4c1d95" }


purple : Color
purple =
    { name = "purple", l50 = "#faf5ff", l100 = "#f3e8ff", l200 = "#d8b4fe", l300 = "#d8b4fe", l400 = "#c084fc", l500 = "#a855f7", l600 = "#9333ea", l700 = "#7e22ce", l800 = "#6b21a8", l900 = "#581c87" }


fuchsia : Color
fuchsia =
    { name = "fuchsia", l50 = "#fdf4ff", l100 = "#fae8ff", l200 = "#f5d0fe", l300 = "#f0abfc", l400 = "#e879f9", l500 = "#d946ef", l600 = "#c026d3", l700 = "#a21caf", l800 = "#86198f", l900 = "#701a75" }


pink : Color
pink =
    { name = "pink", l50 = "#fdf2f8", l100 = "#fce7f3", l200 = "#fbcfe8", l300 = "#f9a8d4", l400 = "#f472b6", l500 = "#ec4899", l600 = "#db2777", l700 = "#be185d", l800 = "#9d174d", l900 = "#831843" }


rose : Color
rose =
    { name = "rose", l50 = "#fff1f2", l100 = "#ffe4e6", l200 = "#fecdd3", l300 = "#fda4af", l400 = "#fb7185", l500 = "#f43f5e", l600 = "#e11d48", l700 = "#be123c", l800 = "#9f1239", l900 = "#881337" }


bg : Color -> TwColorLevel -> Style
bg color level =
    Css.batch
        [ Css.property "--tw-bg-opacity" "1"
        , Css.property "background-color" (color |> rgba "var(--tw-bg-opacity)" level)
        ]


border : Color -> TwColorLevel -> Style
border color level =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-color" (color |> rgba "var(--tw-border-opacity)" level)
        ]


border_b : Color -> TwColorLevel -> Style
border_b color level =
    Css.batch
        [ Css.property "--tw-border-opacity" "1"
        , Css.property "border-bottom-color" (color |> rgba "var(--tw-border-opacity)" level)
        ]


divide : Color -> TwColorLevel -> Style
divide color level =
    Css.batch
        [ Css.Global.children
            [ Css.Global.selector ":not([hidden]) ~ :not([hidden])"
                [ Css.property "--tw-divide-opacity" "1"
                , Css.property "border-color" (color |> rgba "var(--tw-divide-opacity)" level)
                ]
            ]
        ]


from : Color -> TwColorLevel -> Style
from color level =
    Css.batch
        [ Css.property "--tw-gradient-from" (color |> hex level)
        , Css.property "--tw-gradient-stops" ("var(--tw-gradient-from), var(--tw-gradient-to, " ++ (color |> rgba "0" level) ++ ")")
        ]


placeholder : Color -> TwColorLevel -> Style
placeholder color level =
    Css.batch
        [ Css.pseudoElement "placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" (color |> rgba "var(--tw-placeholder-opacity)" level)
            ]
        , Css.pseudoClass "-ms-input-placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" (color |> rgba "var(--tw-placeholder-opacity)" level)
            ]
        , Css.pseudoElement "-moz-placeholder"
            [ Css.property "--tw-placeholder-opacity" "1"
            , Css.property "color" (color |> rgba "var(--tw-placeholder-opacity)" level)
            ]
        ]


ring : Color -> TwColorLevel -> Style
ring color level =
    Css.batch
        [ Css.property "--tw-ring-opacity" "1"
        , Css.property "--tw-ring-color" (color |> rgba "var(--tw-ring-opacity)" level)
        ]


ringOffset : Color -> TwColorLevel -> Style
ringOffset color level =
    Css.property "--tw-ring-offset-color" (color |> hex level)


text : Color -> TwColorLevel -> Style
text color level =
    Css.batch
        [ Css.property "--tw-text-opacity" "1"
        , Css.property "color" (color |> rgba "var(--tw-text-opacity)" level)
        ]


to : Color -> TwColorLevel -> Style
to color level =
    Css.property "--tw-gradient-to" (color |> hex level)


via : Color -> TwColorLevel -> Style
via color level =
    Css.property "--tw-gradient-stops" ("var(--tw-gradient-from), " ++ (color |> hex level) ++ ", var(--tw-gradient-to, " ++ (color |> rgba "0" level) ++ ")")


rgba : String -> TwColorLevel -> Color -> String
rgba alpha level color =
    color
        |> hex level
        |> hexToRgb
        |> Maybe.withDefault (RgbColor 0 0 0)
        |> (\c -> "rgba(" ++ ([ c.red, c.green, c.blue ] |> List.map String.fromInt |> String.join ", ") ++ ", " ++ alpha ++ ")")


hex : TwColorLevel -> Color -> String
hex level color =
    case level of
        L50 ->
            color.l50

        L100 ->
            color.l100

        L200 ->
            color.l200

        L300 ->
            color.l300

        L400 ->
            color.l400

        L500 ->
            color.l500

        L600 ->
            color.l600

        L700 ->
            color.l700

        L800 ->
            color.l800

        L900 ->
            color.l900


hexToRgb : HexColor -> Maybe RgbColor
hexToRgb color =
    case color |> String.toLower |> R.matches "#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})" of
        (Just r) :: (Just g) :: (Just b) :: [] ->
            Maybe.map3 RgbColor (hexToDec r) (hexToDec g) (hexToDec b)

        _ ->
            Nothing


hexToDec : String -> Maybe Int
hexToDec number =
    number
        |> String.toList
        |> List.map (\c -> "0123456789abcdef" |> String.indexes (String.fromChar c) |> List.head)
        |> List.foldl (Maybe.map2 (\value acc -> value + acc * 16)) (Just 0)


encode : Color -> Value
encode value =
    Encode.string value.name


decode : Decode.Decoder Color
decode =
    Decode.string |> Decode.andThen (\name -> all |> L.find (\c -> c.name == name) |> M.mapOrElse Decode.succeed (Decode.fail ("Unknown color: '" ++ name ++ "'")))
