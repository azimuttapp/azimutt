module PagesComponents.Projects.Id_.Models.Erd exposing (Erd, ErdColumn, ErdColumnProps, ErdColumnRef, ErdRelation, ErdRelationProps, ErdTable, ErdTableProps, fromProject, getColumn, getColumnProps, setErdTablePropsColor, setErdTablePropsHighlightedColumns, setErdTablePropsPosition, setErdTablePropsSelected, setErdTablePropsSize, toProject)

import Dict exposing (Dict)
import Libs.Dict as D
import Libs.List as L
import Libs.Maybe as M
import Libs.Models.Color exposing (Color)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel
import Models.Project exposing (Project)
import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.Check exposing (Check)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.Layout exposing (Layout)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.ProjectId exposing (ProjectId)
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId exposing (RelationId)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.Project.TableProps exposing (TableProps)
import Models.Project.Unique exposing (Unique)
import Models.Project.UniqueName exposing (UniqueName)
import Set exposing (Set)
import Time


type alias Erd =
    { projectId : ProjectId
    , projectName : ProjectName
    , projectCreatedAt : Time.Posix
    , projectUpdatedAt : Time.Posix
    , canvas : CanvasProps
    , tables : Dict TableId ErdTable
    , relations : List ErdRelation
    , tableProps : Dict TableId ErdTableProps
    , shownTables : List TableId
    , usedLayout : Maybe LayoutName
    , layouts : Dict LayoutName Layout
    , sources : List Source
    , settings : ProjectSettings
    }


fromProject : Project -> Erd
fromProject project =
    let
        layoutProps : List TableProps
        layoutProps =
            project.layout.tables ++ project.layout.hiddenTables

        relationsByTable : Dict TableId (List Relation)
        relationsByTable =
            project.relations
                |> List.foldr
                    (\rel dict ->
                        if rel.src.table == rel.ref.table then
                            dict |> Dict.update rel.src.table (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else
                            dict
                                |> Dict.update rel.src.table (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                                |> Dict.update rel.ref.table (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                    )
                    Dict.empty
    in
    { projectId = project.id
    , projectName = project.name
    , projectCreatedAt = project.createdAt
    , projectUpdatedAt = project.updatedAt
    , canvas = project.layout.canvas
    , tables = project.tables |> Dict.map (\id -> buildErdTable project.tables (relationsByTable |> D.getOrElse id []))
    , relations = project.relations |> List.map (buildErdRelation project.tables)
    , tableProps = layoutProps |> List.map (\p -> ( p.id, buildErdTableProps (relationsByTable |> D.getOrElse p.id []) project.layout.tables p )) |> Dict.fromList
    , shownTables = project.layout.tables |> List.map .id
    , usedLayout = project.usedLayout
    , layouts = project.layouts
    , sources = project.sources
    , settings = project.settings
    }


toProject : Erd -> Project
toProject erd =
    let
        ( shownTables, hiddenTables ) =
            erd.tableProps |> Dict.keys |> List.partition (\id -> erd.shownTables |> List.member id)
    in
    { id = erd.projectId
    , name = erd.projectName
    , sources = erd.sources
    , tables = erd.tables |> Dict.map (\_ -> buildTable)
    , relations = erd.relations |> List.map buildRelation
    , layout =
        { canvas = erd.canvas
        , tables = shownTables |> List.filterMap (buildTableProps erd.tableProps)
        , hiddenTables = hiddenTables |> List.filterMap (buildTableProps erd.tableProps)
        , createdAt = Time.millisToPosix 0
        , updatedAt = Time.millisToPosix 0
        }
    , usedLayout = erd.usedLayout
    , layouts = erd.layouts
    , settings = erd.settings
    , createdAt = erd.projectCreatedAt
    , updatedAt = erd.projectUpdatedAt
    }


getColumn : TableId -> ColumnName -> Erd -> Maybe ErdColumn
getColumn table column erd =
    erd.tables |> Dict.get table |> Maybe.andThen (\t -> t.columns |> Ned.get column)


getColumnProps : TableId -> ColumnName -> Erd -> Maybe ErdColumnProps
getColumnProps table column erd =
    erd.tableProps |> Dict.get table |> Maybe.andThen (\t -> t.columnProps |> Dict.get column)


type alias ErdTable =
    { id : TableId
    , htmlId : HtmlId
    , label : String
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , columns : Ned ColumnName ErdColumn
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , origins : List Origin
    }


buildErdTable : Dict TableId Table -> List Relation -> Table -> ErdTable
buildErdTable tables tableRelations table =
    let
        relationsByColumn : Dict ColumnName (List Relation)
        relationsByColumn =
            tableRelations
                |> List.foldr
                    (\rel dict ->
                        if rel.src.table == table.id && rel.ref.table == table.id then
                            dict
                                |> Dict.update rel.src.column (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                                |> Dict.update rel.ref.column (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else if rel.src.table == table.id then
                            dict |> Dict.update rel.src.column (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else if rel.ref.table == table.id then
                            dict |> Dict.update rel.ref.column (M.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else
                            dict
                    )
                    Dict.empty
    in
    { id = table.id
    , htmlId = table.id |> TableId.toHtmlId
    , label = table.id |> TableId.show
    , schema = table.schema
    , name = table.name
    , view = table.view
    , columns = table.columns |> Ned.map (\name -> buildErdColumn tables (relationsByColumn |> D.getOrElse name []) table)
    , primaryKey = table.primaryKey
    , uniques = table.uniques
    , indexes = table.indexes
    , checks = table.checks
    , comment = table.comment
    , origins = table.origins
    }


buildTable : ErdTable -> Table
buildTable table =
    { id = table.id
    , schema = table.schema
    , name = table.name
    , view = table.view
    , columns = table.columns |> Ned.map (\_ -> buildColumn)
    , primaryKey = table.primaryKey
    , uniques = table.uniques
    , indexes = table.indexes
    , checks = table.checks
    , comment = table.comment
    , origins = table.origins
    }


type alias ErdColumn =
    { sqlIndex : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe Comment
    , isPrimaryKey : Bool
    , inRelations : List ErdColumnRef
    , outRelations : List ErdColumnRef
    , uniques : List UniqueName
    , indexes : List IndexName
    , checks : List CheckName
    , origins : List Origin
    }


buildErdColumn : Dict TableId Table -> List Relation -> Table -> Column -> ErdColumn
buildErdColumn tables columnRelations table column =
    { sqlIndex = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment
    , isPrimaryKey = column.name |> Table.inPrimaryKey table |> M.isJust
    , inRelations = columnRelations |> List.filter (\r -> r.ref.table == table.id && r.ref.column == column.name) |> List.map .src |> List.map (buildErdColumnRelation tables)
    , outRelations = columnRelations |> List.filter (\r -> r.src.table == table.id && r.src.column == column.name) |> List.map .ref |> List.map (buildErdColumnRelation tables)
    , uniques = table.uniques |> List.filter (\u -> u.columns |> Nel.has column.name) |> List.map (\u -> u.name)
    , indexes = table.indexes |> List.filter (\i -> i.columns |> Nel.has column.name) |> List.map (\i -> i.name)
    , checks = table.checks |> List.filter (\c -> c.columns |> L.has column.name) |> List.map (\c -> c.name)
    , origins = table.origins
    }


buildColumn : ErdColumn -> Column
buildColumn column =
    { index = column.sqlIndex
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment
    , origins = column.origins
    }


type alias ErdRelation =
    { id : RelationId
    , name : RelationName
    , src : ErdColumnRef
    , ref : ErdColumnRef
    , origins : List Origin
    }


buildErdRelation : Dict TableId Table -> Relation -> ErdRelation
buildErdRelation tables relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src |> buildErdColumnRelation tables
    , ref = relation.ref |> buildErdColumnRelation tables
    , origins = relation.origins
    }


buildRelation : ErdRelation -> Relation
buildRelation relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src |> buildColumnRef
    , ref = relation.ref |> buildColumnRef
    , origins = relation.origins
    }


type alias ErdColumnRef =
    { table : TableId
    , column : ColumnName
    , nullable : Bool
    }


buildErdColumnRelation : Dict TableId Table -> ColumnRef -> ErdColumnRef
buildErdColumnRelation tables ref =
    { table = ref.table
    , column = ref.column
    , nullable = tables |> Dict.get ref.table |> Maybe.andThen (.columns >> Ned.get ref.column) |> M.mapOrElse .nullable False
    }


buildColumnRef : ErdColumnRef -> ColumnRef
buildColumnRef ref =
    { table = ref.table, column = ref.column }


type alias ErdTableProps =
    { id : TableId
    , position : Position
    , size : Size
    , isHover : Bool
    , color : Color
    , shownColumns : List ColumnName
    , highlightedColumns : Set ColumnName
    , columnProps : Dict ColumnName ErdColumnProps
    , selected : Bool
    , hiddenColumns : Bool
    , relatedTables : Dict TableId ErdRelationProps
    }


buildErdTableProps : List Relation -> List TableProps -> TableProps -> ErdTableProps
buildErdTableProps tableRelations shownTables props =
    { id = props.id
    , position = props.position
    , size = props.size
    , isHover = False
    , color = props.color
    , shownColumns = props.columns
    , highlightedColumns = Set.empty
    , columnProps = props.columns |> buildErdColumnProps props.color props.size props.position props.selected Set.empty
    , selected = props.selected
    , hiddenColumns = props.hiddenColumns
    , relatedTables =
        tableRelations
            |> List.filterMap
                (\r ->
                    if r.src.table == props.id then
                        Just ( r.ref.table, buildErdRelationProps shownTables r.ref.table )

                    else if r.ref.table == props.id then
                        Just ( r.src.table, buildErdRelationProps shownTables r.src.table )

                    else
                        Nothing
                )
            |> Dict.fromList
    }


buildTableProps : Dict TableId ErdTableProps -> TableId -> Maybe TableProps
buildTableProps props id =
    props
        |> Dict.get id
        |> Maybe.map
            (\prop ->
                { id = id
                , position = prop.position
                , size = prop.size
                , color = prop.color
                , columns = prop.shownColumns
                , selected = prop.selected
                , hiddenColumns = prop.hiddenColumns
                }
            )


setErdTablePropsPosition : Position -> ErdTableProps -> ErdTableProps
setErdTablePropsPosition position props =
    if props.position == position then
        props

    else
        { props | position = position, columnProps = props.columnProps |> Dict.map (\_ p -> { p | position = position }) }


setErdTablePropsSize : Size -> ErdTableProps -> ErdTableProps
setErdTablePropsSize size props =
    if props.size == size then
        props

    else
        { props | size = size, columnProps = props.columnProps |> Dict.map (\_ p -> { p | size = size }) }


setErdTablePropsColor : Color -> ErdTableProps -> ErdTableProps
setErdTablePropsColor color props =
    if props.color == color then
        props

    else
        { props | color = color, columnProps = props.columnProps |> Dict.map (\_ p -> { p | color = color }) }


setErdTablePropsHighlightedColumns : Set ColumnName -> ErdTableProps -> ErdTableProps
setErdTablePropsHighlightedColumns highlightedColumns props =
    if props.highlightedColumns == highlightedColumns then
        props

    else
        { props
            | highlightedColumns = highlightedColumns
            , columnProps =
                props.columnProps
                    |> Dict.map
                        (\c p ->
                            (highlightedColumns |> Set.member c)
                                |> (\highlighted ->
                                        if p.highlighted == highlighted then
                                            p

                                        else
                                            { p | highlighted = highlighted }
                                   )
                        )
        }


setErdTablePropsSelected : Bool -> ErdTableProps -> ErdTableProps
setErdTablePropsSelected selected props =
    if props.selected == selected then
        props

    else
        { props | selected = selected, columnProps = props.columnProps |> Dict.map (\_ p -> { p | selected = selected }) }


type alias ErdColumnProps =
    { column : ColumnName
    , index : Int
    , position : Position
    , size : Size
    , color : Color
    , highlighted : Bool
    , selected : Bool
    }


buildErdColumnProps : Color -> Size -> Position -> Bool -> Set ColumnName -> List ColumnName -> Dict ColumnName ErdColumnProps
buildErdColumnProps color size position selected highlightedColumns columns =
    columns
        |> List.indexedMap
            (\i c ->
                ( c
                , { column = c
                  , index = i
                  , position = position
                  , size = size
                  , color = color
                  , highlighted = highlightedColumns |> Set.member c
                  , selected = selected
                  }
                )
            )
        |> Dict.fromList


type alias ErdRelationProps =
    { shown : Bool }


buildErdRelationProps : List TableProps -> TableId -> ErdRelationProps
buildErdRelationProps shownTables id =
    { shown = shownTables |> List.any (\t -> t.id == id) }
