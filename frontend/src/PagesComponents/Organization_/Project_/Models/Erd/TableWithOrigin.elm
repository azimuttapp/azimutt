module PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (CheckWithOrigin, ColumnWithOrigin, CommentWithOrigin, IndexWithOrigin, NestedColumnsWithOrigin(..), PrimaryKeyWithOrigin, TableWithOrigin, UniqueWithOrigin, create, getColumn, merge, unpack)

import Conf
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Ned as Ned exposing (Ned)
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Check exposing (Check)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.Column exposing (Column, NestedColumns(..))
import Models.Project.ColumnDbStats exposing (ColumnDbStats)
import Models.Project.ColumnIndex exposing (ColumnIndex)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Comment exposing (Comment)
import Models.Project.Index exposing (Index)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.PrimaryKeyName exposing (PrimaryKeyName)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId, SourceIdStr)
import Models.Project.Table exposing (Table)
import Models.Project.TableDbStats exposing (TableDbStats)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import Models.Project.Unique exposing (Unique)
import Models.Project.UniqueName exposing (UniqueName)
import PagesComponents.Organization_.Project_.Models.ErdOrigin as ErdOrigin exposing (ErdOrigin)


type alias TableWithOrigin =
    { id : TableId
    , schema : SchemaName
    , name : TableName
    , view : Bool
    , definition : Maybe String
    , columns : Dict ColumnName ColumnWithOrigin
    , primaryKey : Maybe PrimaryKeyWithOrigin
    , uniques : List UniqueWithOrigin
    , indexes : List IndexWithOrigin
    , checks : List CheckWithOrigin
    , comment : Maybe CommentWithOrigin
    , stats : Dict SourceIdStr TableDbStats
    , origins : List ErdOrigin
    }


create : Source -> Table -> TableWithOrigin
create source table =
    let
        origin : ErdOrigin
        origin =
            ErdOrigin.create source
    in
    { id = table.id
    , schema = table.schema
    , name = table.name
    , view = table.view
    , definition = table.definition
    , columns = table.columns |> Dict.map (\_ -> createColumn origin)
    , primaryKey = table.primaryKey |> Maybe.map (createPrimaryKey origin)
    , uniques = table.uniques |> List.map (createUnique origin)
    , indexes = table.indexes |> List.map (createIndex origin)
    , checks = table.checks |> List.map (createCheck origin)
    , comment = table.comment |> Maybe.map (createComment origin)
    , stats = table.stats |> Maybe.mapOrElse (\stats -> Dict.fromList [ ( origin.id |> SourceId.toString, stats ) ]) Dict.empty
    , origins = [ origin ]
    }


unpack : TableWithOrigin -> Table
unpack table =
    { id = table.id
    , schema = table.schema
    , name = table.name
    , view = table.view
    , definition = table.definition
    , columns = table.columns |> Dict.map (\_ -> unpackColumn)
    , primaryKey = table.primaryKey |> Maybe.map unpackPrimaryKey
    , uniques = table.uniques |> List.map unpackUnique
    , indexes = table.indexes |> List.map unpackIndex
    , checks = table.checks |> List.map unpackCheck
    , comment = table.comment |> Maybe.map unpackComment
    , stats = table.stats |> Dict.values |> List.head
    }


merge : TableWithOrigin -> TableWithOrigin -> TableWithOrigin
merge t1 t2 =
    { id = t1.id
    , schema = t1.schema
    , name = t1.name
    , view = t1.view
    , definition = t1.definition |> Maybe.orElse t2.definition
    , columns = Dict.fuse mergeColumn t1.columns t2.columns
    , primaryKey = Maybe.merge mergePrimaryKey t1.primaryKey t2.primaryKey
    , uniques = List.merge .name mergeUnique t1.uniques t2.uniques
    , indexes = List.merge .name mergeIndex t1.indexes t2.indexes
    , checks = List.merge .name mergeCheck t1.checks t2.checks
    , comment = Maybe.merge mergeComment t1.comment t2.comment
    , origins = t1.origins ++ t2.origins
    , stats = Dict.union t1.stats t2.stats
    }


getColumn : ColumnPath -> TableWithOrigin -> Maybe ColumnWithOrigin
getColumn path table =
    table.columns
        |> Dict.get path.head
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> getColumn2 next col) (Just col))


getColumn2 : ColumnPath -> ColumnWithOrigin -> Maybe ColumnWithOrigin
getColumn2 path column =
    column.columns
        |> Maybe.andThen (\(NestedColumnsWithOrigin cols) -> cols |> Ned.get path.head)
        |> Maybe.andThen (\col -> path.tail |> Nel.fromList |> Maybe.mapOrElse (\next -> getColumn2 next col) (Just col))


type alias ColumnWithOrigin =
    { index : ColumnIndex
    , name : ColumnName
    , kind : ColumnType
    , nullable : Bool
    , default : Maybe ColumnValue
    , comment : Maybe CommentWithOrigin
    , values : Maybe (Nel String)
    , columns : Maybe NestedColumnsWithOrigin
    , stats : Dict SourceIdStr ColumnDbStats
    , origins : List ErdOrigin
    }


type NestedColumnsWithOrigin
    = NestedColumnsWithOrigin (Ned ColumnName ColumnWithOrigin)


createColumn : ErdOrigin -> Column -> ColumnWithOrigin
createColumn origin column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map (createComment origin)
    , values = column.values
    , columns = column.columns |> Maybe.map (\(NestedColumns cols) -> cols |> Ned.map (\_ -> createColumn origin) |> NestedColumnsWithOrigin)
    , stats = column.stats |> Maybe.mapOrElse (\stats -> Dict.fromList [ ( origin.id |> SourceId.toString, stats ) ]) Dict.empty
    , origins = [ origin ]
    }


unpackColumn : ColumnWithOrigin -> Column
unpackColumn column =
    { index = column.index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable
    , default = column.default
    , comment = column.comment |> Maybe.map unpackComment
    , values = column.values
    , columns = column.columns |> Maybe.map (\(NestedColumnsWithOrigin cols) -> cols |> Ned.map (\_ -> unpackColumn) |> NestedColumns)
    , stats = column.stats |> Dict.values |> List.head
    }


mergeColumn : ColumnWithOrigin -> ColumnWithOrigin -> ColumnWithOrigin
mergeColumn c1 c2 =
    { index = c1.index
    , name = c1.name
    , kind =
        if c1.kind == Conf.schema.column.unknownType then
            c2.kind

        else
            c1.kind
    , nullable = c1.nullable && c2.nullable
    , default = c1.default
    , comment = Maybe.merge mergeComment c1.comment c2.comment
    , columns = Maybe.merge mergeColumnNested c1.columns c2.columns
    , values = Maybe.merge Nel.append c1.values c2.values
    , stats = Dict.union c1.stats c2.stats
    , origins = c1.origins ++ c2.origins
    }


mergeColumnNested : NestedColumnsWithOrigin -> NestedColumnsWithOrigin -> NestedColumnsWithOrigin
mergeColumnNested (NestedColumnsWithOrigin c1) (NestedColumnsWithOrigin c2) =
    Ned.merge mergeColumn c1 c2 |> NestedColumnsWithOrigin


type alias PrimaryKeyWithOrigin =
    { name : Maybe PrimaryKeyName
    , columns : Nel ColumnPath
    , origins : List ErdOrigin
    }


createPrimaryKey : ErdOrigin -> PrimaryKey -> PrimaryKeyWithOrigin
createPrimaryKey origin primaryKey =
    { name = primaryKey.name
    , columns = primaryKey.columns
    , origins = [ origin ]
    }


unpackPrimaryKey : PrimaryKeyWithOrigin -> PrimaryKey
unpackPrimaryKey primaryKey =
    { name = primaryKey.name
    , columns = primaryKey.columns
    }


mergePrimaryKey : PrimaryKeyWithOrigin -> PrimaryKeyWithOrigin -> PrimaryKeyWithOrigin
mergePrimaryKey pk1 pk2 =
    { name = pk1.name
    , columns = Nel.merge ColumnPath.toString ColumnPath.merge pk1.columns pk2.columns
    , origins = pk1.origins ++ pk2.origins
    }


type alias UniqueWithOrigin =
    { name : UniqueName
    , columns : Nel ColumnPath
    , definition : Maybe String
    , origins : List ErdOrigin
    }


createUnique : ErdOrigin -> Unique -> UniqueWithOrigin
createUnique origin unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    , origins = [ origin ]
    }


unpackUnique : UniqueWithOrigin -> Unique
unpackUnique unique =
    { name = unique.name
    , columns = unique.columns
    , definition = unique.definition
    }


mergeUnique : UniqueWithOrigin -> UniqueWithOrigin -> UniqueWithOrigin
mergeUnique u1 u2 =
    { name = u1.name
    , columns = Nel.merge ColumnPath.toString ColumnPath.merge u1.columns u2.columns
    , definition = u1.definition
    , origins = u1.origins ++ u2.origins
    }


type alias IndexWithOrigin =
    { name : IndexName
    , columns : Nel ColumnPath
    , definition : Maybe String
    , origins : List ErdOrigin
    }


createIndex : ErdOrigin -> Index -> IndexWithOrigin
createIndex origin index =
    { name = index.name
    , columns = index.columns
    , definition = index.definition
    , origins = [ origin ]
    }


unpackIndex : IndexWithOrigin -> Index
unpackIndex index =
    { name = index.name
    , columns = index.columns
    , definition = index.definition
    }


mergeIndex : IndexWithOrigin -> IndexWithOrigin -> IndexWithOrigin
mergeIndex i1 i2 =
    { name = i1.name
    , columns = Nel.merge ColumnPath.toString ColumnPath.merge i1.columns i2.columns
    , definition = i1.definition
    , origins = i1.origins ++ i2.origins
    }


type alias CheckWithOrigin =
    { name : CheckName
    , columns : List ColumnPath
    , predicate : Maybe String
    , origins : List ErdOrigin
    }


createCheck : ErdOrigin -> Check -> CheckWithOrigin
createCheck origin check =
    { name = check.name
    , columns = check.columns
    , predicate = check.predicate
    , origins = [ origin ]
    }


unpackCheck : CheckWithOrigin -> Check
unpackCheck check =
    { name = check.name
    , columns = check.columns
    , predicate = check.predicate
    }


mergeCheck : CheckWithOrigin -> CheckWithOrigin -> CheckWithOrigin
mergeCheck c1 c2 =
    { name = c1.name
    , columns = List.merge ColumnPath.toString ColumnPath.merge c1.columns c2.columns
    , predicate = c1.predicate
    , origins = c1.origins ++ c2.origins
    }


type alias CommentWithOrigin =
    { text : String
    , origins : List ErdOrigin
    }


createComment : ErdOrigin -> Comment -> CommentWithOrigin
createComment origin comment =
    { text = comment.text
    , origins = [ origin ]
    }


unpackComment : CommentWithOrigin -> Comment
unpackComment comment =
    { text = comment.text
    }


mergeComment : CommentWithOrigin -> CommentWithOrigin -> CommentWithOrigin
mergeComment c1 c2 =
    { text = c1.text
    , origins = c1.origins ++ c2.origins
    }
