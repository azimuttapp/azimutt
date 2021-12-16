module PagesComponents.Projects.Id_.Views.Erd exposing (Model, viewErd)

import Components.Organisms.Table as Table
import Dict exposing (Dict)
import Html.Styled exposing (Html, div, main_)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Keyed as Keyed
import Libs.Html.Styled.Attributes exposing (onPointerDown)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Theme exposing (Theme)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Tailwind.Utilities as Tu
import Models.Project exposing (Project)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.Projects.Id_.Models exposing (DragState, Msg(..))
import Tailwind.Utilities as Tw


type alias Model x =
    { x
        | openedDropdown : HtmlId
        , dragging : Maybe DragState
        , hoverTable : Maybe TableId
        , hoverColumn : Maybe ColumnRef
    }


viewErd : Theme -> Model x -> Project -> Html Msg
viewErd _ model project =
    main_ [ class "erd" ]
        [ div [ class "canvas" ]
            [ viewTables model project.tables project.layout.tables project.relations
            ]
        ]


viewTables : Model x -> Dict TableId Table -> List TableProps -> List Relation -> Html Msg
viewTables model tables layout relations =
    Keyed.node "div"
        [ class "tables" ]
        (layout
            |> List.reverse
            |> L.filterZip (\p -> tables |> Dict.get p.id)
            |> List.indexedMap (\i ( p, t ) -> ( TableId.toString t.id, viewTable model i t p (relations |> List.filter (\r -> r.src.table == t.id || r.ref.table == t.id)) ))
        )


viewTable : Model x -> Int -> Table -> TableProps -> List Relation -> Html Msg
viewTable model _ table props tableRelations =
    let
        tableId : HtmlId
        tableId =
            TableId.toHtmlId table.id

        position : Position
        position =
            props.position |> Position.add (model.dragging |> M.filter (\d -> d.id == tableId) |> M.mapOrElse (\d -> d.last |> Position.sub d.init) (Position 0 0))

        ( columns, hiddenColumns ) =
            table.columns
                |> Ned.values
                |> Nel.zipWith (\col -> tableRelations |> List.filter (isColumnRelation table col))
                |> Nel.map (\( col, rels ) -> buildColumn rels table col)
                |> Nel.partition (\col -> props.columns |> L.has col.name)
    in
    div [ onPointerDown (DragStart tableId), css [ Tw.absolute, Tw.transform, Tu.translate_x_y position.left position.top "px" ] ]
        [ Table.table
            { id = tableId
            , ref = { schema = table.schema, table = table.name }
            , label = TableId.show table.id
            , isView = table.view
            , columns = columns
            , hiddenColumns = hiddenColumns
            , state =
                { color = props.color
                , hover = model.hoverTable |> Maybe.map (\( schemaName, tableName ) -> { schema = schemaName, table = tableName })
                , hoverColumn = model.hoverColumn |> Maybe.map (\ref -> { schema = ref.table |> Tuple.first, table = ref.table |> Tuple.second, column = ref.column })
                , selected = props.selected
                , dragging = model.dragging |> M.filter (\d -> d.id == tableId) |> M.isJust
                , openedDropdown = model.openedDropdown
                }
            , actions =
                { toggleSettings = DropdownToggle
                , toggleHover = ToggleHoverTable table.id
                , toggleHoverColumn = \c -> ToggleHoverColumn { table = table.id, column = c }
                , toggleSelected = SelectTable table.id
                }
            }
        ]


buildColumn : List Relation -> Table -> Column -> Table.Column
buildColumn relations table column =
    { name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map .text
    , isPrimaryKey = column.name |> Table.inPrimaryKey table |> M.isJust
    , inRelations = relations |> List.filter (\r -> r.ref.table == table.id && r.ref.column == column.name) |> List.map buildColumnRef
    , outRelations = relations |> List.filter (\r -> r.src.table == table.id && r.src.column == column.name) |> List.map buildColumnRef
    , uniques = table.uniques |> List.filter (\u -> u.columns |> Nel.has column.name) |> List.map (\u -> { name = u.name })
    , indexes = table.indexes |> List.filter (\i -> i.columns |> Nel.has column.name) |> List.map (\i -> { name = i.name })
    , checks = table.checks |> List.filter (\c -> c.columns |> L.has column.name) |> List.map (\c -> { name = c.name })
    }


buildColumnRef : Relation -> Table.ColumnRef
buildColumnRef relation =
    { schema = relation.src.table |> Tuple.first, table = relation.src.table |> Tuple.second, column = relation.src.column }


isColumnRelation : Table -> Column -> Relation -> Bool
isColumnRelation table column relation =
    (relation.src.table == table.id && relation.src.column == column.name) || (relation.ref.table == table.id && relation.ref.column == column.name)
