module DataSources.SqlMiner.SqlAdapter exposing (SqlSchema, SqlSchemaError, buildSource, evolve, initSchema)

import Array
import Conf
import DataSources.Helpers exposing (SourceLine, defaultCheckName, defaultRelName, defaultUniqueName)
import DataSources.SqlMiner.Parsers.AlterTable as AlterTable exposing (ColumnUpdate(..), TableConstraint(..), TableUpdate(..))
import DataSources.SqlMiner.Parsers.CreateTable exposing (ParsedCheck, ParsedColumn, ParsedForeignKey, ParsedIndex, ParsedPrimaryKey, ParsedTable, ParsedUnique)
import DataSources.SqlMiner.Parsers.CreateType exposing (ParsedType, ParsedTypeValue(..))
import DataSources.SqlMiner.Parsers.CreateView exposing (ParsedView)
import DataSources.SqlMiner.Parsers.Select exposing (SelectColumn(..))
import DataSources.SqlMiner.SqlParser exposing (Command(..))
import DataSources.SqlMiner.Utils.Helpers exposing (buildRawSql)
import DataSources.SqlMiner.Utils.Types exposing (SqlColumnName, SqlComment, SqlForeignKeyRef, SqlSchemaName, SqlStatement, SqlTableName)
import Dict exposing (Dict)
import Libs.Dict as Dict
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Libs.String as String
import Models.Project.Check exposing (Check)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Comment exposing (Comment)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeValue as CustomTypeValue
import Models.Project.Index exposing (Index)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.Source exposing (Source)
import Models.Project.Table exposing (Table)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.Unique exposing (Unique)
import Models.SourceInfo exposing (SourceInfo)


type alias SqlSchema =
    { tables : Dict TableId Table
    , relations : List Relation
    , types : List CustomType
    , errors : List (List SqlSchemaError)
    }


type alias SqlSchemaError =
    String


initSchema : SqlSchema
initSchema =
    { tables = Dict.empty, relations = [], types = [], errors = [] }


buildSource : SourceInfo -> List SourceLine -> SqlSchema -> Source
buildSource source _ schema =
    { id = source.id
    , name = source.name
    , kind = source.kind
    , content = [] |> Array.fromList -- don't store the source anymore (not used but heavy)
    , tables = schema.tables
    , relations = schema.relations |> List.reverse
    , types = schema.types |> Dict.fromListMap .id
    , enabled = source.enabled
    , fromSample = source.fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


evolve : ( SqlStatement, Command ) -> SqlSchema -> SqlSchema
evolve ( statement, command ) content =
    case command of
        CreateTable sqlTable ->
            sqlTable
                |> createTable content.tables
                |> (\( table, relations, errors ) ->
                        (content.tables |> Dict.get table.id)
                            |> Maybe.map (\_ -> { content | errors = [ "Table '" ++ TableId.show Conf.schema.empty table.id ++ "' is already defined" ] :: content.errors })
                            |> Maybe.withDefault { content | tables = content.tables |> Dict.insert table.id table, relations = relations ++ content.relations, errors = content.errors |> addErrors errors }
                   )

        CreateView sqlView ->
            sqlView
                |> createView content.tables statement
                |> (\view ->
                        (content.tables |> Dict.get view.id)
                            |> Maybe.filterNot (\_ -> sqlView.replace)
                            |> Maybe.map (\_ -> { content | errors = [ "View '" ++ TableId.show Conf.schema.empty view.id ++ "' is already defined" ] :: content.errors })
                            |> Maybe.withDefault { content | tables = content.tables |> Dict.insert view.id view }
                   )

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedPrimaryKey constraintName pk)) ->
            updateTable schema table (\t -> t.primaryKey |> Maybe.mapOrElse (\_ -> ( t, [ "Primary key already defined for '" ++ TableId.show Conf.schema.empty t.id ++ "' table" ] )) ( { t | primaryKey = Just (PrimaryKey constraintName (pk |> Nel.map ColumnPath.fromString)) }, [] )) statement content

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedForeignKey constraint fks)) ->
            -- TODO: handle multi-column foreign key!
            createRelation content.tables table constraint (ColumnRef (createTableId schema table) (ColumnPath.fromString fks.head.column)) fks.head.ref
                |> (\( relation, errors ) ->
                        { content
                            | relations = relation |> Maybe.mapOrElse (\r -> r :: content.relations) content.relations
                            , errors = content.errors |> addErrors errors
                        }
                   )

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedUnique constraint unique)) ->
            updateTable schema table (\t -> ( { t | uniques = t.uniques ++ [ Unique constraint (unique.columns |> Nel.map ColumnPath.fromString) (Just unique.definition) ] }, [] )) statement content

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedCheck constraint check)) ->
            updateTable schema table (\t -> ( { t | checks = t.checks ++ [ Check constraint (check.columns |> List.map ColumnPath.fromString) (Just check.predicate) ] }, [] )) statement content

        AlterTable (AddTableConstraint _ _ (IgnoredConstraint _)) ->
            content

        AlterTable (AlterColumn schema table (ColumnDefault column default)) ->
            updateColumn schema table column (\c -> ( { c | default = Just default }, [] )) statement content

        AlterTable (AlterColumn _ _ (ColumnStatistics _ _)) ->
            content

        AlterTable (DropColumn schema table column) ->
            deleteColumn schema table column statement content

        AlterTable (AddTableOwner _ _ _) ->
            content

        AlterTable (AttachPartition _ _) ->
            content

        AlterTable (DropConstraint _ _ _) ->
            content

        AlterTable (IgnoredCommand _) ->
            content

        CreateIndex index ->
            updateTable index.table.schema index.table.table (\t -> ( { t | indexes = t.indexes ++ [ Index index.name (index.columns |> Nel.map ColumnPath.fromString) (Just index.definition) ] }, [] )) statement content

        CreateUnique unique ->
            updateTable unique.table.schema unique.table.table (\t -> ( { t | uniques = t.uniques ++ [ Unique unique.name (unique.columns |> Nel.map ColumnPath.fromString) (Just unique.definition) ] }, [] )) statement content

        TableComment comment ->
            updateTable comment.schema comment.table (\t -> t.comment |> Maybe.mapOrElse (\_ -> ( t, [ "Comment already defined for '" ++ TableId.show Conf.schema.empty t.id ++ "' table" ] )) ( { t | comment = Just (Comment comment.comment) }, [] )) statement content

        ColumnComment comment ->
            updateColumn comment.schema comment.table comment.column (\c -> c.comment |> Maybe.mapOrElse (\_ -> ( c, [ "Comment already defined for '" ++ c.name ++ "' column in '" ++ TableId.show Conf.schema.empty (createTableId comment.schema comment.table) ++ "' table" ] )) ( { c | comment = Just (Comment comment.comment) }, [] )) statement content

        ConstraintComment _ ->
            content

        CreateType t ->
            { content | types = createType t :: content.types }

        Ignored _ ->
            content


updateTable : Maybe SqlSchemaName -> SqlTableName -> (Table -> ( Table, List SqlSchemaError )) -> SqlStatement -> SqlSchema -> SqlSchema
updateTable schema table transform statement content =
    createTableId schema table
        |> (\id ->
                (content.tables |> Dict.get id)
                    |> Maybe.map transform
                    |> Maybe.map (\( t, errors ) -> { content | tables = content.tables |> Dict.insert id t, errors = content.errors |> addErrors errors })
                    |> Maybe.withDefault { content | errors = [ "Table '" ++ TableId.show Conf.schema.empty id ++ "' does not exist (in '" ++ buildRawSql statement ++ "')" ] :: content.errors }
           )


updateColumn : Maybe SqlSchemaName -> SqlTableName -> SqlColumnName -> (Column -> ( Column, List SqlSchemaError )) -> SqlStatement -> SqlSchema -> SqlSchema
updateColumn schema table column transform statement content =
    updateTable
        schema
        table
        (\t ->
            (t.columns |> Dict.get column)
                |> Maybe.map transform
                |> Maybe.map (\( col, errors ) -> ( { t | columns = t.columns |> Dict.insert column col }, errors ))
                |> Maybe.withDefault ( t, [ "Column '" ++ column ++ "' does not exist in table '" ++ TableId.show Conf.schema.empty t.id ++ "' (in '" ++ buildRawSql statement ++ "')" ] )
        )
        statement
        content


deleteColumn : Maybe SqlSchemaName -> SqlTableName -> SqlColumnName -> SqlStatement -> SqlSchema -> SqlSchema
deleteColumn schema table column statement content =
    updateTable
        schema
        table
        (\t ->
            (t.columns |> Dict.get column)
                |> Maybe.map
                    (\_ ->
                        if Dict.size t.columns == 1 then
                            ( t, [ "Can't delete last column (" ++ column ++ ") of table " ++ TableId.show Conf.schema.empty t.id ++ " (in '" ++ buildRawSql statement ++ "')" ] )

                        else
                            ( { t | columns = t.columns |> Dict.remove column }, [] )
                    )
                |> Maybe.withDefault ( t, [ "Can't delete missing column " ++ column ++ " in table " ++ TableId.show Conf.schema.empty t.id ++ " (in '" ++ buildRawSql statement ++ "')" ] )
        )
        statement
        content


createTable : Dict TableId Table -> ParsedTable -> ( Table, List Relation, List SqlSchemaError )
createTable tables table =
    let
        id : TableId
        id =
            createTableId table.schema table.table

        ( relations, errors ) =
            table.foreignKeys |> createRelations tables id table.table table.columns
    in
    ( { id = id
      , schema = id |> Tuple.first
      , name = id |> Tuple.second
      , view = False
      , definition = Nothing
      , columns = table.columns |> Nel.toList |> List.indexedMap (createColumn table.primaryKey) |> Dict.fromListMap .name
      , primaryKey = table.primaryKey |> createPrimaryKey table.columns
      , uniques = table.uniques |> createUniques table.table table.columns
      , indexes = table.indexes |> createIndexes
      , checks = table.checks |> createChecks table.table table.columns
      , comment = Nothing
      , stats = Nothing
      }
    , relations
    , errors
    )


createColumn : Maybe ParsedPrimaryKey -> Int -> ParsedColumn -> Column
createColumn pk index column =
    let
        inPk : Bool
        inPk =
            (column.primaryKey |> Maybe.isJust) || (pk |> Maybe.any (\k -> k.columns |> Nel.any (\c -> c == column.name)))
    in
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable && not inPk
    , default = column.default
    , comment = column.comment |> Maybe.map createComment
    , values = Nothing
    , columns = Nothing -- nested columns not supported in SQL
    , stats = Nothing
    }


createView : Dict TableId Table -> SqlStatement -> ParsedView -> Table
createView tables statement view =
    let
        id : TableId
        id =
            createTableId view.schema view.table
    in
    { id = id
    , schema = id |> Tuple.first
    , name = id |> Tuple.second
    , view = True
    , definition = statement |> Nel.map .text |> Nel.join "\n" |> Just
    , columns = view.select.columns |> List.indexedMap (buildViewColumn tables) |> Dict.fromListMap .name
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    , stats = Nothing
    }


buildViewColumn : Dict TableId Table -> Int -> SelectColumn -> Column
buildViewColumn tables index column =
    case column of
        BasicColumn c ->
            c.table
                -- TODO: should handle table alias (when table is renamed in select)
                |> Maybe.andThen (\t -> tables |> Dict.get (createTableId Nothing t))
                |> Maybe.andThen (\t -> t.columns |> Dict.get c.column)
                |> Maybe.mapOrElse
                    (\col ->
                        { index = index
                        , name = c.alias |> Maybe.withDefault c.column
                        , kind = col.kind
                        , nullable = col.nullable
                        , default = Just ((c.table |> Maybe.mapOrElse (\t -> t ++ ".") "") ++ c.column)
                        , comment = col.comment
                        , values = Nothing
                        , columns = Nothing -- nested columns not supported in SQL
                        , stats = Nothing
                        }
                    )
                    { index = index
                    , name = c.alias |> Maybe.withDefault c.column
                    , kind = Conf.schema.column.unknownType
                    , nullable = False
                    , default = Just ((c.table |> Maybe.mapOrElse (\t -> t ++ ".") "") ++ c.column)
                    , comment = Nothing
                    , values = Nothing
                    , columns = Nothing -- nested columns not supported in SQL
                    , stats = Nothing
                    }

        ComplexColumn c ->
            { index = index
            , name = c.alias
            , kind = Conf.schema.column.unknownType
            , nullable = False
            , default = Just c.formula
            , comment = Nothing
            , values = Nothing
            , columns = Nothing -- nested columns not supported in SQL
            , stats = Nothing
            }


createPrimaryKey : Nel ParsedColumn -> Maybe ParsedPrimaryKey -> Maybe PrimaryKey
createPrimaryKey columns primaryKey =
    (primaryKey |> Maybe.map (\pk -> PrimaryKey pk.name (pk.columns |> Nel.map ColumnPath.fromString)))
        |> Maybe.orElse (columns |> Nel.filterMap (\c -> c.primaryKey |> Maybe.map (\pk -> PrimaryKey (String.nonEmptyMaybe pk) (Nel (c.name |> ColumnPath.fromString) []))) |> List.head)


createUniques : SqlTableName -> Nel ParsedColumn -> List ParsedUnique -> List Unique
createUniques tableName columns uniques =
    (uniques |> List.map (\u -> Unique u.name (u.columns |> Nel.map ColumnPath.fromString) (Just u.definition)))
        ++ (columns |> Nel.toList |> List.filterMap (\col -> col.unique |> Maybe.map (\u -> Unique (defaultUniqueName tableName col.name) (Nel (col.name |> ColumnPath.fromString) []) (Just u))))


createIndexes : List ParsedIndex -> List Index
createIndexes indexes =
    indexes |> List.map (\i -> Index i.name (i.columns |> Nel.map ColumnPath.fromString) (Just i.definition))


createChecks : SqlTableName -> Nel ParsedColumn -> List ParsedCheck -> List Check
createChecks tableName columns checks =
    (checks |> List.map (\c -> Check c.name (c.columns |> List.map ColumnPath.fromString) (Just c.predicate)))
        ++ (columns |> Nel.toList |> List.filterMap (\col -> col.check |> Maybe.map (\c -> Check (defaultCheckName tableName col.name) [ col.name |> ColumnPath.fromString ] (Just c))))


createType : ParsedType -> CustomType
createType t =
    (case t.value of
        EnumType values ->
            CustomTypeValue.Enum values

        UnknownType definition ->
            CustomTypeValue.Definition definition
    )
        |> (\value -> { id = ( t.schema |> Maybe.withDefault "", t.name ), name = t.name, value = value })


createComment : SqlComment -> Comment
createComment comment =
    Comment comment


createRelations : Dict TableId Table -> TableId -> SqlTableName -> Nel ParsedColumn -> List ParsedForeignKey -> ( List Relation, List SqlSchemaError )
createRelations tables tableId tableName columns foreignKeys =
    ((columns |> Nel.toList |> List.filterMap (\col -> col.foreignKey |> Maybe.map (\( name, ref ) -> createRelation tables tableName name (ColumnRef tableId (ColumnPath.fromString col.name)) ref)))
        ++ (foreignKeys |> List.map (\fk -> createRelation tables tableName fk.name (ColumnRef tableId (ColumnPath.fromString fk.src)) fk.ref))
    )
        |> List.foldr (\( rel, errs ) ( rels, errors ) -> ( rel |> Maybe.mapOrElse (\r -> r :: rels) rels, errs ++ errors )) ( [], [] )


createRelation : Dict TableId Table -> SqlTableName -> Maybe RelationName -> ColumnRef -> SqlForeignKeyRef -> ( Maybe Relation, List SqlSchemaError )
createRelation tables table relation src ref =
    let
        name : RelationName
        name =
            relation |> Maybe.withDefault (defaultRelName table src.column)

        refTable : TableId
        refTable =
            createTableId ref.schema ref.table

        ( refCol, errors ) =
            ref.column
                |> Maybe.map (\c -> ( c |> ColumnPath.fromString |> Just, [] ))
                |> Maybe.withDefault
                    (tables
                        |> Dict.get refTable
                        |> Maybe.mapOrElse
                            (\t ->
                                case t.primaryKey |> Maybe.map .columns of
                                    Just cols ->
                                        if List.isEmpty cols.tail then
                                            ( Just cols.head, [] )

                                        else
                                            ( Just cols.head, [ "Bad relation '" ++ name ++ "': target table " ++ TableId.show Conf.schema.empty refTable ++ " has a primary key with multiple columns (" ++ (cols |> Nel.map ColumnPath.show |> Nel.toList |> String.join ", ") ++ ")" ] )

                                    Nothing ->
                                        ( Nothing, [ "Can't create relation '" ++ name ++ "': target table '" ++ TableId.show Conf.schema.empty refTable ++ "' has no primary key" ] )
                            )
                            ( Nothing, [ "Can't create relation '" ++ name ++ "': target table '" ++ TableId.show Conf.schema.empty refTable ++ "' does not exist (yet)" ] )
                    )
    in
    ( refCol |> Maybe.map (\col -> Relation.new name src (ColumnRef refTable col)), errors )


createTableId : Maybe SqlSchemaName -> SqlTableName -> TableId
createTableId schema table =
    ( schema |> Maybe.withDefault Conf.schema.empty, table )


addErrors : List SqlSchemaError -> List (List SqlSchemaError) -> List (List SqlSchemaError)
addErrors new initial =
    if List.isEmpty new then
        initial

    else
        new :: initial
