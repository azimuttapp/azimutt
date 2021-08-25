module Libs.Json.FormatsTest exposing (..)

import Libs.Json.Formats exposing (decodeColor, decodePosition, decodePosix, decodeSize, decodeZoomLevel, encodeColor, encodePosition, encodePosix, encodeSize, encodeZoomLevel)
import Test exposing (Test, describe)
import TestHelpers.Fuzzers as Fuzzers
import TestHelpers.JsonTest exposing (jsonFuzz)


suite : Test
suite =
    describe "Formats"
        [ jsonFuzz "Position" Fuzzers.position encodePosition decodePosition
        , jsonFuzz "Size" Fuzzers.size encodeSize decodeSize
        , jsonFuzz "ZoomLevel" Fuzzers.zoomLevel encodeZoomLevel decodeZoomLevel
        , jsonFuzz "Color" Fuzzers.color encodeColor decodeColor
        , jsonFuzz "Posix" Fuzzers.posix encodePosix decodePosix
        ]
