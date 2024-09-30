module DataSources.AmlMiner.AmlGeneratorTest exposing (..)

import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import Expect
import Models.Project.ColumnRef as ColumnRef
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "AmlGenerator"
        [ describe "relationStandalone"
            [ test "basic" (\_ -> AmlGenerator.relationStandalone (ColumnRef.fromString "posts.author") (ColumnRef.fromString "users.id") |> Expect.equal "rel posts(author) -> users(id)") ]
        ]
