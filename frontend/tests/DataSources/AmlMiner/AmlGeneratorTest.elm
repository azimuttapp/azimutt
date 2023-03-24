module DataSources.AmlMiner.AmlGeneratorTest exposing (..)

import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import Dict exposing (Dict)
import Expect
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "AmlGenerator"
        [ describe "generate"
            [ test "empty" (\_ -> emptySource |> AmlGenerator.generate |> Expect.equal "")
            ]
        ]


emptySource : { tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType }
emptySource =
    { tables = Dict.empty, relations = [], types = Dict.empty }
