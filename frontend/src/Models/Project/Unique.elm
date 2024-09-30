module Models.Project.Unique exposing (Unique, decode, doc, docUnique, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.UniqueName as UniqueName exposing (UniqueName)


type alias Unique =
    { name : UniqueName
    , columns : Nel ColumnPath
    , definition : Maybe String
    }


encode : Unique -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> UniqueName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnPath.encode )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        ]


decode : Decode.Decoder Unique
decode =
    Decode.map3 Unique
        (Decode.field "name" UniqueName.decode)
        (Decode.field "columns" (Decode.nel ColumnPath.decode))
        (Decode.maybeField "definition" Decode.string)


docUnique : Unique
docUnique =
    { name = "Doc unique", columns = Nel.from (Nel.from "email"), definition = Nothing }


doc : List ColumnPathStr -> String -> Unique
doc columns name =
    columns |> Nel.fromList |> Maybe.map (Nel.map ColumnPath.fromString) |> Maybe.mapOrElse (\cols -> { name = name, columns = cols, definition = Nothing }) docUnique
