module Libs.Color exposing (fromHex)

import Bitwise exposing (shiftLeftBy)
import Color exposing (Color)



-- taken from https://github.com/avh4/elm-color/blob/1.0.0/src/Color.elm#L351 as it's not public :/


fromHex : String -> Maybe Color
fromHex hexString =
    case String.toList hexString of
        [ '#', r, g, b ] ->
            fromHex8 ( r, r ) ( g, g ) ( b, b ) ( 'f', 'f' )

        [ r, g, b ] ->
            fromHex8 ( r, r ) ( g, g ) ( b, b ) ( 'f', 'f' )

        [ '#', r, g, b, a ] ->
            fromHex8 ( r, r ) ( g, g ) ( b, b ) ( a, a )

        [ r, g, b, a ] ->
            fromHex8 ( r, r ) ( g, g ) ( b, b ) ( a, a )

        [ '#', r1, r2, g1, g2, b1, b2 ] ->
            fromHex8 ( r1, r2 ) ( g1, g2 ) ( b1, b2 ) ( 'f', 'f' )

        [ r1, r2, g1, g2, b1, b2 ] ->
            fromHex8 ( r1, r2 ) ( g1, g2 ) ( b1, b2 ) ( 'f', 'f' )

        [ '#', r1, r2, g1, g2, b1, b2, a1, a2 ] ->
            fromHex8 ( r1, r2 ) ( g1, g2 ) ( b1, b2 ) ( a1, a2 )

        [ r1, r2, g1, g2, b1, b2, a1, a2 ] ->
            fromHex8 ( r1, r2 ) ( g1, g2 ) ( b1, b2 ) ( a1, a2 )

        _ ->
            Nothing


fromHex8 : ( Char, Char ) -> ( Char, Char ) -> ( Char, Char ) -> ( Char, Char ) -> Maybe Color
fromHex8 ( r1, r2 ) ( g1, g2 ) ( b1, b2 ) ( a1, a2 ) =
    Maybe.map4 (\r g b a -> Color.fromRgba { red = toFloat r / 255, green = toFloat g / 255, blue = toFloat b / 255, alpha = toFloat a / 255 })
        (hex2ToInt r1 r2)
        (hex2ToInt g1 g2)
        (hex2ToInt b1 b2)
        (hex2ToInt a1 a2)


hex2ToInt : Char -> Char -> Maybe Int
hex2ToInt c1 c2 =
    Maybe.map2 (\v1 v2 -> shiftLeftBy 4 v1 + v2) (hexToInt c1) (hexToInt c2)


hexToInt : Char -> Maybe Int
hexToInt char =
    case Char.toLower char of
        '0' ->
            Just 0

        '1' ->
            Just 1

        '2' ->
            Just 2

        '3' ->
            Just 3

        '4' ->
            Just 4

        '5' ->
            Just 5

        '6' ->
            Just 6

        '7' ->
            Just 7

        '8' ->
            Just 8

        '9' ->
            Just 9

        'a' ->
            Just 10

        'b' ->
            Just 11

        'c' ->
            Just 12

        'd' ->
            Just 13

        'e' ->
            Just 14

        'f' ->
            Just 15

        _ ->
            Nothing
