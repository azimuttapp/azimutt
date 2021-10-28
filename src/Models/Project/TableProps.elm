module Models.Project.TableProps exposing (TableProps, decode, encode, init)

import Conf exposing (conf)
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.List as L
import Libs.Models.Color as Color exposing (Color)
import Libs.Models.Position as Position exposing (Position)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.String as S
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)


type alias TableProps =
    { id : TableId, position : Position, color : Color, columns : List ColumnName, selected : Bool }


init : Table -> TableProps
init table =
    { id = table.id
    , position = Position 0 0
    , color = computeColor table.id
    , selected = False
    , columns = table.columns |> Ned.values |> Nel.toList |> List.sortBy .index |> List.map .name
    }


computeColor : TableId -> Color
computeColor ( _, table ) =
    S.wordSplit table
        |> List.head
        |> Maybe.map S.hashCode
        |> Maybe.map (modBy (List.length conf.colors))
        |> Maybe.andThen (\index -> conf.colors |> L.get index)
        |> Maybe.withDefault conf.default.color


encode : TableProps -> Value
encode value =
    E.object
        [ ( "id", value.id |> TableId.encode )
        , ( "position", value.position |> Position.encode )
        , ( "color", value.color |> Color.encode )
        , ( "columns", value.columns |> E.withDefault (Encode.list ColumnName.encode) [] )
        , ( "selected", value.selected |> E.withDefault Encode.bool False )
        ]


decode : Decode.Decoder TableProps
decode =
    Decode.map5 TableProps
        (Decode.field "id" TableId.decode)
        (Decode.field "position" Position.decode)
        (Decode.field "color" Color.decode)
        (D.defaultField "columns" (Decode.list ColumnName.decode) [])
        (D.defaultField "selected" Decode.bool False)
