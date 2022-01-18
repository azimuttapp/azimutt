module PagesComponents.Projects.Id_.Models.Erd exposing (Erd, ErdColumn, ErdColumnRelation, ErdRelation, ErdRelationProps, ErdTable, ErdTableProps, fromProject, toProject)

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
    , props : Dict TableId ErdTableProps
    , shownTables : List TableId
    , relations : List ErdRelation
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
    , props = layoutProps |> List.map (\p -> ( p.id, buildErdTableProps (relationsByTable |> D.getOrElse p.id []) project.layout.tables p )) |> Dict.fromList
    , shownTables = project.layout.tables |> List.map .id
    , relations = project.relations |> List.map buildErdRelation
    , usedLayout = project.usedLayout
    , layouts = project.layouts
    , sources = project.sources
    , settings = project.settings
    }


toProject : Erd -> Project
toProject erd =
    let
        ( shownTables, hiddenTables ) =
            erd.props |> Dict.keys |> List.partition (\id -> erd.shownTables |> List.member id)
    in
    { id = erd.projectId
    , name = erd.projectName
    , sources = erd.sources
    , tables = erd.tables |> Dict.map (\_ -> buildTable)
    , relations = erd.relations |> List.map buildRelation
    , layout =
        { canvas = erd.canvas
        , tables = shownTables |> List.filterMap (buildTableProps erd.props)
        , hiddenTables = hiddenTables |> List.filterMap (buildTableProps erd.props)
        , createdAt = Time.millisToPosix 0
        , updatedAt = Time.millisToPosix 0
        }
    , usedLayout = erd.usedLayout
    , layouts = erd.layouts
    , settings = erd.settings
    , createdAt = erd.projectCreatedAt
    , updatedAt = erd.projectUpdatedAt
    }


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
    , inRelations : List ErdColumnRelation
    , outRelations : List ErdColumnRelation
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


type alias ErdColumnRelation =
    { ref : ColumnRef
    , refNullable : Bool
    }


buildErdColumnRelation : Dict TableId Table -> ColumnRef -> ErdColumnRelation
buildErdColumnRelation tables ref =
    { ref = ref
    , refNullable = tables |> Dict.get ref.table |> Maybe.andThen (.columns >> Ned.get ref.column) |> M.mapOrElse .nullable False
    }


type alias ErdRelation =
    { id : RelationId
    , name : RelationName
    , src : ColumnRef
    , ref : ColumnRef
    , origins : List Origin
    }


buildErdRelation : Relation -> ErdRelation
buildErdRelation relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src
    , ref = relation.ref
    , origins = relation.origins
    }


buildRelation : ErdRelation -> Relation
buildRelation relation =
    { id = relation.id
    , name = relation.name
    , src = relation.src
    , ref = relation.ref
    , origins = relation.origins
    }


type alias ErdTableProps =
    { size : Size
    , position : Position
    , isHover : Bool
    , color : Color
    , columns : List ColumnName
    , hoverColumns : Set ColumnName
    , selected : Bool
    , hiddenColumns : Bool
    , relatedTables : Dict TableId ErdRelationProps
    }


buildErdTableProps : List Relation -> List TableProps -> TableProps -> ErdTableProps
buildErdTableProps tableRelations shownTables props =
    { size = props.size
    , position = props.position
    , isHover = False
    , color = props.color
    , columns = props.columns
    , hoverColumns = Set.empty
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
                , columns = prop.columns
                , selected = prop.selected
                , hiddenColumns = prop.hiddenColumns
                }
            )


type alias ErdRelationProps =
    { shown : Bool }


buildErdRelationProps : List TableProps -> TableId -> ErdRelationProps
buildErdRelationProps shownTables id =
    { shown = shownTables |> List.any (\t -> t.id == id) }
