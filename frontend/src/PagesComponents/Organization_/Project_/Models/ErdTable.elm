module PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable, create, getColumnI, getColumnRoot, getTable, inChecks, inIndexes, inPrimaryKey, inUniques, ranking, unpack)

import Conf
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath, ColumnPathStr)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.SourceId exposing (SourceIdStr)
import Models.Project.Table exposing (Table)
import Models.Project.TableDbStats exposing (TableDbStats)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (TableWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdCheck as ErdCheck exposing (ErdCheck)
import PagesComponents.Organization_.Project_.Models.ErdColumn as ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdComment as ErdComment exposing (ErdComment)
import PagesComponents.Organization_.Project_.Models.ErdCustomType exposing (ErdCustomType)
import PagesComponents.Organization_.Project_.Models.ErdIndex as ErdIndex exposing (ErdIndex)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)
import PagesComponents.Organization_.Project_.Models.ErdPrimaryKey as ErdPrimaryKey exposing (ErdPrimaryKey)
import PagesComponents.Organization_.Project_.Models.ErdRelation exposing (ErdRelation)
import PagesComponents.Organization_.Project_.Models.ErdUnique as ErdUnique exposing (ErdUnique)
import PagesComponents.Organization_.Project_.Models.SuggestedRelation exposing (SuggestedRelation)


type alias ErdTable =
    { id : TableId
    , htmlId : HtmlId
    , label : String
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , definition : Maybe String
    , columns : Dict ColumnName ErdColumn
    , primaryKey : Maybe ErdPrimaryKey
    , uniques : List ErdUnique
    , indexes : List ErdIndex
    , checks : List ErdCheck
    , comment : Maybe ErdComment
    , stats : Dict SourceIdStr TableDbStats
    , origins : List ErdOrigin
    }


create : SchemaName -> Dict CustomTypeId ErdCustomType -> List ErdRelation -> Dict ColumnPathStr (List SuggestedRelation) -> TableWithOrigin -> ErdTable
create defaultSchema types tableRelations suggestedRelations table =
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
    , definition = table.definition
    , columns = table.columns |> Dict.map (\name -> ErdColumn.create defaultSchema types (relationsByRootColumn |> Dict.getOrElse name []) suggestedRelations table (ColumnPath.fromString name))
    , primaryKey = table.primaryKey |> Maybe.map ErdPrimaryKey.create
    , uniques = table.uniques |> List.map ErdUnique.create
    , indexes = table.indexes |> List.map ErdIndex.create
    , checks = table.checks |> List.map ErdCheck.create
    , comment = table.comment |> Maybe.map ErdComment.create
    , stats = table.stats
    , origins = table.origins
    }


unpack : ErdTable -> Table
unpack table =
    { id = table.id
    , schema = table.schema
    , name = table.name
    , view = table.view
    , definition = table.definition
    , columns = table.columns |> Dict.map (\_ -> ErdColumn.unpack)
    , primaryKey = table.primaryKey |> Maybe.map ErdPrimaryKey.unpack
    , uniques = table.uniques |> List.map ErdUnique.unpack
    , indexes = table.indexes |> List.map ErdIndex.unpack
    , checks = table.checks |> List.map ErdCheck.unpack
    , comment = table.comment |> Maybe.map ErdComment.unpack
    , stats = table.stats |> Dict.values |> List.head
    }


getTable : SchemaName -> TableId -> Dict TableId ErdTable -> Maybe ErdTable
getTable defaultSchema ( schema, table ) tables =
    case tables |> Dict.get ( schema, table ) of
        Just t ->
            Just t

        Nothing ->
            if schema == Conf.schema.empty then
                tables |> Dict.get ( defaultSchema, table )

            else
                Nothing


getColumnI : ColumnPath -> ErdTable -> Maybe ErdColumn
getColumnI path table =
    (table.columns |> Dict.get path.head)
        |> Maybe.orElse (table.columns |> Dict.find (\k _ -> String.toLower k == String.toLower path.head))
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> ErdColumn.getColumnI next col) (Just col))


getColumnRoot : ColumnPath -> ErdTable -> Maybe ErdColumn
getColumnRoot path table =
    table.columns |> Dict.get path.head


inPrimaryKey : ErdTable -> ColumnPath -> Maybe ErdPrimaryKey
inPrimaryKey table column =
    table.primaryKey |> Maybe.filter (\{ columns } -> columns |> Nel.toList |> hasColumn column)


inUniques : ErdTable -> ColumnPath -> List ErdUnique
inUniques table column =
    table.uniques |> List.filter (\u -> u.columns |> Nel.toList |> hasColumn column)


inIndexes : ErdTable -> ColumnPath -> List ErdIndex
inIndexes table column =
    table.indexes |> List.filter (\i -> i.columns |> Nel.toList |> hasColumn column)


inChecks : ErdTable -> ColumnPath -> List ErdCheck
inChecks table column =
    table.checks |> List.filter (\i -> i.columns |> hasColumn column)


hasColumn : ColumnPath -> List ColumnPath -> Bool
hasColumn column columns =
    columns |> List.any (\c -> c |> ColumnPath.startsWith column)


ranking : ErdTable -> Int
ranking table =
    -- basic computation if "table importance", using number of incoming relations as the main metric, then number of columns
    table.columns |> Dict.foldl (\_ c r -> r + 1 + (10 * (c.inRelations |> List.length))) 0
