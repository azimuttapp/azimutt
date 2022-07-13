module PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable, create, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.Check exposing (Check)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.Project.Unique exposing (Unique)
import PagesComponents.Projects.Id_.Models.ErdColumn as ErdColumn exposing (ErdColumn)


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


create : SchemaName -> Dict TableId Table -> List Relation -> Table -> ErdTable
create defaultSchema tables tableRelations table =
    let
        relationsByColumn : Dict ColumnName (List Relation)
        relationsByColumn =
            tableRelations
                |> List.foldr
                    (\rel dict ->
                        if rel.src.table == table.id && rel.ref.table == table.id then
                            dict
                                |> Dict.update rel.src.column (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)
                                |> Dict.update rel.ref.column (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else if rel.src.table == table.id then
                            dict |> Dict.update rel.src.column (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

                        else if rel.ref.table == table.id then
                            dict |> Dict.update rel.ref.column (Maybe.mapOrElse (\relations -> rel :: relations) [ rel ] >> Just)

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
    , columns = table.columns |> Dict.map (\name -> ErdColumn.create tables (relationsByColumn |> Dict.getOrElse name []) table)
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
