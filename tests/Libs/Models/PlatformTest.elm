module Libs.Models.PlatformTest exposing (..)

import Expect
import Libs.Models.Platform as Platform exposing (Platform(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Models.Platform"
        [ test "fromString / toString" (\_ -> [ PC, Mac ] |> (\all -> all |> List.map Platform.toString |> List.map Platform.fromString |> Expect.equal all))
        ]
