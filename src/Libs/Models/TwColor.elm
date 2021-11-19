module Libs.Models.TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..), colorToString, colors, levelToString, levels, render, toHex)

import Array
import Css
import Tailwind.Utilities as Tw


type TwColor
    = Blue
    | Gray
    | Green
    | Indigo
    | Pink
    | Purple
    | Red
    | Yellow
    | Black
    | White
    | Current
    | Transparent


type TwColorLevel
    = L50
    | L100
    | L200
    | L300
    | L400
    | L500
    | L600
    | L700
    | L800
    | L900


type TwColorPosition
    = Bg
    | Border
    | Divide
    | From
    | Placeholder
    | Ring
    | RingOffset
    | Text
    | To
    | Via


colors : List TwColor
colors =
    [ Blue, Gray, Green, Indigo, Pink, Purple, Red, Yellow, Black, White, Current, Transparent ]


levels : List TwColorLevel
levels =
    [ L50, L100, L200, L300, L400, L500, L600, L700, L800, L900 ]


colorToString : TwColor -> String
colorToString color =
    case color of
        Blue ->
            "blue"

        Gray ->
            "gray"

        Green ->
            "green"

        Indigo ->
            "indigo"

        Pink ->
            "pink"

        Purple ->
            "purple"

        Red ->
            "red"

        Yellow ->
            "yellow"

        Black ->
            "black"

        White ->
            "white"

        Current ->
            "current"

        Transparent ->
            "transparent"


levelToString : TwColorLevel -> String
levelToString level =
    case level of
        L50 ->
            "50"

        L100 ->
            "100"

        L200 ->
            "200"

        L300 ->
            "300"

        L400 ->
            "400"

        L500 ->
            "500"

        L600 ->
            "600"

        L700 ->
            "700"

        L800 ->
            "800"

        L900 ->
            "900"


toHex : TwColorLevel -> TwColor -> String
toHex level color =
    color |> withLevel level |> colorToHex


type alias Color =
    ( Int, Int, Int )


withLevel : TwColorLevel -> TwColor -> Color
withLevel level color =
    case color of
        Blue ->
            case level of
                L50 ->
                    ( 239, 246, 255 )

                L100 ->
                    ( 219, 234, 254 )

                L200 ->
                    ( 191, 219, 254 )

                L300 ->
                    ( 147, 197, 253 )

                L400 ->
                    ( 96, 165, 250 )

                L500 ->
                    ( 59, 130, 246 )

                L600 ->
                    ( 37, 99, 235 )

                L700 ->
                    ( 29, 78, 216 )

                L800 ->
                    ( 30, 64, 175 )

                L900 ->
                    ( 30, 58, 138 )

        Gray ->
            case level of
                L50 ->
                    ( 249, 250, 251 )

                L100 ->
                    ( 243, 244, 246 )

                L200 ->
                    ( 229, 231, 235 )

                L300 ->
                    ( 209, 213, 219 )

                L400 ->
                    ( 156, 163, 175 )

                L500 ->
                    ( 107, 114, 128 )

                L600 ->
                    ( 75, 85, 99 )

                L700 ->
                    ( 55, 65, 81 )

                L800 ->
                    ( 31, 41, 55 )

                L900 ->
                    ( 17, 24, 39 )

        Green ->
            case level of
                L50 ->
                    ( 236, 253, 245 )

                L100 ->
                    ( 209, 250, 229 )

                L200 ->
                    ( 167, 243, 208 )

                L300 ->
                    ( 110, 231, 183 )

                L400 ->
                    ( 52, 211, 153 )

                L500 ->
                    ( 16, 185, 129 )

                L600 ->
                    ( 5, 150, 105 )

                L700 ->
                    ( 4, 120, 87 )

                L800 ->
                    ( 6, 95, 70 )

                L900 ->
                    ( 6, 78, 59 )

        Indigo ->
            case level of
                L50 ->
                    ( 238, 242, 255 )

                L100 ->
                    ( 224, 231, 255 )

                L200 ->
                    ( 199, 210, 254 )

                L300 ->
                    ( 165, 180, 252 )

                L400 ->
                    ( 129, 140, 248 )

                L500 ->
                    ( 99, 102, 241 )

                L600 ->
                    ( 79, 70, 229 )

                L700 ->
                    ( 67, 56, 202 )

                L800 ->
                    ( 55, 48, 163 )

                L900 ->
                    ( 49, 46, 129 )

        Pink ->
            case level of
                L50 ->
                    ( 253, 242, 248 )

                L100 ->
                    ( 252, 231, 243 )

                L200 ->
                    ( 251, 207, 232 )

                L300 ->
                    ( 249, 168, 212 )

                L400 ->
                    ( 244, 114, 182 )

                L500 ->
                    ( 236, 72, 153 )

                L600 ->
                    ( 219, 39, 119 )

                L700 ->
                    ( 190, 24, 93 )

                L800 ->
                    ( 157, 23, 77 )

                L900 ->
                    ( 131, 24, 67 )

        Purple ->
            case level of
                L50 ->
                    ( 245, 243, 255 )

                L100 ->
                    ( 237, 233, 254 )

                L200 ->
                    ( 221, 214, 254 )

                L300 ->
                    ( 196, 181, 253 )

                L400 ->
                    ( 167, 139, 250 )

                L500 ->
                    ( 139, 92, 246 )

                L600 ->
                    ( 124, 58, 237 )

                L700 ->
                    ( 109, 40, 217 )

                L800 ->
                    ( 91, 33, 182 )

                L900 ->
                    ( 76, 29, 149 )

        Red ->
            case level of
                L50 ->
                    ( 254, 242, 242 )

                L100 ->
                    ( 254, 226, 226 )

                L200 ->
                    ( 254, 202, 202 )

                L300 ->
                    ( 252, 165, 165 )

                L400 ->
                    ( 248, 113, 113 )

                L500 ->
                    ( 239, 68, 68 )

                L600 ->
                    ( 220, 38, 38 )

                L700 ->
                    ( 185, 28, 28 )

                L800 ->
                    ( 153, 27, 27 )

                L900 ->
                    ( 127, 29, 29 )

        Yellow ->
            case level of
                L50 ->
                    ( 255, 251, 235 )

                L100 ->
                    ( 254, 243, 199 )

                L200 ->
                    ( 253, 230, 138 )

                L300 ->
                    ( 252, 211, 77 )

                L400 ->
                    ( 251, 191, 36 )

                L500 ->
                    ( 245, 158, 11 )

                L600 ->
                    ( 217, 119, 6 )

                L700 ->
                    ( 180, 83, 9 )

                L800 ->
                    ( 146, 64, 14 )

                L900 ->
                    ( 120, 53, 15 )

        Black ->
            ( 0, 0, 0 )

        White ->
            ( 255, 255, 255 )

        Current ->
            ( 256, 0, 0 )

        Transparent ->
            ( 257, 0, 0 )


colorToHex : Color -> String
colorToHex ( r, g, b ) =
    case r of
        256 ->
            "currentColor"

        257 ->
            "transparent"

        _ ->
            "#" ++ byteToHex r ++ byteToHex g ++ byteToHex b


byteToHex : Int -> String
byteToHex dec =
    [ dec // 16, dec |> modBy 16 ] |> List.map getHexChar |> String.fromList


getHexChar : Int -> Char
getHexChar i =
    hexDigits |> Array.get i |> Maybe.withDefault '?'


hexDigits : Array.Array Char
hexDigits =
    Array.fromList (String.toList "0123456789ABCDEF")


render : TwColorPosition -> TwColor -> TwColorLevel -> Css.Style
render pos color level =
    case pos of
        Bg ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.bg_blue_50

                        L100 ->
                            Tw.bg_blue_100

                        L200 ->
                            Tw.bg_blue_200

                        L300 ->
                            Tw.bg_blue_300

                        L400 ->
                            Tw.bg_blue_400

                        L500 ->
                            Tw.bg_blue_500

                        L600 ->
                            Tw.bg_blue_600

                        L700 ->
                            Tw.bg_blue_700

                        L800 ->
                            Tw.bg_blue_800

                        L900 ->
                            Tw.bg_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.bg_gray_50

                        L100 ->
                            Tw.bg_gray_100

                        L200 ->
                            Tw.bg_gray_200

                        L300 ->
                            Tw.bg_gray_300

                        L400 ->
                            Tw.bg_gray_400

                        L500 ->
                            Tw.bg_gray_500

                        L600 ->
                            Tw.bg_gray_600

                        L700 ->
                            Tw.bg_gray_700

                        L800 ->
                            Tw.bg_gray_800

                        L900 ->
                            Tw.bg_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.bg_green_50

                        L100 ->
                            Tw.bg_green_100

                        L200 ->
                            Tw.bg_green_200

                        L300 ->
                            Tw.bg_green_300

                        L400 ->
                            Tw.bg_green_400

                        L500 ->
                            Tw.bg_green_500

                        L600 ->
                            Tw.bg_green_600

                        L700 ->
                            Tw.bg_green_700

                        L800 ->
                            Tw.bg_green_800

                        L900 ->
                            Tw.bg_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.bg_indigo_50

                        L100 ->
                            Tw.bg_indigo_100

                        L200 ->
                            Tw.bg_indigo_200

                        L300 ->
                            Tw.bg_indigo_300

                        L400 ->
                            Tw.bg_indigo_400

                        L500 ->
                            Tw.bg_indigo_500

                        L600 ->
                            Tw.bg_indigo_600

                        L700 ->
                            Tw.bg_indigo_700

                        L800 ->
                            Tw.bg_indigo_800

                        L900 ->
                            Tw.bg_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.bg_pink_50

                        L100 ->
                            Tw.bg_pink_100

                        L200 ->
                            Tw.bg_pink_200

                        L300 ->
                            Tw.bg_pink_300

                        L400 ->
                            Tw.bg_pink_400

                        L500 ->
                            Tw.bg_pink_500

                        L600 ->
                            Tw.bg_pink_600

                        L700 ->
                            Tw.bg_pink_700

                        L800 ->
                            Tw.bg_pink_800

                        L900 ->
                            Tw.bg_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.bg_purple_50

                        L100 ->
                            Tw.bg_purple_100

                        L200 ->
                            Tw.bg_purple_200

                        L300 ->
                            Tw.bg_purple_300

                        L400 ->
                            Tw.bg_purple_400

                        L500 ->
                            Tw.bg_purple_500

                        L600 ->
                            Tw.bg_purple_600

                        L700 ->
                            Tw.bg_purple_700

                        L800 ->
                            Tw.bg_purple_800

                        L900 ->
                            Tw.bg_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.bg_red_50

                        L100 ->
                            Tw.bg_red_100

                        L200 ->
                            Tw.bg_red_200

                        L300 ->
                            Tw.bg_red_300

                        L400 ->
                            Tw.bg_red_400

                        L500 ->
                            Tw.bg_red_500

                        L600 ->
                            Tw.bg_red_600

                        L700 ->
                            Tw.bg_red_700

                        L800 ->
                            Tw.bg_red_800

                        L900 ->
                            Tw.bg_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.bg_yellow_50

                        L100 ->
                            Tw.bg_yellow_100

                        L200 ->
                            Tw.bg_yellow_200

                        L300 ->
                            Tw.bg_yellow_300

                        L400 ->
                            Tw.bg_yellow_400

                        L500 ->
                            Tw.bg_yellow_500

                        L600 ->
                            Tw.bg_yellow_600

                        L700 ->
                            Tw.bg_yellow_700

                        L800 ->
                            Tw.bg_yellow_800

                        L900 ->
                            Tw.bg_yellow_900

                Black ->
                    Tw.bg_black

                White ->
                    Tw.bg_white

                Current ->
                    Tw.bg_current

                Transparent ->
                    Tw.bg_transparent

        Border ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.border_blue_50

                        L100 ->
                            Tw.border_blue_100

                        L200 ->
                            Tw.border_blue_200

                        L300 ->
                            Tw.border_blue_300

                        L400 ->
                            Tw.border_blue_400

                        L500 ->
                            Tw.border_blue_500

                        L600 ->
                            Tw.border_blue_600

                        L700 ->
                            Tw.border_blue_700

                        L800 ->
                            Tw.border_blue_800

                        L900 ->
                            Tw.border_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.border_gray_50

                        L100 ->
                            Tw.border_gray_100

                        L200 ->
                            Tw.border_gray_200

                        L300 ->
                            Tw.border_gray_300

                        L400 ->
                            Tw.border_gray_400

                        L500 ->
                            Tw.border_gray_500

                        L600 ->
                            Tw.border_gray_600

                        L700 ->
                            Tw.border_gray_700

                        L800 ->
                            Tw.border_gray_800

                        L900 ->
                            Tw.border_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.border_green_50

                        L100 ->
                            Tw.border_green_100

                        L200 ->
                            Tw.border_green_200

                        L300 ->
                            Tw.border_green_300

                        L400 ->
                            Tw.border_green_400

                        L500 ->
                            Tw.border_green_500

                        L600 ->
                            Tw.border_green_600

                        L700 ->
                            Tw.border_green_700

                        L800 ->
                            Tw.border_green_800

                        L900 ->
                            Tw.border_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.border_indigo_50

                        L100 ->
                            Tw.border_indigo_100

                        L200 ->
                            Tw.border_indigo_200

                        L300 ->
                            Tw.border_indigo_300

                        L400 ->
                            Tw.border_indigo_400

                        L500 ->
                            Tw.border_indigo_500

                        L600 ->
                            Tw.border_indigo_600

                        L700 ->
                            Tw.border_indigo_700

                        L800 ->
                            Tw.border_indigo_800

                        L900 ->
                            Tw.border_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.border_pink_50

                        L100 ->
                            Tw.border_pink_100

                        L200 ->
                            Tw.border_pink_200

                        L300 ->
                            Tw.border_pink_300

                        L400 ->
                            Tw.border_pink_400

                        L500 ->
                            Tw.border_pink_500

                        L600 ->
                            Tw.border_pink_600

                        L700 ->
                            Tw.border_pink_700

                        L800 ->
                            Tw.border_pink_800

                        L900 ->
                            Tw.border_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.border_purple_50

                        L100 ->
                            Tw.border_purple_100

                        L200 ->
                            Tw.border_purple_200

                        L300 ->
                            Tw.border_purple_300

                        L400 ->
                            Tw.border_purple_400

                        L500 ->
                            Tw.border_purple_500

                        L600 ->
                            Tw.border_purple_600

                        L700 ->
                            Tw.border_purple_700

                        L800 ->
                            Tw.border_purple_800

                        L900 ->
                            Tw.border_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.border_red_50

                        L100 ->
                            Tw.border_red_100

                        L200 ->
                            Tw.border_red_200

                        L300 ->
                            Tw.border_red_300

                        L400 ->
                            Tw.border_red_400

                        L500 ->
                            Tw.border_red_500

                        L600 ->
                            Tw.border_red_600

                        L700 ->
                            Tw.border_red_700

                        L800 ->
                            Tw.border_red_800

                        L900 ->
                            Tw.border_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.border_yellow_50

                        L100 ->
                            Tw.border_yellow_100

                        L200 ->
                            Tw.border_yellow_200

                        L300 ->
                            Tw.border_yellow_300

                        L400 ->
                            Tw.border_yellow_400

                        L500 ->
                            Tw.border_yellow_500

                        L600 ->
                            Tw.border_yellow_600

                        L700 ->
                            Tw.border_yellow_700

                        L800 ->
                            Tw.border_yellow_800

                        L900 ->
                            Tw.border_yellow_900

                Black ->
                    Tw.border_black

                White ->
                    Tw.border_white

                Current ->
                    Tw.border_current

                Transparent ->
                    Tw.border_transparent

        Divide ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.divide_blue_50

                        L100 ->
                            Tw.divide_blue_100

                        L200 ->
                            Tw.divide_blue_200

                        L300 ->
                            Tw.divide_blue_300

                        L400 ->
                            Tw.divide_blue_400

                        L500 ->
                            Tw.divide_blue_500

                        L600 ->
                            Tw.divide_blue_600

                        L700 ->
                            Tw.divide_blue_700

                        L800 ->
                            Tw.divide_blue_800

                        L900 ->
                            Tw.divide_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.divide_gray_50

                        L100 ->
                            Tw.divide_gray_100

                        L200 ->
                            Tw.divide_gray_200

                        L300 ->
                            Tw.divide_gray_300

                        L400 ->
                            Tw.divide_gray_400

                        L500 ->
                            Tw.divide_gray_500

                        L600 ->
                            Tw.divide_gray_600

                        L700 ->
                            Tw.divide_gray_700

                        L800 ->
                            Tw.divide_gray_800

                        L900 ->
                            Tw.divide_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.divide_green_50

                        L100 ->
                            Tw.divide_green_100

                        L200 ->
                            Tw.divide_green_200

                        L300 ->
                            Tw.divide_green_300

                        L400 ->
                            Tw.divide_green_400

                        L500 ->
                            Tw.divide_green_500

                        L600 ->
                            Tw.divide_green_600

                        L700 ->
                            Tw.divide_green_700

                        L800 ->
                            Tw.divide_green_800

                        L900 ->
                            Tw.divide_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.divide_indigo_50

                        L100 ->
                            Tw.divide_indigo_100

                        L200 ->
                            Tw.divide_indigo_200

                        L300 ->
                            Tw.divide_indigo_300

                        L400 ->
                            Tw.divide_indigo_400

                        L500 ->
                            Tw.divide_indigo_500

                        L600 ->
                            Tw.divide_indigo_600

                        L700 ->
                            Tw.divide_indigo_700

                        L800 ->
                            Tw.divide_indigo_800

                        L900 ->
                            Tw.divide_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.divide_pink_50

                        L100 ->
                            Tw.divide_pink_100

                        L200 ->
                            Tw.divide_pink_200

                        L300 ->
                            Tw.divide_pink_300

                        L400 ->
                            Tw.divide_pink_400

                        L500 ->
                            Tw.divide_pink_500

                        L600 ->
                            Tw.divide_pink_600

                        L700 ->
                            Tw.divide_pink_700

                        L800 ->
                            Tw.divide_pink_800

                        L900 ->
                            Tw.divide_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.divide_purple_50

                        L100 ->
                            Tw.divide_purple_100

                        L200 ->
                            Tw.divide_purple_200

                        L300 ->
                            Tw.divide_purple_300

                        L400 ->
                            Tw.divide_purple_400

                        L500 ->
                            Tw.divide_purple_500

                        L600 ->
                            Tw.divide_purple_600

                        L700 ->
                            Tw.divide_purple_700

                        L800 ->
                            Tw.divide_purple_800

                        L900 ->
                            Tw.divide_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.divide_red_50

                        L100 ->
                            Tw.divide_red_100

                        L200 ->
                            Tw.divide_red_200

                        L300 ->
                            Tw.divide_red_300

                        L400 ->
                            Tw.divide_red_400

                        L500 ->
                            Tw.divide_red_500

                        L600 ->
                            Tw.divide_red_600

                        L700 ->
                            Tw.divide_red_700

                        L800 ->
                            Tw.divide_red_800

                        L900 ->
                            Tw.divide_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.divide_yellow_50

                        L100 ->
                            Tw.divide_yellow_100

                        L200 ->
                            Tw.divide_yellow_200

                        L300 ->
                            Tw.divide_yellow_300

                        L400 ->
                            Tw.divide_yellow_400

                        L500 ->
                            Tw.divide_yellow_500

                        L600 ->
                            Tw.divide_yellow_600

                        L700 ->
                            Tw.divide_yellow_700

                        L800 ->
                            Tw.divide_yellow_800

                        L900 ->
                            Tw.divide_yellow_900

                Black ->
                    Tw.divide_black

                White ->
                    Tw.divide_white

                Current ->
                    Tw.divide_current

                Transparent ->
                    Tw.divide_transparent

        From ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.from_blue_50

                        L100 ->
                            Tw.from_blue_100

                        L200 ->
                            Tw.from_blue_200

                        L300 ->
                            Tw.from_blue_300

                        L400 ->
                            Tw.from_blue_400

                        L500 ->
                            Tw.from_blue_500

                        L600 ->
                            Tw.from_blue_600

                        L700 ->
                            Tw.from_blue_700

                        L800 ->
                            Tw.from_blue_800

                        L900 ->
                            Tw.from_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.from_gray_50

                        L100 ->
                            Tw.from_gray_100

                        L200 ->
                            Tw.from_gray_200

                        L300 ->
                            Tw.from_gray_300

                        L400 ->
                            Tw.from_gray_400

                        L500 ->
                            Tw.from_gray_500

                        L600 ->
                            Tw.from_gray_600

                        L700 ->
                            Tw.from_gray_700

                        L800 ->
                            Tw.from_gray_800

                        L900 ->
                            Tw.from_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.from_green_50

                        L100 ->
                            Tw.from_green_100

                        L200 ->
                            Tw.from_green_200

                        L300 ->
                            Tw.from_green_300

                        L400 ->
                            Tw.from_green_400

                        L500 ->
                            Tw.from_green_500

                        L600 ->
                            Tw.from_green_600

                        L700 ->
                            Tw.from_green_700

                        L800 ->
                            Tw.from_green_800

                        L900 ->
                            Tw.from_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.from_indigo_50

                        L100 ->
                            Tw.from_indigo_100

                        L200 ->
                            Tw.from_indigo_200

                        L300 ->
                            Tw.from_indigo_300

                        L400 ->
                            Tw.from_indigo_400

                        L500 ->
                            Tw.from_indigo_500

                        L600 ->
                            Tw.from_indigo_600

                        L700 ->
                            Tw.from_indigo_700

                        L800 ->
                            Tw.from_indigo_800

                        L900 ->
                            Tw.from_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.from_pink_50

                        L100 ->
                            Tw.from_pink_100

                        L200 ->
                            Tw.from_pink_200

                        L300 ->
                            Tw.from_pink_300

                        L400 ->
                            Tw.from_pink_400

                        L500 ->
                            Tw.from_pink_500

                        L600 ->
                            Tw.from_pink_600

                        L700 ->
                            Tw.from_pink_700

                        L800 ->
                            Tw.from_pink_800

                        L900 ->
                            Tw.from_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.from_purple_50

                        L100 ->
                            Tw.from_purple_100

                        L200 ->
                            Tw.from_purple_200

                        L300 ->
                            Tw.from_purple_300

                        L400 ->
                            Tw.from_purple_400

                        L500 ->
                            Tw.from_purple_500

                        L600 ->
                            Tw.from_purple_600

                        L700 ->
                            Tw.from_purple_700

                        L800 ->
                            Tw.from_purple_800

                        L900 ->
                            Tw.from_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.from_red_50

                        L100 ->
                            Tw.from_red_100

                        L200 ->
                            Tw.from_red_200

                        L300 ->
                            Tw.from_red_300

                        L400 ->
                            Tw.from_red_400

                        L500 ->
                            Tw.from_red_500

                        L600 ->
                            Tw.from_red_600

                        L700 ->
                            Tw.from_red_700

                        L800 ->
                            Tw.from_red_800

                        L900 ->
                            Tw.from_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.from_yellow_50

                        L100 ->
                            Tw.from_yellow_100

                        L200 ->
                            Tw.from_yellow_200

                        L300 ->
                            Tw.from_yellow_300

                        L400 ->
                            Tw.from_yellow_400

                        L500 ->
                            Tw.from_yellow_500

                        L600 ->
                            Tw.from_yellow_600

                        L700 ->
                            Tw.from_yellow_700

                        L800 ->
                            Tw.from_yellow_800

                        L900 ->
                            Tw.from_yellow_900

                Black ->
                    Tw.from_black

                White ->
                    Tw.from_white

                Current ->
                    Tw.from_current

                Transparent ->
                    Tw.from_transparent

        Placeholder ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.placeholder_blue_50

                        L100 ->
                            Tw.placeholder_blue_100

                        L200 ->
                            Tw.placeholder_blue_200

                        L300 ->
                            Tw.placeholder_blue_300

                        L400 ->
                            Tw.placeholder_blue_400

                        L500 ->
                            Tw.placeholder_blue_500

                        L600 ->
                            Tw.placeholder_blue_600

                        L700 ->
                            Tw.placeholder_blue_700

                        L800 ->
                            Tw.placeholder_blue_800

                        L900 ->
                            Tw.placeholder_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.placeholder_gray_50

                        L100 ->
                            Tw.placeholder_gray_100

                        L200 ->
                            Tw.placeholder_gray_200

                        L300 ->
                            Tw.placeholder_gray_300

                        L400 ->
                            Tw.placeholder_gray_400

                        L500 ->
                            Tw.placeholder_gray_500

                        L600 ->
                            Tw.placeholder_gray_600

                        L700 ->
                            Tw.placeholder_gray_700

                        L800 ->
                            Tw.placeholder_gray_800

                        L900 ->
                            Tw.placeholder_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.placeholder_green_50

                        L100 ->
                            Tw.placeholder_green_100

                        L200 ->
                            Tw.placeholder_green_200

                        L300 ->
                            Tw.placeholder_green_300

                        L400 ->
                            Tw.placeholder_green_400

                        L500 ->
                            Tw.placeholder_green_500

                        L600 ->
                            Tw.placeholder_green_600

                        L700 ->
                            Tw.placeholder_green_700

                        L800 ->
                            Tw.placeholder_green_800

                        L900 ->
                            Tw.placeholder_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.placeholder_indigo_50

                        L100 ->
                            Tw.placeholder_indigo_100

                        L200 ->
                            Tw.placeholder_indigo_200

                        L300 ->
                            Tw.placeholder_indigo_300

                        L400 ->
                            Tw.placeholder_indigo_400

                        L500 ->
                            Tw.placeholder_indigo_500

                        L600 ->
                            Tw.placeholder_indigo_600

                        L700 ->
                            Tw.placeholder_indigo_700

                        L800 ->
                            Tw.placeholder_indigo_800

                        L900 ->
                            Tw.placeholder_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.placeholder_pink_50

                        L100 ->
                            Tw.placeholder_pink_100

                        L200 ->
                            Tw.placeholder_pink_200

                        L300 ->
                            Tw.placeholder_pink_300

                        L400 ->
                            Tw.placeholder_pink_400

                        L500 ->
                            Tw.placeholder_pink_500

                        L600 ->
                            Tw.placeholder_pink_600

                        L700 ->
                            Tw.placeholder_pink_700

                        L800 ->
                            Tw.placeholder_pink_800

                        L900 ->
                            Tw.placeholder_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.placeholder_purple_50

                        L100 ->
                            Tw.placeholder_purple_100

                        L200 ->
                            Tw.placeholder_purple_200

                        L300 ->
                            Tw.placeholder_purple_300

                        L400 ->
                            Tw.placeholder_purple_400

                        L500 ->
                            Tw.placeholder_purple_500

                        L600 ->
                            Tw.placeholder_purple_600

                        L700 ->
                            Tw.placeholder_purple_700

                        L800 ->
                            Tw.placeholder_purple_800

                        L900 ->
                            Tw.placeholder_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.placeholder_red_50

                        L100 ->
                            Tw.placeholder_red_100

                        L200 ->
                            Tw.placeholder_red_200

                        L300 ->
                            Tw.placeholder_red_300

                        L400 ->
                            Tw.placeholder_red_400

                        L500 ->
                            Tw.placeholder_red_500

                        L600 ->
                            Tw.placeholder_red_600

                        L700 ->
                            Tw.placeholder_red_700

                        L800 ->
                            Tw.placeholder_red_800

                        L900 ->
                            Tw.placeholder_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.placeholder_yellow_50

                        L100 ->
                            Tw.placeholder_yellow_100

                        L200 ->
                            Tw.placeholder_yellow_200

                        L300 ->
                            Tw.placeholder_yellow_300

                        L400 ->
                            Tw.placeholder_yellow_400

                        L500 ->
                            Tw.placeholder_yellow_500

                        L600 ->
                            Tw.placeholder_yellow_600

                        L700 ->
                            Tw.placeholder_yellow_700

                        L800 ->
                            Tw.placeholder_yellow_800

                        L900 ->
                            Tw.placeholder_yellow_900

                Black ->
                    Tw.placeholder_black

                White ->
                    Tw.placeholder_white

                Current ->
                    Tw.placeholder_current

                Transparent ->
                    Tw.placeholder_transparent

        Ring ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.ring_blue_50

                        L100 ->
                            Tw.ring_blue_100

                        L200 ->
                            Tw.ring_blue_200

                        L300 ->
                            Tw.ring_blue_300

                        L400 ->
                            Tw.ring_blue_400

                        L500 ->
                            Tw.ring_blue_500

                        L600 ->
                            Tw.ring_blue_600

                        L700 ->
                            Tw.ring_blue_700

                        L800 ->
                            Tw.ring_blue_800

                        L900 ->
                            Tw.ring_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.ring_gray_50

                        L100 ->
                            Tw.ring_gray_100

                        L200 ->
                            Tw.ring_gray_200

                        L300 ->
                            Tw.ring_gray_300

                        L400 ->
                            Tw.ring_gray_400

                        L500 ->
                            Tw.ring_gray_500

                        L600 ->
                            Tw.ring_gray_600

                        L700 ->
                            Tw.ring_gray_700

                        L800 ->
                            Tw.ring_gray_800

                        L900 ->
                            Tw.ring_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.ring_green_50

                        L100 ->
                            Tw.ring_green_100

                        L200 ->
                            Tw.ring_green_200

                        L300 ->
                            Tw.ring_green_300

                        L400 ->
                            Tw.ring_green_400

                        L500 ->
                            Tw.ring_green_500

                        L600 ->
                            Tw.ring_green_600

                        L700 ->
                            Tw.ring_green_700

                        L800 ->
                            Tw.ring_green_800

                        L900 ->
                            Tw.ring_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.ring_indigo_50

                        L100 ->
                            Tw.ring_indigo_100

                        L200 ->
                            Tw.ring_indigo_200

                        L300 ->
                            Tw.ring_indigo_300

                        L400 ->
                            Tw.ring_indigo_400

                        L500 ->
                            Tw.ring_indigo_500

                        L600 ->
                            Tw.ring_indigo_600

                        L700 ->
                            Tw.ring_indigo_700

                        L800 ->
                            Tw.ring_indigo_800

                        L900 ->
                            Tw.ring_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.ring_pink_50

                        L100 ->
                            Tw.ring_pink_100

                        L200 ->
                            Tw.ring_pink_200

                        L300 ->
                            Tw.ring_pink_300

                        L400 ->
                            Tw.ring_pink_400

                        L500 ->
                            Tw.ring_pink_500

                        L600 ->
                            Tw.ring_pink_600

                        L700 ->
                            Tw.ring_pink_700

                        L800 ->
                            Tw.ring_pink_800

                        L900 ->
                            Tw.ring_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.ring_purple_50

                        L100 ->
                            Tw.ring_purple_100

                        L200 ->
                            Tw.ring_purple_200

                        L300 ->
                            Tw.ring_purple_300

                        L400 ->
                            Tw.ring_purple_400

                        L500 ->
                            Tw.ring_purple_500

                        L600 ->
                            Tw.ring_purple_600

                        L700 ->
                            Tw.ring_purple_700

                        L800 ->
                            Tw.ring_purple_800

                        L900 ->
                            Tw.ring_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.ring_red_50

                        L100 ->
                            Tw.ring_red_100

                        L200 ->
                            Tw.ring_red_200

                        L300 ->
                            Tw.ring_red_300

                        L400 ->
                            Tw.ring_red_400

                        L500 ->
                            Tw.ring_red_500

                        L600 ->
                            Tw.ring_red_600

                        L700 ->
                            Tw.ring_red_700

                        L800 ->
                            Tw.ring_red_800

                        L900 ->
                            Tw.ring_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.ring_yellow_50

                        L100 ->
                            Tw.ring_yellow_100

                        L200 ->
                            Tw.ring_yellow_200

                        L300 ->
                            Tw.ring_yellow_300

                        L400 ->
                            Tw.ring_yellow_400

                        L500 ->
                            Tw.ring_yellow_500

                        L600 ->
                            Tw.ring_yellow_600

                        L700 ->
                            Tw.ring_yellow_700

                        L800 ->
                            Tw.ring_yellow_800

                        L900 ->
                            Tw.ring_yellow_900

                Black ->
                    Tw.ring_black

                White ->
                    Tw.ring_white

                Current ->
                    Tw.ring_current

                Transparent ->
                    Tw.ring_transparent

        RingOffset ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.ring_offset_blue_50

                        L100 ->
                            Tw.ring_offset_blue_100

                        L200 ->
                            Tw.ring_offset_blue_200

                        L300 ->
                            Tw.ring_offset_blue_300

                        L400 ->
                            Tw.ring_offset_blue_400

                        L500 ->
                            Tw.ring_offset_blue_500

                        L600 ->
                            Tw.ring_offset_blue_600

                        L700 ->
                            Tw.ring_offset_blue_700

                        L800 ->
                            Tw.ring_offset_blue_800

                        L900 ->
                            Tw.ring_offset_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.ring_offset_gray_50

                        L100 ->
                            Tw.ring_offset_gray_100

                        L200 ->
                            Tw.ring_offset_gray_200

                        L300 ->
                            Tw.ring_offset_gray_300

                        L400 ->
                            Tw.ring_offset_gray_400

                        L500 ->
                            Tw.ring_offset_gray_500

                        L600 ->
                            Tw.ring_offset_gray_600

                        L700 ->
                            Tw.ring_offset_gray_700

                        L800 ->
                            Tw.ring_offset_gray_800

                        L900 ->
                            Tw.ring_offset_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.ring_offset_green_50

                        L100 ->
                            Tw.ring_offset_green_100

                        L200 ->
                            Tw.ring_offset_green_200

                        L300 ->
                            Tw.ring_offset_green_300

                        L400 ->
                            Tw.ring_offset_green_400

                        L500 ->
                            Tw.ring_offset_green_500

                        L600 ->
                            Tw.ring_offset_green_600

                        L700 ->
                            Tw.ring_offset_green_700

                        L800 ->
                            Tw.ring_offset_green_800

                        L900 ->
                            Tw.ring_offset_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.ring_offset_indigo_50

                        L100 ->
                            Tw.ring_offset_indigo_100

                        L200 ->
                            Tw.ring_offset_indigo_200

                        L300 ->
                            Tw.ring_offset_indigo_300

                        L400 ->
                            Tw.ring_offset_indigo_400

                        L500 ->
                            Tw.ring_offset_indigo_500

                        L600 ->
                            Tw.ring_offset_indigo_600

                        L700 ->
                            Tw.ring_offset_indigo_700

                        L800 ->
                            Tw.ring_offset_indigo_800

                        L900 ->
                            Tw.ring_offset_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.ring_offset_pink_50

                        L100 ->
                            Tw.ring_offset_pink_100

                        L200 ->
                            Tw.ring_offset_pink_200

                        L300 ->
                            Tw.ring_offset_pink_300

                        L400 ->
                            Tw.ring_offset_pink_400

                        L500 ->
                            Tw.ring_offset_pink_500

                        L600 ->
                            Tw.ring_offset_pink_600

                        L700 ->
                            Tw.ring_offset_pink_700

                        L800 ->
                            Tw.ring_offset_pink_800

                        L900 ->
                            Tw.ring_offset_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.ring_offset_purple_50

                        L100 ->
                            Tw.ring_offset_purple_100

                        L200 ->
                            Tw.ring_offset_purple_200

                        L300 ->
                            Tw.ring_offset_purple_300

                        L400 ->
                            Tw.ring_offset_purple_400

                        L500 ->
                            Tw.ring_offset_purple_500

                        L600 ->
                            Tw.ring_offset_purple_600

                        L700 ->
                            Tw.ring_offset_purple_700

                        L800 ->
                            Tw.ring_offset_purple_800

                        L900 ->
                            Tw.ring_offset_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.ring_offset_red_50

                        L100 ->
                            Tw.ring_offset_red_100

                        L200 ->
                            Tw.ring_offset_red_200

                        L300 ->
                            Tw.ring_offset_red_300

                        L400 ->
                            Tw.ring_offset_red_400

                        L500 ->
                            Tw.ring_offset_red_500

                        L600 ->
                            Tw.ring_offset_red_600

                        L700 ->
                            Tw.ring_offset_red_700

                        L800 ->
                            Tw.ring_offset_red_800

                        L900 ->
                            Tw.ring_offset_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.ring_offset_yellow_50

                        L100 ->
                            Tw.ring_offset_yellow_100

                        L200 ->
                            Tw.ring_offset_yellow_200

                        L300 ->
                            Tw.ring_offset_yellow_300

                        L400 ->
                            Tw.ring_offset_yellow_400

                        L500 ->
                            Tw.ring_offset_yellow_500

                        L600 ->
                            Tw.ring_offset_yellow_600

                        L700 ->
                            Tw.ring_offset_yellow_700

                        L800 ->
                            Tw.ring_offset_yellow_800

                        L900 ->
                            Tw.ring_offset_yellow_900

                Black ->
                    Tw.ring_offset_black

                White ->
                    Tw.ring_offset_white

                Current ->
                    Tw.ring_offset_current

                Transparent ->
                    Tw.ring_offset_transparent

        Text ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.text_blue_50

                        L100 ->
                            Tw.text_blue_100

                        L200 ->
                            Tw.text_blue_200

                        L300 ->
                            Tw.text_blue_300

                        L400 ->
                            Tw.text_blue_400

                        L500 ->
                            Tw.text_blue_500

                        L600 ->
                            Tw.text_blue_600

                        L700 ->
                            Tw.text_blue_700

                        L800 ->
                            Tw.text_blue_800

                        L900 ->
                            Tw.text_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.text_gray_50

                        L100 ->
                            Tw.text_gray_100

                        L200 ->
                            Tw.text_gray_200

                        L300 ->
                            Tw.text_gray_300

                        L400 ->
                            Tw.text_gray_400

                        L500 ->
                            Tw.text_gray_500

                        L600 ->
                            Tw.text_gray_600

                        L700 ->
                            Tw.text_gray_700

                        L800 ->
                            Tw.text_gray_800

                        L900 ->
                            Tw.text_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.text_green_50

                        L100 ->
                            Tw.text_green_100

                        L200 ->
                            Tw.text_green_200

                        L300 ->
                            Tw.text_green_300

                        L400 ->
                            Tw.text_green_400

                        L500 ->
                            Tw.text_green_500

                        L600 ->
                            Tw.text_green_600

                        L700 ->
                            Tw.text_green_700

                        L800 ->
                            Tw.text_green_800

                        L900 ->
                            Tw.text_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.text_indigo_50

                        L100 ->
                            Tw.text_indigo_100

                        L200 ->
                            Tw.text_indigo_200

                        L300 ->
                            Tw.text_indigo_300

                        L400 ->
                            Tw.text_indigo_400

                        L500 ->
                            Tw.text_indigo_500

                        L600 ->
                            Tw.text_indigo_600

                        L700 ->
                            Tw.text_indigo_700

                        L800 ->
                            Tw.text_indigo_800

                        L900 ->
                            Tw.text_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.text_pink_50

                        L100 ->
                            Tw.text_pink_100

                        L200 ->
                            Tw.text_pink_200

                        L300 ->
                            Tw.text_pink_300

                        L400 ->
                            Tw.text_pink_400

                        L500 ->
                            Tw.text_pink_500

                        L600 ->
                            Tw.text_pink_600

                        L700 ->
                            Tw.text_pink_700

                        L800 ->
                            Tw.text_pink_800

                        L900 ->
                            Tw.text_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.text_purple_50

                        L100 ->
                            Tw.text_purple_100

                        L200 ->
                            Tw.text_purple_200

                        L300 ->
                            Tw.text_purple_300

                        L400 ->
                            Tw.text_purple_400

                        L500 ->
                            Tw.text_purple_500

                        L600 ->
                            Tw.text_purple_600

                        L700 ->
                            Tw.text_purple_700

                        L800 ->
                            Tw.text_purple_800

                        L900 ->
                            Tw.text_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.text_red_50

                        L100 ->
                            Tw.text_red_100

                        L200 ->
                            Tw.text_red_200

                        L300 ->
                            Tw.text_red_300

                        L400 ->
                            Tw.text_red_400

                        L500 ->
                            Tw.text_red_500

                        L600 ->
                            Tw.text_red_600

                        L700 ->
                            Tw.text_red_700

                        L800 ->
                            Tw.text_red_800

                        L900 ->
                            Tw.text_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.text_yellow_50

                        L100 ->
                            Tw.text_yellow_100

                        L200 ->
                            Tw.text_yellow_200

                        L300 ->
                            Tw.text_yellow_300

                        L400 ->
                            Tw.text_yellow_400

                        L500 ->
                            Tw.text_yellow_500

                        L600 ->
                            Tw.text_yellow_600

                        L700 ->
                            Tw.text_yellow_700

                        L800 ->
                            Tw.text_yellow_800

                        L900 ->
                            Tw.text_yellow_900

                Black ->
                    Tw.text_black

                White ->
                    Tw.text_white

                Current ->
                    Tw.text_current

                Transparent ->
                    Tw.text_transparent

        To ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.to_blue_50

                        L100 ->
                            Tw.to_blue_100

                        L200 ->
                            Tw.to_blue_200

                        L300 ->
                            Tw.to_blue_300

                        L400 ->
                            Tw.to_blue_400

                        L500 ->
                            Tw.to_blue_500

                        L600 ->
                            Tw.to_blue_600

                        L700 ->
                            Tw.to_blue_700

                        L800 ->
                            Tw.to_blue_800

                        L900 ->
                            Tw.to_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.to_gray_50

                        L100 ->
                            Tw.to_gray_100

                        L200 ->
                            Tw.to_gray_200

                        L300 ->
                            Tw.to_gray_300

                        L400 ->
                            Tw.to_gray_400

                        L500 ->
                            Tw.to_gray_500

                        L600 ->
                            Tw.to_gray_600

                        L700 ->
                            Tw.to_gray_700

                        L800 ->
                            Tw.to_gray_800

                        L900 ->
                            Tw.to_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.to_green_50

                        L100 ->
                            Tw.to_green_100

                        L200 ->
                            Tw.to_green_200

                        L300 ->
                            Tw.to_green_300

                        L400 ->
                            Tw.to_green_400

                        L500 ->
                            Tw.to_green_500

                        L600 ->
                            Tw.to_green_600

                        L700 ->
                            Tw.to_green_700

                        L800 ->
                            Tw.to_green_800

                        L900 ->
                            Tw.to_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.to_indigo_50

                        L100 ->
                            Tw.to_indigo_100

                        L200 ->
                            Tw.to_indigo_200

                        L300 ->
                            Tw.to_indigo_300

                        L400 ->
                            Tw.to_indigo_400

                        L500 ->
                            Tw.to_indigo_500

                        L600 ->
                            Tw.to_indigo_600

                        L700 ->
                            Tw.to_indigo_700

                        L800 ->
                            Tw.to_indigo_800

                        L900 ->
                            Tw.to_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.to_pink_50

                        L100 ->
                            Tw.to_pink_100

                        L200 ->
                            Tw.to_pink_200

                        L300 ->
                            Tw.to_pink_300

                        L400 ->
                            Tw.to_pink_400

                        L500 ->
                            Tw.to_pink_500

                        L600 ->
                            Tw.to_pink_600

                        L700 ->
                            Tw.to_pink_700

                        L800 ->
                            Tw.to_pink_800

                        L900 ->
                            Tw.to_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.to_purple_50

                        L100 ->
                            Tw.to_purple_100

                        L200 ->
                            Tw.to_purple_200

                        L300 ->
                            Tw.to_purple_300

                        L400 ->
                            Tw.to_purple_400

                        L500 ->
                            Tw.to_purple_500

                        L600 ->
                            Tw.to_purple_600

                        L700 ->
                            Tw.to_purple_700

                        L800 ->
                            Tw.to_purple_800

                        L900 ->
                            Tw.to_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.to_red_50

                        L100 ->
                            Tw.to_red_100

                        L200 ->
                            Tw.to_red_200

                        L300 ->
                            Tw.to_red_300

                        L400 ->
                            Tw.to_red_400

                        L500 ->
                            Tw.to_red_500

                        L600 ->
                            Tw.to_red_600

                        L700 ->
                            Tw.to_red_700

                        L800 ->
                            Tw.to_red_800

                        L900 ->
                            Tw.to_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.to_yellow_50

                        L100 ->
                            Tw.to_yellow_100

                        L200 ->
                            Tw.to_yellow_200

                        L300 ->
                            Tw.to_yellow_300

                        L400 ->
                            Tw.to_yellow_400

                        L500 ->
                            Tw.to_yellow_500

                        L600 ->
                            Tw.to_yellow_600

                        L700 ->
                            Tw.to_yellow_700

                        L800 ->
                            Tw.to_yellow_800

                        L900 ->
                            Tw.to_yellow_900

                Black ->
                    Tw.to_black

                White ->
                    Tw.to_white

                Current ->
                    Tw.to_current

                Transparent ->
                    Tw.to_transparent

        Via ->
            case color of
                Blue ->
                    case level of
                        L50 ->
                            Tw.via_blue_50

                        L100 ->
                            Tw.via_blue_100

                        L200 ->
                            Tw.via_blue_200

                        L300 ->
                            Tw.via_blue_300

                        L400 ->
                            Tw.via_blue_400

                        L500 ->
                            Tw.via_blue_500

                        L600 ->
                            Tw.via_blue_600

                        L700 ->
                            Tw.via_blue_700

                        L800 ->
                            Tw.via_blue_800

                        L900 ->
                            Tw.via_blue_900

                Gray ->
                    case level of
                        L50 ->
                            Tw.via_gray_50

                        L100 ->
                            Tw.via_gray_100

                        L200 ->
                            Tw.via_gray_200

                        L300 ->
                            Tw.via_gray_300

                        L400 ->
                            Tw.via_gray_400

                        L500 ->
                            Tw.via_gray_500

                        L600 ->
                            Tw.via_gray_600

                        L700 ->
                            Tw.via_gray_700

                        L800 ->
                            Tw.via_gray_800

                        L900 ->
                            Tw.via_gray_900

                Green ->
                    case level of
                        L50 ->
                            Tw.via_green_50

                        L100 ->
                            Tw.via_green_100

                        L200 ->
                            Tw.via_green_200

                        L300 ->
                            Tw.via_green_300

                        L400 ->
                            Tw.via_green_400

                        L500 ->
                            Tw.via_green_500

                        L600 ->
                            Tw.via_green_600

                        L700 ->
                            Tw.via_green_700

                        L800 ->
                            Tw.via_green_800

                        L900 ->
                            Tw.via_green_900

                Indigo ->
                    case level of
                        L50 ->
                            Tw.via_indigo_50

                        L100 ->
                            Tw.via_indigo_100

                        L200 ->
                            Tw.via_indigo_200

                        L300 ->
                            Tw.via_indigo_300

                        L400 ->
                            Tw.via_indigo_400

                        L500 ->
                            Tw.via_indigo_500

                        L600 ->
                            Tw.via_indigo_600

                        L700 ->
                            Tw.via_indigo_700

                        L800 ->
                            Tw.via_indigo_800

                        L900 ->
                            Tw.via_indigo_900

                Pink ->
                    case level of
                        L50 ->
                            Tw.via_pink_50

                        L100 ->
                            Tw.via_pink_100

                        L200 ->
                            Tw.via_pink_200

                        L300 ->
                            Tw.via_pink_300

                        L400 ->
                            Tw.via_pink_400

                        L500 ->
                            Tw.via_pink_500

                        L600 ->
                            Tw.via_pink_600

                        L700 ->
                            Tw.via_pink_700

                        L800 ->
                            Tw.via_pink_800

                        L900 ->
                            Tw.via_pink_900

                Purple ->
                    case level of
                        L50 ->
                            Tw.via_purple_50

                        L100 ->
                            Tw.via_purple_100

                        L200 ->
                            Tw.via_purple_200

                        L300 ->
                            Tw.via_purple_300

                        L400 ->
                            Tw.via_purple_400

                        L500 ->
                            Tw.via_purple_500

                        L600 ->
                            Tw.via_purple_600

                        L700 ->
                            Tw.via_purple_700

                        L800 ->
                            Tw.via_purple_800

                        L900 ->
                            Tw.via_purple_900

                Red ->
                    case level of
                        L50 ->
                            Tw.via_red_50

                        L100 ->
                            Tw.via_red_100

                        L200 ->
                            Tw.via_red_200

                        L300 ->
                            Tw.via_red_300

                        L400 ->
                            Tw.via_red_400

                        L500 ->
                            Tw.via_red_500

                        L600 ->
                            Tw.via_red_600

                        L700 ->
                            Tw.via_red_700

                        L800 ->
                            Tw.via_red_800

                        L900 ->
                            Tw.via_red_900

                Yellow ->
                    case level of
                        L50 ->
                            Tw.via_yellow_50

                        L100 ->
                            Tw.via_yellow_100

                        L200 ->
                            Tw.via_yellow_200

                        L300 ->
                            Tw.via_yellow_300

                        L400 ->
                            Tw.via_yellow_400

                        L500 ->
                            Tw.via_yellow_500

                        L600 ->
                            Tw.via_yellow_600

                        L700 ->
                            Tw.via_yellow_700

                        L800 ->
                            Tw.via_yellow_800

                        L900 ->
                            Tw.via_yellow_900

                Black ->
                    Tw.via_black

                White ->
                    Tw.via_white

                Current ->
                    Tw.via_current

                Transparent ->
                    Tw.via_transparent
