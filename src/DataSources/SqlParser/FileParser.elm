module DataSources.SqlParser.FileParser exposing (SchemaError, SqlCheck, SqlColumn, SqlComment, SqlForeignKey, SqlIndex, SqlPrimaryKey, SqlSchema, SqlTable, SqlTableId, SqlUnique, buildSqlLines, buildStatements, parseLines, parseSchema)

import DataSources.SqlParser.Parsers.AlterTable as AlterTable exposing (ColumnUpdate(..), TableConstraint(..), TableUpdate(..))
import DataSources.SqlParser.Parsers.CreateTable exposing (ParsedColumn, ParsedTable)
import DataSources.SqlParser.Parsers.CreateView exposing (ParsedView)
import DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..))
import DataSources.SqlParser.StatementParser exposing (Command(..), parseStatement)
import DataSources.SqlParser.Utils.Helpers exposing (buildRawSql, defaultCheckName, defaultFkName, defaultPkName)
import DataSources.SqlParser.Utils.Types exposing (SqlColumnName, SqlColumnType, SqlColumnValue, SqlConstraintName, SqlLine, SqlPredicate, SqlSchemaName, SqlStatement, SqlTableName)
import Dict exposing (Dict)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (FileContent, FileLineContent)
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as R


type alias SchemaError =
    String


type alias SqlSchema =
    Dict SqlTableId SqlTable


type alias SqlTableId =
    String


type alias SqlTable =
    { schema : SqlSchemaName
    , table : SqlTableName
    , view : Bool
    , columns : Nel SqlColumn
    , primaryKey : Maybe SqlPrimaryKey
    , uniques : List SqlUnique
    , indexes : List SqlIndex
    , checks : List SqlCheck
    , comment : Maybe SqlComment
    , source : SqlStatement
    }


type alias SqlColumn =
    { name : SqlColumnName
    , kind : SqlColumnType
    , nullable : Bool
    , default : Maybe SqlColumnValue
    , foreignKey : Maybe SqlForeignKey
    , comment : Maybe SqlComment
    , source : SqlStatement
    }


type alias SqlPrimaryKey =
    { name : SqlConstraintName, columns : Nel SqlColumnName, source : SqlStatement }


type alias SqlForeignKey =
    { name : SqlConstraintName, schema : SqlSchemaName, table : SqlTableName, column : SqlColumnName, source : SqlStatement }


type alias SqlUnique =
    { name : SqlConstraintName, columns : Nel SqlColumnName, definition : String, source : SqlStatement }


type alias SqlIndex =
    { name : SqlConstraintName, columns : Nel SqlColumnName, definition : String, source : SqlStatement }


type alias SqlCheck =
    { name : SqlConstraintName, columns : List SqlColumnName, predicate : SqlPredicate, source : SqlStatement }


type alias SqlComment =
    { text : String, source : SqlStatement }


defaultSchema : String
defaultSchema =
    "public"


parseLines : FileContent -> List FileLineContent
parseLines fileContent =
    fileContent
        |> String.replace "\u{000D}" "\n"
        |> String.split "\n"


parseSchema : FileContent -> ( List SchemaError, ( List FileLineContent, SqlSchema ) )
parseSchema fileContent =
    let
        lines : List FileLineContent
        lines =
            parseLines fileContent
    in
    lines
        |> buildSqlLines
        |> buildStatements
        |> List.foldl
            (\statement ( errs, schema ) ->
                case statement |> parseStatement |> Result.andThen (\command -> schema |> evolve command) of
                    Ok newSchema ->
                        ( errs, newSchema )

                    Err e ->
                        ( errs ++ e, schema )
            )
            ( [], Dict.empty )
        |> (\( errs, schema ) -> ( errs, ( lines, schema ) ))


evolve : ( SqlStatement, Command ) -> SqlSchema -> Result (List SchemaError) SqlSchema
evolve ( statement, command ) tables =
    case command of
        CreateTable table ->
            let
                id : SqlTableId
                id =
                    buildId table.schema table.table
            in
            tables
                |> Dict.get id
                |> M.mapOrElse (\_ -> Err [ "Table " ++ id ++ " already exists" ])
                    (buildTable tables statement table |> Result.map (\sqlTable -> tables |> Dict.insert id sqlTable))

        CreateView view ->
            let
                id : SqlTableId
                id =
                    buildId view.schema view.table
            in
            tables
                |> Dict.get id
                |> M.mapOrElse (\_ -> Err [ "View " ++ id ++ " already exists" ])
                    (Ok (tables |> Dict.insert id (buildView tables statement view)))

        AlterTable (AddTableConstraint schema table (ParsedPrimaryKey constraintName pk)) ->
            updateTable statement (buildId schema table) (\t -> Ok { t | primaryKey = Just (SqlPrimaryKey (constraintName |> Maybe.withDefault (defaultPkName table)) pk statement) }) tables

        AlterTable (AddTableConstraint schema table (AlterTable.ParsedForeignKey constraint fk)) ->
            updateColumn statement (buildId schema table) fk.column (\c -> buildFk tables statement constraint fk.ref.schema fk.ref.table fk.ref.column |> Result.map (\r -> { c | foreignKey = Just r }) |> Result.mapError (\e -> [ e ])) tables

        AlterTable (AddTableConstraint schema table (ParsedUnique constraint unique)) ->
            updateTable statement (buildId schema table) (\t -> Ok { t | uniques = t.uniques ++ [ SqlUnique constraint unique.columns unique.definition statement ] }) tables

        AlterTable (AddTableConstraint schema table (ParsedCheck constraint check)) ->
            updateTable statement (buildId schema table) (\t -> Ok { t | checks = t.checks ++ [ SqlCheck constraint check.columns check.predicate statement ] }) tables

        AlterTable (AlterColumn schema table (ColumnDefault column default)) ->
            updateColumn statement (buildId schema table) column (\c -> Ok { c | default = Just default }) tables

        AlterTable (AlterColumn _ _ (ColumnStatistics _ _)) ->
            Ok tables

        AlterTable (AddTableOwner _ _ _) ->
            Ok tables

        AlterTable (AttachPartition _ _) ->
            Ok tables

        AlterTable (DropConstraint _ _ _) ->
            Ok tables

        CreateIndex index ->
            updateTable statement (buildId index.table.schema index.table.table) (\t -> Ok { t | indexes = t.indexes ++ [ SqlIndex index.name index.columns index.definition statement ] }) tables

        CreateUnique unique ->
            updateTable statement (buildId unique.table.schema unique.table.table) (\t -> Ok { t | uniques = t.uniques ++ [ SqlUnique unique.name unique.columns unique.definition statement ] }) tables

        TableComment comment ->
            updateTable statement (buildId comment.schema comment.table) (\table -> Ok { table | comment = Just (SqlComment comment.comment.text statement) }) tables

        ColumnComment comment ->
            updateColumn statement (buildId comment.schema comment.table) comment.column (\column -> Ok { column | comment = Just (SqlComment comment.comment.text statement) }) tables

        Ignored _ ->
            Ok tables


updateTable : SqlStatement -> SqlTableId -> (SqlTable -> Result (List SchemaError) SqlTable) -> SqlSchema -> Result (List SchemaError) SqlSchema
updateTable statement id transform tables =
    tables
        |> Dict.get id
        |> M.mapOrElse (\table -> transform table |> Result.map (\newTable -> tables |> Dict.update id (Maybe.map (\_ -> newTable))))
            (Err [ "Table " ++ id ++ " does not exist (in '" ++ buildRawSql statement ++ "')" ])


updateColumn : SqlStatement -> SqlTableId -> SqlColumnName -> (SqlColumn -> Result (List SchemaError) SqlColumn) -> SqlSchema -> Result (List SchemaError) SqlSchema
updateColumn statement id name transform tables =
    updateTable statement
        id
        (\table ->
            table.columns
                |> Nel.find (\column -> column.name == name)
                |> M.mapOrElse (\column -> transform column |> Result.map (\newColumn -> updateTableColumn name (\_ -> newColumn) table))
                    (Err [ "Column '" ++ name ++ "' does not exist in table " ++ id ++ " (in '" ++ buildRawSql statement ++ "')" ])
        )
        tables


updateTableColumn : SqlColumnName -> (SqlColumn -> SqlColumn) -> SqlTable -> SqlTable
updateTableColumn column transform table =
    { table
        | columns =
            table.columns
                |> Nel.map
                    (\c ->
                        if c.name == column then
                            transform c

                        else
                            c
                    )
    }


buildTable : SqlSchema -> SqlStatement -> ParsedTable -> Result (List SchemaError) SqlTable
buildTable tables statement table =
    table.columns
        |> Nel.toList
        |> List.map (buildColumn tables statement table)
        |> L.resultSeq
        |> Result.andThen (\cols -> cols |> Nel.fromList |> Result.fromMaybe [ "No valid column for table " ++ buildId table.schema table.table ])
        |> Result.map
            (\columns ->
                { schema = table.schema |> withDefaultSchema
                , table = table.table
                , view = False
                , columns = columns
                , primaryKey =
                    table.primaryKey
                        |> Maybe.map (\pk -> SqlPrimaryKey (pk.name |> Maybe.withDefault (defaultPkName table.table)) pk.columns statement)
                        |> M.orElse (table.columns |> Nel.filterMap (\c -> c.primaryKey |> Maybe.map (\pk -> SqlPrimaryKey pk (Nel c.name []) statement)) |> List.head)
                , uniques = table.uniques |> List.map (\i -> SqlUnique i.name i.columns i.definition statement)
                , indexes = table.indexes |> List.map (\i -> SqlIndex i.name i.columns i.definition statement)
                , checks =
                    (table.checks |> List.map (\i -> SqlCheck i.name i.columns i.predicate statement))
                        ++ (table.columns |> Nel.toList |> List.filterMap (\c -> c.check |> Maybe.map (\p -> SqlCheck (defaultCheckName table.table c.name) [ c.name ] p statement)))
                , source = statement
                , comment = Nothing
                }
            )


buildColumn : SqlSchema -> SqlStatement -> ParsedTable -> ParsedColumn -> Result SchemaError SqlColumn
buildColumn tables statement table column =
    column.foreignKey
        |> M.orElse (table.foreignKeys |> List.filter (\fk -> fk.src == column.name) |> List.head |> Maybe.map (\fk -> ( fk.name |> Maybe.withDefault (defaultFkName table.table column.name), fk.ref )))
        |> Maybe.map (\( fk, ref ) -> buildFk tables statement fk ref.schema ref.table ref.column)
        |> M.resultSeq
        |> Result.map
            (\fk ->
                { name = column.name
                , kind = column.kind
                , nullable = column.nullable
                , default = column.default
                , foreignKey = fk
                , comment = Nothing
                , source = statement
                }
            )


buildFk : SqlSchema -> SqlStatement -> SqlConstraintName -> Maybe SqlSchemaName -> SqlTableName -> Maybe SqlColumnName -> Result SchemaError SqlForeignKey
buildFk tables statement constraint schema table column =
    column
        |> withPkColumn tables schema table
        |> Result.map
            (\col ->
                { name = constraint
                , schema = schema |> withDefaultSchema
                , table = table
                , column = col
                , source = statement
                }
            )


withPkColumn : SqlSchema -> Maybe SqlSchemaName -> SqlTableName -> Maybe SqlColumnName -> Result SchemaError SqlColumnName
withPkColumn tables schema table name =
    case name of
        Just n ->
            Ok n

        Nothing ->
            tables
                |> Dict.get (buildId schema table)
                |> M.mapOrElse
                    (\t ->
                        case t.primaryKey |> Maybe.map .columns of
                            Just cols ->
                                if List.isEmpty cols.tail then
                                    Ok cols.head

                                else
                                    Err ("Table " ++ buildId schema table ++ " has a primary key with more than one column (" ++ String.join ", " (Nel.toList cols) ++ ")")

                            Nothing ->
                                Err ("No primary key on table " ++ buildId schema table)
                    )
                    (Err ("Table " ++ buildId schema table ++ " does not exist (yet)"))


buildView : SqlSchema -> SqlStatement -> ParsedView -> SqlTable
buildView tables statement view =
    { schema = view.schema |> withDefaultSchema
    , table = view.table
    , view = True
    , columns = view.select.columns |> Nel.map (buildViewColumn tables statement)
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , source = statement
    , comment = Nothing
    }


buildViewColumn : SqlSchema -> SqlStatement -> SelectColumn -> SqlColumn
buildViewColumn tables statement column =
    case column of
        BasicColumn c ->
            c.table
                -- FIXME should handle table alias (when table is renamed in select)
                |> Maybe.andThen (\t -> tables |> Dict.get (buildId Nothing t))
                |> Maybe.andThen (\t -> t.columns |> Nel.find (\col -> col.name == c.column))
                |> M.mapOrElse
                    (\col ->
                        { col
                            | name = c.alias |> Maybe.withDefault c.column
                            , default = Just ((c.table |> M.mapOrElse (\t -> t ++ ".") "") ++ c.column)
                        }
                    )
                    { name = c.alias |> Maybe.withDefault c.column
                    , kind = "unknown"
                    , nullable = False
                    , default = Just ((c.table |> M.mapOrElse (\t -> t ++ ".") "") ++ c.column)
                    , foreignKey = Nothing
                    , comment = Nothing
                    , source = statement
                    }

        ComplexColumn c ->
            { name = c.alias
            , kind = "unknown"
            , nullable = False
            , default = Just c.formula
            , foreignKey = Nothing
            , comment = Nothing
            , source = statement
            }


buildId : Maybe SqlSchemaName -> SqlTableName -> SqlTableId
buildId schema table =
    withDefaultSchema schema ++ "." ++ table


withDefaultSchema : Maybe SqlSchemaName -> SqlSchemaName
withDefaultSchema schema =
    schema |> Maybe.withDefault defaultSchema


buildStatements : List SqlLine -> List SqlStatement
buildStatements lines =
    lines
        |> List.filter
            (\line ->
                not
                    (String.isEmpty (String.trim line.text)
                        || String.startsWith "--" (String.trim line.text)
                        || String.startsWith "#" (String.trim line.text)
                        || hasOnlyComment line
                    )
            )
        |> List.foldr
            (\line ( currentStatementLines, statements, nestedBlock ) ->
                case
                    ( ( (line |> hasKeyword "BEGIN") || (line |> hasKeyword "CASE")
                      , line |> hasKeyword "END"
                      )
                    , ( line.text |> String.endsWith ";"
                      , nestedBlock
                      )
                    )
                of
                    ( ( True, _ ), ( False, _ ) ) ->
                        ( line :: currentStatementLines, statements, max (nestedBlock - 1) 0 )

                    ( ( _, True ), ( False, _ ) ) ->
                        ( line :: currentStatementLines, statements, nestedBlock + 1 )

                    ( ( _, True ), ( True, _ ) ) ->
                        ( line :: [], addStatement currentStatementLines statements, nestedBlock + 1 )

                    ( _, ( True, 0 ) ) ->
                        ( line :: [], addStatement currentStatementLines statements, nestedBlock )

                    _ ->
                        ( line :: currentStatementLines, statements, nestedBlock )
            )
            ( [], [], 0 )
        |> (\( cur, res, _ ) -> addStatement cur res)
        |> List.filter (\s -> not (statementIsEmpty s))


hasKeyword : String -> SqlLine -> Bool
hasKeyword keyword line =
    (line.text |> R.contains ("[^A-Z_]" ++ keyword ++ "([^A-Z_]|$)")) && not (line.text |> R.contains ("'.*" ++ keyword ++ ".*'"))


hasOnlyComment : SqlLine -> Bool
hasOnlyComment line =
    case line.text |> R.matches "^/\\*(.*)\\*/;$" of
        _ :: [] ->
            True

        _ ->
            False


addStatement : List SqlLine -> List SqlStatement -> List SqlStatement
addStatement lines statements =
    case lines of
        [] ->
            statements

        head :: tail ->
            { head = head, tail = tail } :: statements


statementIsEmpty : SqlStatement -> Bool
statementIsEmpty statement =
    statement.head.text == ";"


buildSqlLines : List FileLineContent -> List SqlLine
buildSqlLines lines =
    lines |> List.indexedMap (\i line -> { line = i, text = line })
