module Models.Project.TableProps exposing (TableProps, decode, encode)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodeColor, decodePosition, encodeColor, encodePosition)
import Libs.Models exposing (Color)
import Libs.Position exposing (Position)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.TableId as TableId exposing (TableId)


type alias TableProps =
    { id : TableId, position : Position, color : Color, columns : List ColumnName, selected : Bool }


encode : TableProps -> Value
encode value =
    E.object
        [ ( "id", value.id |> TableId.encode )
        , ( "position", value.position |> encodePosition )
        , ( "color", value.color |> encodeColor )
        , ( "columns", value.columns |> E.withDefault (Encode.list ColumnName.encode) [] )
        , ( "selected", value.selected |> E.withDefault Encode.bool False )
        ]


decode : Decode.Decoder TableProps
decode =
    Decode.map5 TableProps
        (Decode.field "id" TableId.decode)
        (Decode.field "position" decodePosition)
        (Decode.field "color" decodeColor)
        (D.defaultField "columns" (Decode.list ColumnName.decode) [])
        (D.defaultField "selected" Decode.bool False)
