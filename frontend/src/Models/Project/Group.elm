module Models.Project.Group exposing (Group, decode, encode, init)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Tailwind as Tw exposing (Color)
import Models.Project.TableId as TableId exposing (TableId)


type alias Group =
    { name : String
    , tables : List TableId
    , color : Color
    , collapsed : Bool
    }


init : List TableId -> Group
init tables =
    { name = "New group"
    , tables = tables
    , color = Tw.indigo
    , collapsed = False
    }


encode : Group -> Value
encode value =
    Encode.notNullObject
        [ ( "name", value.name |> Encode.string )
        , ( "tables", value.tables |> Encode.list TableId.encode )
        , ( "color", value.color |> Tw.encodeColor )
        , ( "collapsed", value.collapsed |> Encode.withDefault Encode.bool False )
        ]


decode : Decode.Decoder Group
decode =
    Decode.map4 Group
        (Decode.field "name" Decode.string)
        (Decode.field "tables" (Decode.list TableId.decode))
        (Decode.field "color" Tw.decodeColor)
        (Decode.defaultField "collapsed" Decode.bool False)
