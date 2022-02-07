module Libs.Json.FormatsTest exposing (..)

import Libs.Models.Position as Position
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel as ZoomLevel
import Libs.Tailwind as Tw
import Libs.Time as Time
import Test exposing (Test, describe)
import TestHelpers.Fuzzers as Fuzzers
import TestHelpers.JsonTest exposing (jsonFuzz)


suite : Test
suite =
    describe "Formats"
        [ jsonFuzz "Position" Fuzzers.position Position.encode Position.decode
        , jsonFuzz "Size" Fuzzers.size Size.encode Size.decode
        , jsonFuzz "ZoomLevel" Fuzzers.zoomLevel ZoomLevel.encode ZoomLevel.decode
        , jsonFuzz "Color" Fuzzers.color Tw.encodeColor Tw.decodeColor
        , jsonFuzz "Posix" Fuzzers.posix Time.encode Time.decode
        ]
