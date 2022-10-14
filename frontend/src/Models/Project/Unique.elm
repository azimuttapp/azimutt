module Models.Project.Unique exposing (Unique, clearOrigins, decode, encode, merge)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.UniqueName as UniqueName exposing (UniqueName)
import Services.Lenses exposing (setOrigins)


type alias Unique =
    { name : UniqueName
    , columns : Nel ColumnName
    , definition : Maybe String
    , origins : List Origin
    }


merge : Unique -> Unique -> Unique
merge u1 u2 =
    { name = u1.name
    , columns = Nel.merge identity ColumnName.merge u1.columns u2.columns
    , definition = u1.definition
    , origins = u1.origins ++ u2.origins
    }


clearOrigins : Unique -> Unique
clearOrigins unique =
    unique |> setOrigins []


encode : Unique -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> UniqueName.encode )
        , ( "columns", value.columns |> Encode.nel ColumnName.encode )
        , ( "definition", value.definition |> Encode.maybe Encode.string )
        , ( "origins", value.origins |> Encode.list Origin.encode )
        ]


decode : Decode.Decoder Unique
decode =
    Decode.map4 Unique
        (Decode.field "name" UniqueName.decode)
        (Decode.field "columns" (Decode.nel ColumnName.decode))
        (Decode.maybeField "definition" Decode.string)
        (Decode.defaultField "origins" (Decode.list Origin.decode) [])
