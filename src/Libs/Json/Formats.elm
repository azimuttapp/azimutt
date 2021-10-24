module Libs.Json.Formats exposing (decodeColor, decodeFileLineIndex, decodeFileModified, decodeFileName, decodeFileSize, decodeFileUrl, decodePosition, decodePosix, decodeSize, decodeZoomLevel, encodeColor, encodeFileLineIndex, encodeFileModified, encodeFileName, encodeFileSize, encodeFileUrl, encodePosition, encodePosix, encodeSize, encodeZoomLevel)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Encode as E
import Libs.Models exposing (Color, FileLineIndex, FileModified, FileName, FileSize, FileUrl, ZoomLevel)
import Libs.Position exposing (Position)
import Libs.Size exposing (Size)
import Time


encodePosition : Position -> Value
encodePosition value =
    E.object
        [ ( "left", value.left |> Encode.float )
        , ( "top", value.top |> Encode.float )
        ]


decodePosition : Decode.Decoder Position
decodePosition =
    Decode.map2 Position
        (Decode.field "left" Decode.float)
        (Decode.field "top" Decode.float)


encodeSize : Size -> Value
encodeSize value =
    E.object
        [ ( "width", value.width |> Encode.float )
        , ( "height", value.height |> Encode.float )
        ]


decodeSize : Decode.Decoder Size
decodeSize =
    Decode.map2 Size
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)


encodeFileName : FileName -> Value
encodeFileName value =
    Encode.string value


decodeFileName : Decode.Decoder FileName
decodeFileName =
    Decode.string


encodeFileUrl : FileUrl -> Value
encodeFileUrl value =
    Encode.string value


decodeFileUrl : Decode.Decoder FileUrl
decodeFileUrl =
    Decode.string


encodeFileSize : FileSize -> Value
encodeFileSize value =
    Encode.int value


decodeFileSize : Decode.Decoder FileSize
decodeFileSize =
    Decode.int


encodeFileLineIndex : FileLineIndex -> Value
encodeFileLineIndex value =
    Encode.int value


decodeFileLineIndex : Decode.Decoder FileLineIndex
decodeFileLineIndex =
    Decode.int


encodeFileModified : FileModified -> Value
encodeFileModified value =
    encodePosix value


decodeFileModified : Decode.Decoder FileModified
decodeFileModified =
    decodePosix


encodeZoomLevel : ZoomLevel -> Value
encodeZoomLevel value =
    Encode.float value


decodeZoomLevel : Decode.Decoder ZoomLevel
decodeZoomLevel =
    Decode.float


encodeColor : Color -> Value
encodeColor value =
    Encode.string value


decodeColor : Decode.Decoder Color
decodeColor =
    Decode.string


encodePosix : Time.Posix -> Value
encodePosix value =
    value |> Time.posixToMillis |> Encode.int


decodePosix : Decode.Decoder Time.Posix
decodePosix =
    Decode.int |> Decode.map Time.millisToPosix
