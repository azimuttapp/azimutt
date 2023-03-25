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
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.RelationName exposing (RelationName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
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
buildSource source lines schema =
    { id = source.id
    , name = source.name
    , kind = source.kind
    , content = lines |> List.map .text |> Array.fromList
    , tables = schema.tables
    , relations = schema.relations |> List.reverse
    , types = schema.types |> Dict.fromListMap .id
    , enabled = source.enabled
    , fromSample = source.fromSample
    , createdAt = source.createdAt
    , updatedAt = source.updatedAt
    }


evolve : SourceId -> ( SqlStatement, Command ) -> SqlSchema -> SqlSchema
evolve source ( statement, command ) content =
    let
        origin : Origin
        origin =
            createOrigin source statement
    in
    case command of
        CreateTable sqlTable ->
            sqlTable
                |> createTable origin content.tables
                |> (\( table, relations, errors ) ->
                        (content.tables |> Dict.get table.id)
                            |> Maybe.map (\_ -> { content | errors = [ "Table '" ++ TableId.show Conf.schema.empty table.id ++ "' is already defined" ] :: content.errors })
                            |> Maybe.withDefault { content | tables = content.tables |> Dict.insert table.id table, relations = relations ++ content.relations, errors = content.errors |> addErrors errors }
                   )

        CreateView sqlView ->
            sqlView
                |> createView origin content.tables
                |> (\view ->
                        (content.tables |> Dict.get view.id)
                            |> Maybe.filterNot (\_ -> sqlView.replace)
                            |> Maybe.map (\_ -> { content | errors = [ "View '" ++ TableId.show Conf.schema.empty view.id ++ "' is already defined" ] :: content.errors })
                            |> Maybe.withDefault { content | tables = content.tables |> Dict.insert view.id view }
                   )

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedPrimaryKey constraintName pk)) ->
            updateTable schema table (\t -> t.primaryKey |> Maybe.mapOrElse (\_ -> ( t, [ "Primary key already defined for '" ++ TableId.show Conf.schema.empty t.id ++ "' table" ] )) ( { t | primaryKey = Just (PrimaryKey constraintName (pk |> Nel.map ColumnPath.fromString) [ origin ]) }, [] )) statement content

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedForeignKey constraint fks)) ->
            -- TODO: handle multi-column foreign key!
            createRelation origin content.tables table constraint (ColumnRef (createTableId schema table) (ColumnPath.fromString fks.head.column)) fks.head.ref
                |> (\( relation, errors ) ->
                        { content
                            | relations = relation |> Maybe.mapOrElse (\r -> r :: content.relations) content.relations
                            , errors = content.errors |> addErrors errors
                        }
                   )

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedUnique constraint unique)) ->
            updateTable schema table (\t -> ( { t | uniques = t.uniques ++ [ Unique constraint (unique.columns |> Nel.map ColumnPath.fromString) (Just unique.definition) [ origin ] ] }, [] )) statement content

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedCheck constraint check)) ->
            updateTable schema table (\t -> ( { t | checks = t.checks ++ [ Check constraint (check.columns |> List.map ColumnPath.fromString) (Just check.predicate) [ origin ] ] }, [] )) statement content

        AlterTable (AddTableConstraint _ _ (IgnoredConstraint _)) ->
            content

        AlterTable (AlterColumn schema table (ColumnDefault column default)) ->
            updateColumn schema table column (\c -> ( { c | default = Just default, origins = c.origins ++ [ origin ] }, [] )) statement content

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
            updateTable index.table.schema index.table.table (\t -> ( { t | indexes = t.indexes ++ [ Index index.name (index.columns |> Nel.map ColumnPath.fromString) (Just index.definition) [ origin ] ] }, [] )) statement content

        CreateUnique unique ->
            updateTable unique.table.schema unique.table.table (\t -> ( { t | uniques = t.uniques ++ [ Unique unique.name (unique.columns |> Nel.map ColumnPath.fromString) (Just unique.definition) [ origin ] ] }, [] )) statement content

        TableComment comment ->
            updateTable comment.schema comment.table (\t -> t.comment |> Maybe.mapOrElse (\_ -> ( t, [ "Comment already defined for '" ++ TableId.show Conf.schema.empty t.id ++ "' table" ] )) ( { t | comment = Just (Comment comment.comment [ origin ]) }, [] )) statement content

        ColumnComment comment ->
            updateColumn comment.schema comment.table comment.column (\c -> c.comment |> Maybe.mapOrElse (\_ -> ( c, [ "Comment already defined for '" ++ c.name ++ "' column in '" ++ TableId.show Conf.schema.empty (createTableId comment.schema comment.table) ++ "' table" ] )) ( { c | comment = Just (Comment comment.comment [ origin ]) }, [] )) statement content

        ConstraintComment _ ->
            content

        CreateType t ->
            { content | types = createType origin t :: content.types }

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


createTable : Origin -> Dict TableId Table -> ParsedTable -> ( Table, List Relation, List SqlSchemaError )
createTable origin tables table =
    let
        id : TableId
        id =
            createTableId table.schema table.table

        ( relations, errors ) =
            table.foreignKeys |> createRelations origin tables id table.table table.columns
    in
    ( { id = id
      , schema = id |> Tuple.first
      , name = id |> Tuple.second
      , view = False
      , columns = table.columns |> Nel.toList |> List.indexedMap (createColumn origin table.primaryKey) |> Dict.fromListMap .name
      , primaryKey = table.primaryKey |> createPrimaryKey origin table.columns
      , uniques = table.uniques |> createUniques origin table.table table.columns
      , indexes = table.indexes |> createIndexes origin
      , checks = table.checks |> createChecks origin table.table table.columns
      , comment = Nothing
      , origins = [ origin ]
      }
    , relations
    , errors
    )


createColumn : Origin -> Maybe ParsedPrimaryKey -> Int -> ParsedColumn -> Column
createColumn origin pk index column =
    { index = index
    , name = column.name
    , kind = column.kind
    , nullable = column.nullable && (pk |> Maybe.any (\k -> k.columns |> Nel.any (\c -> c == column.name)))
    , default = column.default
    , comment = column.comment |> Maybe.map (createComment origin)
    , columns = Nothing -- nested columns not supported in SQL
    , origins = [ origin ]
    }


createView : Origin -> Dict TableId Table -> ParsedView -> Table
createView origin tables view =
    let
        id : TableId
        id =
            createTableId view.schema view.table
    in
    { id = id
    , schema = id |> Tuple.first
    , name = id |> Tuple.second
    , view = True
    , columns = view.select.columns |> List.indexedMap (buildViewColumn origin tables) |> Dict.fromListMap .name
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , comment = Nothing
    , origins = [ origin ]
    }


buildViewColumn : Origin -> Dict TableId Table -> Int -> SelectColumn -> Column
buildViewColumn origin tables index column =
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
                        , columns = Nothing -- nested columns not supported in SQL
                        , origins = [ origin ]
                        }
                    )
                    { index = index
                    , name = c.alias |> Maybe.withDefault c.column
                    , kind = Conf.schema.column.unknownType
                    , nullable = False
                    , default = Just ((c.table |> Maybe.mapOrElse (\t -> t ++ ".") "") ++ c.column)
                    , comment = Nothing
                    , columns = Nothing -- nested columns not supported in SQL
                    , origins = [ origin ]
                    }

        ComplexColumn c ->
            { index = index
            , name = c.alias
            , kind = Conf.schema.column.unknownType
            , nullable = False
            , default = Just c.formula
            , comment = Nothing
            , columns = Nothing -- nested columns not supported in SQL
            , origins = [ origin ]
            }


createPrimaryKey : Origin -> Nel ParsedColumn -> Maybe ParsedPrimaryKey -> Maybe PrimaryKey
createPrimaryKey origin columns primaryKey =
    (primaryKey |> Maybe.map (\pk -> PrimaryKey pk.name (pk.columns |> Nel.map ColumnPath.fromString) [ origin ]))
        |> Maybe.orElse (columns |> Nel.filterMap (\c -> c.primaryKey |> Maybe.map (\pk -> PrimaryKey (String.nonEmptyMaybe pk) (Nel (c.name |> ColumnPath.fromString) []) [ origin ])) |> List.head)


createUniques : Origin -> SqlTableName -> Nel ParsedColumn -> List ParsedUnique -> List Unique
createUniques origin tableName columns uniques =
    (uniques |> List.map (\u -> Unique u.name (u.columns |> Nel.map ColumnPath.fromString) (Just u.definition) [ origin ]))
        ++ (columns |> Nel.toList |> List.filterMap (\col -> col.unique |> Maybe.map (\u -> Unique (defaultUniqueName tableName col.name) (Nel (col.name |> ColumnPath.fromString) []) (Just u) [ origin ])))


createIndexes : Origin -> List ParsedIndex -> List Index
createIndexes origin indexes =
    indexes |> List.map (\i -> Index i.name (i.columns |> Nel.map ColumnPath.fromString) (Just i.definition) [ origin ])


createChecks : Origin -> SqlTableName -> Nel ParsedColumn -> List ParsedCheck -> List Check
createChecks origin tableName columns checks =
    (checks |> List.map (\c -> Check c.name (c.columns |> List.map ColumnPath.fromString) (Just c.predicate) [ origin ]))
        ++ (columns |> Nel.toList |> List.filterMap (\col -> col.check |> Maybe.map (\c -> Check (defaultCheckName tableName col.name) [ col.name |> ColumnPath.fromString ] (Just c) [ origin ])))


createType : Origin -> ParsedType -> CustomType
createType origin t =
    (case t.value of
        EnumType values ->
            CustomTypeValue.Enum values

        UnknownType definition ->
            CustomTypeValue.Definition definition
    )
        |> (\value -> { id = ( t.schema |> Maybe.withDefault "", t.name ), name = t.name, value = value, origins = [ origin ] })


createComment : Origin -> SqlComment -> Comment
createComment origin comment =
    Comment comment [ origin ]


createRelations : Origin -> Dict TableId Table -> TableId -> SqlTableName -> Nel ParsedColumn -> List ParsedForeignKey -> ( List Relation, List SqlSchemaError )
createRelations origin tables tableId tableName columns foreignKeys =
    ((columns |> Nel.toList |> List.filterMap (\col -> col.foreignKey |> Maybe.map (\( name, ref ) -> createRelation origin tables tableName name (ColumnRef tableId (ColumnPath.fromString col.name)) ref)))
        ++ (foreignKeys |> List.map (\fk -> createRelation origin tables tableName fk.name (ColumnRef tableId (ColumnPath.fromString fk.src)) fk.ref))
    )
        |> List.foldr (\( rel, errs ) ( rels, errors ) -> ( rel |> Maybe.mapOrElse (\r -> r :: rels) rels, errs ++ errors )) ( [], [] )


createRelation : Origin -> Dict TableId Table -> SqlTableName -> Maybe RelationName -> ColumnRef -> SqlForeignKeyRef -> ( Maybe Relation, List SqlSchemaError )
createRelation origin tables table relation src ref =
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
    ( refCol |> Maybe.map (\col -> Relation.new name src (ColumnRef refTable col) [ origin ]), errors )


createOrigin : SourceId -> SqlStatement -> Origin
createOrigin source statement =
    { id = source, lines = statement |> Nel.map .index |> Nel.toList }


createTableId : Maybe SqlSchemaName -> SqlTableName -> TableId
createTableId schema table =
    ( schema |> Maybe.withDefault Conf.schema.empty, table )


addErrors : List SqlSchemaError -> List (List SqlSchemaError) -> List (List SqlSchemaError)
addErrors new initial =
    if List.isEmpty new then
        initial

    else
        new :: initial
