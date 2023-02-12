module Models.Project.TableProps exposing (TableProps, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Tailwind as Tw exposing (Color)
import Models.Position as Position
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Size as Size


type alias TableProps =
    { id : TableId
    , position : Position.Grid
    , size : Size.Canvas
    , color : Color
    , columns : List ColumnPath
    , selected : Bool
    , collapsed : Bool
    , hiddenColumns : Bool
    }


encode : TableProps -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> TableId.encode )
        , ( "position", value.position |> Position.encodeGrid )
        , ( "size", value.size |> Size.encodeCanvas )
        , ( "color", value.color |> Tw.encodeColor )
        , ( "columns", value.columns |> Encode.list ColumnPath.encode )
        , ( "selected", value.selected |> Encode.withDefault Encode.bool False )
        , ( "collapsed", value.collapsed |> Encode.withDefault Encode.bool False )
        , ( "hiddenColumns", value.hiddenColumns |> Encode.withDefault Encode.bool False )
        ]


decode : Decode.Decoder TableProps
decode =
    Decode.map8 TableProps
        (Decode.field "id" TableId.decode)
        (Decode.field "position" Position.decodeGrid)
        (Decode.defaultField "size" Size.decodeCanvas Size.zeroCanvas)
        (Decode.field "color" Tw.decodeColor)
        (Decode.defaultField "columns" (Decode.list ColumnPath.decode) [])
        (Decode.defaultField "selected" Decode.bool False)
        (Decode.defaultField "collapsed" Decode.bool False)
        (Decode.defaultField "hiddenColumns" Decode.bool False)
