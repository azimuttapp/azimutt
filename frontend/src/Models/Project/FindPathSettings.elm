module Models.Project.FindPathSettings exposing (FindPathSettings, decode, encode, init)

import Conf
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Models.Project.ColumnName as ColumnName
import Models.Project.TableId as TableId


type alias FindPathSettings =
    { maxPathLength : Int
    , ignoredTables : String
    , ignoredColumns : String
    }


init : FindPathSettings
init =
    FindPathSettings 3 "" ""


encode : FindPathSettings -> FindPathSettings -> Value
encode default value =
    Encode.notNullObject
        [ ( "maxPathLength", value.maxPathLength |> Encode.withDefault Encode.int default.maxPathLength )
        , ( "ignoredTables", value.ignoredTables |> Encode.withDefault Encode.string default.ignoredTables )
        , ( "ignoredColumns", value.ignoredColumns |> Encode.withDefault Encode.string default.ignoredColumns )
        ]


decode : FindPathSettings -> Decode.Decoder FindPathSettings
decode default =
    Decode.map3 FindPathSettings
        (Decode.defaultField "maxPathLength" Decode.int default.maxPathLength)
        (Decode.defaultField "ignoredTables" decodeTables default.ignoredTables)
        (Decode.defaultField "ignoredColumns" decodeColumns default.ignoredColumns)


decodeTables : Decode.Decoder String
decodeTables =
    Decode.oneOf
        [ Decode.string

        -- needed for retro-compatibility
        , Decode.list (TableId.decodeWith Conf.schema.default) |> Decode.map (List.map (TableId.show Conf.schema.default) >> String.join ", ")
        ]


decodeColumns : Decode.Decoder String
decodeColumns =
    Decode.oneOf
        [ Decode.string

        -- needed for retro-compatibility
        , Decode.list ColumnName.decode |> Decode.map (String.join ", ")
        ]
