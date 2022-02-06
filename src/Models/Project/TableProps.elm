module Models.Project.TableProps exposing (TableProps, area, decode, encode, init)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.Area exposing (Area)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.List as L
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.String as S
import Libs.Tailwind as Tw exposing (Color)
import Models.ColumnOrder as ColumnOrder
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)


type alias TableProps =
    { id : TableId
    , position : Position
    , size : Size
    , color : Color
    , columns : List ColumnName
    , selected : Bool
    , hiddenColumns : Bool
    }


init : ProjectSettings -> List Relation -> Table -> TableProps
init settings relations table =
    { id = table.id
    , position = Position.zero
    , size = Size.zero
    , color = computeColor table.id
    , columns = table.columns |> Ned.values |> Nel.toList |> List.map .name |> computeColumns settings relations table
    , selected = False
    , hiddenColumns = False
    }


computeColumns : ProjectSettings -> List Relation -> Table -> List ColumnName -> List ColumnName
computeColumns settings relations table columns =
    let
        isColumnHidden : ColumnName -> Bool
        isColumnHidden =
            settings.hiddenColumns |> ProjectSettings.isColumnHidden

        tableRelations : List Relation
        tableRelations =
            relations |> Relation.withTableSrc table.id
    in
    columns
        |> List.filterMap (\c -> table.columns |> Ned.get c)
        |> L.filterNot (\c -> isColumnHidden c.name)
        |> ColumnOrder.sortBy settings.columnOrder table tableRelations
        |> List.map .name


computeColor : TableId -> Color
computeColor ( _, table ) =
    S.wordSplit table
        |> List.head
        |> Maybe.map S.hashCode
        |> Maybe.map (modBy (List.length Tw.list))
        |> Maybe.andThen (\index -> Tw.list |> L.get index)
        |> Maybe.withDefault Tw.default


area : TableProps -> Area
area props =
    { position = props.position, size = props.size }


encode : TableProps -> Value
encode value =
    E.notNullObject
        [ ( "id", value.id |> TableId.encode )
        , ( "position", value.position |> Position.encode )

        -- , ( "size", value.size |> Size.encode ) do not store size, it should be re-computed
        , ( "color", value.color |> Tw.encodeColor )
        , ( "columns", value.columns |> E.withDefault (Encode.list ColumnName.encode) [] )
        , ( "selected", value.selected |> E.withDefault Encode.bool False )
        , ( "hiddenColumns", value.hiddenColumns |> E.withDefault Encode.bool False )
        ]


decode : Decode.Decoder TableProps
decode =
    Decode.map7 TableProps
        (Decode.field "id" TableId.decode)
        (Decode.field "position" Position.decode)
        (D.defaultField "size" Size.decode Size.zero)
        (Decode.field "color" Tw.decodeColor)
        (D.defaultField "columns" (Decode.list ColumnName.decode) [])
        (D.defaultField "selected" Decode.bool False)
        (D.defaultField "hiddenColumns" Decode.bool False)
