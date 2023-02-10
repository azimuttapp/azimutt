module PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable, create, getColumn, getColumnRoot, inChecks, inIndexes, inPrimaryKey, inUniques, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Check exposing (Check)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.Project.Unique exposing (Unique)
import PagesComponents.Organization_.Project_.Models.ErdColumn as ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)


type alias ErdTable =
    { id : TableId
    , htmlId : HtmlId
    , label : String
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , columns : Dict ColumnName ErdColumn
    , primaryKey : Maybe PrimaryKey
    , uniques : List Unique
    , indexes : List Index
    , checks : List Check
    , comment : Maybe Comment
    , origins : List Origin
    }


create : SchemaName -> Dict CustomTypeId CustomType -> List ErdRelation -> Table -> ErdTable
create defaultSchema types tableRelations table =
    let
        relationsByRootColumn : Dict ColumnName (List ErdRelation)
        relationsByRootColumn =
            tableRelations
                |> List.foldr
                    (\rel dict ->
                        if rel.src.table == table.id && rel.ref.table == table.id then
                            dict
                                |> Dict.update (rel.src.column |> ColumnPath.rootName) (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                                |> Dict.update (rel.ref.column |> ColumnPath.rootName) (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else if rel.src.table == table.id then
                            dict |> Dict.update (rel.src.column |> ColumnPath.rootName) (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else if rel.ref.table == table.id then
                            dict |> Dict.update (rel.ref.column |> ColumnPath.rootName) (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else
                            dict
                    )
                    Dict.empty
    in
    { id = table.id
    , htmlId = table.id |> TableId.toHtmlId
    , label = table.id |> TableId.show defaultSchema
    , schema = table.schema
    , name = table.name
    , view = table.view
    , columns = table.columns |> Dict.map (\name -> ErdColumn.create defaultSchema types (relationsByRootColumn |> Dict.getOrElse name []) table (ColumnPath.fromString name))
    , primaryKey = table.primaryKey
    , uniques = table.uniques
    , indexes = table.indexes
    , checks = table.checks
    , comment = table.comment
    , origins = table.origins
    }


unpack : ErdTable -> Table
unpack table =
    { id = table.id
    , schema = table.schema
    , name = table.name
    , view = table.view
    , columns = table.columns |> Dict.map (\_ -> ErdColumn.unpack)
    , primaryKey = table.primaryKey
    , uniques = table.uniques
    , indexes = table.indexes
    , checks = table.checks
    , comment = table.comment
    , origins = table.origins
    }


getColumn : ColumnPath -> ErdTable -> Maybe ErdColumn
getColumn path table =
    table.columns
        |> Dict.get path.head
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> ErdColumn.getColumn next col) (Just col))


getColumnRoot : ColumnPath -> ErdTable -> Maybe ErdColumn
getColumnRoot path table =
    table.columns |> Dict.get path.head


inPrimaryKey : ErdTable -> ColumnPath -> Maybe PrimaryKey
inPrimaryKey table column =
    table.primaryKey |> Maybe.filter (\{ columns } -> columns |> Nel.toList |> hasColumn column)


inUniques : ErdTable -> ColumnPath -> List Unique
inUniques table column =
    table.uniques |> List.filter (\u -> u.columns |> Nel.toList |> hasColumn column)


inIndexes : ErdTable -> ColumnPath -> List Index
inIndexes table column =
    table.indexes |> List.filter (\i -> i.columns |> Nel.toList |> hasColumn column)


inChecks : ErdTable -> ColumnPath -> List Check
inChecks table column =
    table.checks |> List.filter (\i -> i.columns |> hasColumn column)


hasColumn : ColumnPath -> List ColumnPath -> Bool
hasColumn column columns =
    columns |> List.any (\c -> c == column)
