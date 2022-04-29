module Models.Project.TableProps exposing (TableProps, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Tailwind as Tw exposing (Color)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.GridPosition as GridPosition
import Models.Project.TableId as TableId exposing (TableId)


type alias TableProps =
    { id : TableId
    , position : Position
    , size : Size
    , color : Color
    , columns : List ColumnName
    , selected : Bool
    , collapsed : Bool
    , hiddenColumns : Bool
    }


encode : TableProps -> Value
encode value =
    Encode.notNullObject
        [ ( "id", value.id |> TableId.encode )
        , ( "position", value.position |> GridPosition.encode )

        -- , ( "size", value.size |> Size.encode ) do not store size, it should be re-computed
        , ( "color", value.color |> Tw.encodeColor )
        , ( "columns", value.columns |> Encode.withDefault (Encode.list ColumnName.encode) [] )
        , ( "selected", value.selected |> Encode.withDefault Encode.bool False )
        , ( "collapsed", value.collapsed |> Encode.withDefault Encode.bool False )
        , ( "hiddenColumns", value.hiddenColumns |> Encode.withDefault Encode.bool False )
        ]


decode : Decode.Decoder TableProps
decode =
    Decode.map8 TableProps
        (Decode.field "id" TableId.decode)
        (Decode.field "position" GridPosition.decode)
        (Decode.defaultField "size" Size.decode Size.zero)
        (Decode.field "color" Tw.decodeColor)
        (Decode.defaultField "columns" (Decode.list ColumnName.decode) [])
        (Decode.defaultField "selected" Decode.bool False)
        (Decode.defaultField "collapsed" Decode.bool False)
        (Decode.defaultField "hiddenColumns" Decode.bool False)
