module Libs.Json.FormatsTest exposing (..)

import Libs.Models.Position as Position
import Libs.Models.Size as Size
import Libs.Models.ZoomLevel as ZoomLevel
import Libs.Tailwind as Tw
import Libs.Time as Time
import Test exposing (Test, describe)
import TestHelpers.Fuzzers as Fuzzers
import TestHelpers.Helpers exposing (fuzzSerde)


suite : Test
suite =
    describe "Formats"
        [ fuzzSerde "Position" Position.encode Position.decode Fuzzers.position
        , fuzzSerde "Size" Size.encode Size.decode Fuzzers.size
        , fuzzSerde "ZoomLevel" ZoomLevel.encode ZoomLevel.decode Fuzzers.zoomLevel
        , fuzzSerde "Color" Tw.encodeColor Tw.decodeColor Fuzzers.color
        , fuzzSerde "Posix" Time.encode Time.decode Fuzzers.posix
        ]
