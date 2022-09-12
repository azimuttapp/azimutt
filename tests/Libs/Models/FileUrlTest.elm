module Libs.Models.FileUrlTest exposing (..)

import Expect
import Libs.Models.FileUrl as FileUrl
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Models.FileUrl"
        [ describe "filename"
            [ test "basic" (\_ -> "https://example.com/test.php" |> FileUrl.filename |> Expect.equal "test.php")
            , test "with query" (\_ -> "https://example.com/test.php?q=test" |> FileUrl.filename |> Expect.equal "test.php")
            , test "with hash" (\_ -> "https://example.com/test.php#section" |> FileUrl.filename |> Expect.equal "test.php")
            , test "with query and hash" (\_ -> "https://example.com/test.php?q=test#section" |> FileUrl.filename |> Expect.equal "test.php")
            , test "with folder" (\_ -> "https://example.com/app/test.php" |> FileUrl.filename |> Expect.equal "test.php")
            , test "with trailing /" (\_ -> "https://example.com/test.php/" |> FileUrl.filename |> Expect.equal "test.php")
            , test "empty" (\_ -> "https://example.com" |> FileUrl.filename |> Expect.equal "example.com")
            ]
        ]
