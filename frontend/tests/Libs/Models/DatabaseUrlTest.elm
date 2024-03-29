module Libs.Models.DatabaseUrlTest exposing (..)

import Expect
import Libs.Models.DatabaseUrl as DatabaseUrl
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Libs.Models.DatabaseUrl"
        [ describe "databaseName"
            [ test "bigquery" (\_ -> "bigquery://bigquery.googleapis.com/azimutt-experiments?key=local/key.json" |> DatabaseUrl.databaseName |> Expect.equal "azimutt-experiments")
            , test "postgres" (\_ -> "postgresql://postgres:postgres@localhost/azimutt_dev" |> DatabaseUrl.databaseName |> Expect.equal "azimutt_dev")
            ]
        ]
