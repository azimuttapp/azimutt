module DataSources.SqlParser.FileParser exposing (SchemaError, SqlCheck, SqlColumn, SqlForeignKey, SqlIndex, SqlPrimaryKey, SqlSchema, SqlTable, SqlTableId, SqlUnique, buildStatements, parseLines, parseSchema, updateColumn, updateTable)

import DataSources.SqlParser.Parsers.AlterTable exposing (ColumnUpdate(..), TableConstraint(..), TableUpdate(..))
import DataSources.SqlParser.Parsers.Comment exposing (SqlComment)
import DataSources.SqlParser.Parsers.CreateTable exposing (ParsedColumn, ParsedTable)
import DataSources.SqlParser.Parsers.CreateView exposing (ParsedView)
import DataSources.SqlParser.Parsers.Select exposing (SelectColumn(..))
import DataSources.SqlParser.StatementParser exposing (Command(..), parseCommand)
import DataSources.SqlParser.Utils.Types exposing (SqlColumnName, SqlColumnType, SqlColumnValue, SqlConstraintName, SqlLine, SqlPredicate, SqlSchemaName, SqlStatement, SqlTableName)
import Dict exposing (Dict)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (FileContent, FileName)
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
    }


type alias SqlPrimaryKey =
    { name : SqlConstraintName, columns : Nel SqlColumnName }


type alias SqlForeignKey =
    { name : SqlConstraintName, schema : SqlSchemaName, table : SqlTableName, column : SqlColumnName }


type alias SqlUnique =
    { name : SqlConstraintName, columns : Nel SqlColumnName, definition : String }


type alias SqlIndex =
    { name : SqlConstraintName, columns : Nel SqlColumnName, definition : String }


type alias SqlCheck =
    { name : SqlConstraintName, predicate : SqlPredicate }


defaultSchema : String
defaultSchema =
    "public"


parseSchema : FileName -> FileContent -> ( List SchemaError, SqlSchema )
parseSchema fileName fileContent =
    parseLines fileName fileContent
        |> buildStatements
        |> List.foldl
            (\statement ( errs, schema ) ->
                case statement |> parseCommand |> Result.andThen (\command -> schema |> evolve command) of
                    Ok newSchema ->
                        ( errs, newSchema )

                    Err e ->
                        ( errs ++ e, schema )
            )
            ( [], Dict.empty )


evolve : Command -> SqlSchema -> Result (List SchemaError) SqlSchema
evolve command tables =
    case command of
        CreateTable table ->
            let
                id : SqlTableId
                id =
                    buildId table.schema table.table
            in
            tables
                |> Dict.get id
                |> Maybe.map (\_ -> Err [ "Table " ++ id ++ " already exists" ])
                |> Maybe.withDefault (buildTable tables table |> Result.map (\sqlTable -> tables |> Dict.insert id sqlTable))

        CreateView view ->
            let
                id : SqlTableId
                id =
                    buildId view.schema view.table
            in
            tables
                |> Dict.get id
                |> Maybe.map (\_ -> Err [ "View " ++ id ++ " already exists" ])
                |> Maybe.withDefault (Ok (tables |> Dict.insert id (buildView view)))

        AlterTable (AddTableConstraint schema table (ParsedPrimaryKey constraint pk)) ->
            updateTable (buildId schema table) (\t -> Ok { t | primaryKey = Just { name = constraint, columns = pk } }) tables

        AlterTable (AddTableConstraint schema table (ParsedForeignKey constraint fk)) ->
            updateColumn (buildId schema table) fk.column (\c -> buildFk tables constraint fk.ref.schema fk.ref.table fk.ref.column |> Result.map (\r -> { c | foreignKey = Just r }) |> Result.mapError (\e -> [ e ])) tables

        AlterTable (AddTableConstraint schema table (ParsedUnique constraint unique)) ->
            updateTable (buildId schema table) (\t -> Ok { t | uniques = t.uniques ++ [ { name = constraint, columns = unique.columns, definition = unique.definition } ] }) tables

        AlterTable (AddTableConstraint schema table (ParsedCheck constraint check)) ->
            updateTable (buildId schema table) (\t -> Ok { t | checks = t.checks ++ [ { name = constraint, predicate = check } ] }) tables

        AlterTable (AlterColumn schema table (ColumnDefault column default)) ->
            updateColumn (buildId schema table) column (\c -> Ok { c | default = Just default }) tables

        AlterTable (AlterColumn _ _ (ColumnStatistics _ _)) ->
            Ok tables

        AlterTable (AddTableOwner _ _ _) ->
            Ok tables

        CreateIndex index ->
            updateTable (buildId index.table.schema index.table.table) (\t -> Ok { t | indexes = t.indexes ++ [ { name = index.name, columns = index.columns, definition = index.definition } ] }) tables

        CreateUnique unique ->
            updateTable (buildId unique.table.schema unique.table.table) (\t -> Ok { t | uniques = t.uniques ++ [ { name = unique.name, columns = unique.columns, definition = unique.definition } ] }) tables

        TableComment comment ->
            updateTable (buildId comment.schema comment.table) (\table -> Ok { table | comment = Just comment.comment }) tables

        ColumnComment comment ->
            updateColumn (buildId comment.schema comment.table) comment.column (\column -> Ok { column | comment = Just comment.comment }) tables

        Ignored _ ->
            Ok tables


updateTable : SqlTableId -> (SqlTable -> Result (List SchemaError) SqlTable) -> SqlSchema -> Result (List SchemaError) SqlSchema
updateTable id transform tables =
    tables
        |> Dict.get id
        |> Maybe.map (\table -> transform table |> Result.map (\newTable -> tables |> Dict.update id (Maybe.map (\_ -> newTable))))
        |> Maybe.withDefault (Err [ "Table " ++ id ++ " does not exist" ])


updateColumn : SqlTableId -> SqlColumnName -> (SqlColumn -> Result (List SchemaError) SqlColumn) -> SqlSchema -> Result (List SchemaError) SqlSchema
updateColumn id name transform tables =
    updateTable id
        (\table ->
            table.columns
                |> Nel.find (\column -> column.name == name)
                |> Maybe.map (\column -> transform column |> Result.map (\newColumn -> updateTableColumn name (\_ -> newColumn) table))
                |> Maybe.withDefault (Err [ "Column '" ++ name ++ "' does not exist in table " ++ id ])
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


buildTable : SqlSchema -> ParsedTable -> Result (List SchemaError) SqlTable
buildTable tables table =
    table.columns
        |> Nel.toList
        |> List.map (buildColumn tables)
        |> L.resultSeq
        |> Result.andThen (\cols -> cols |> Nel.fromList |> Result.fromMaybe [ "No valid column for table " ++ buildId table.schema table.table ])
        |> Result.map
            (\columns ->
                { schema = table.schema |> withDefaultSchema
                , table = table.table
                , columns = columns
                , primaryKey = table.primaryKey |> M.orElse (table.columns |> Nel.filterMap (\c -> c.primaryKey |> Maybe.map (\pk -> { name = pk, columns = Nel c.name [] })) |> List.head)
                , uniques = table.uniques
                , indexes = table.indexes
                , checks = table.checks
                , source = table.source
                , comment = Nothing
                }
            )


buildColumn : SqlSchema -> ParsedColumn -> Result SchemaError SqlColumn
buildColumn tables column =
    column.foreignKey
        |> Maybe.map (\( fk, ref ) -> buildFk tables fk ref.schema ref.table ref.column)
        |> M.resultSeq
        |> Result.map
            (\fk ->
                { name = column.name
                , kind = column.kind
                , nullable = column.nullable
                , default = column.default
                , foreignKey = fk
                , comment = Nothing
                }
            )


buildFk : SqlSchema -> SqlConstraintName -> Maybe SqlSchemaName -> SqlTableName -> Maybe SqlColumnName -> Result SchemaError SqlForeignKey
buildFk tables constraint schema table column =
    column
        |> withPkColumn tables schema table
        |> Result.map
            (\col ->
                { name = constraint
                , schema = schema |> withDefaultSchema
                , table = table
                , column = col
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
                |> Maybe.map
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
                |> Maybe.withDefault (Err ("Table " ++ buildId schema table ++ " does not exist (yet)"))


buildView : ParsedView -> SqlTable
buildView view =
    { schema = view.schema |> withDefaultSchema
    , table = view.table
    , columns = view.select.columns |> Nel.map buildViewColumn
    , primaryKey = Nothing
    , uniques = []
    , indexes = []
    , checks = []
    , source = view.source
    , comment = Nothing
    }


buildViewColumn : SelectColumn -> SqlColumn
buildViewColumn column =
    case column of
        BasicColumn c ->
            { name = c.alias |> Maybe.withDefault c.column
            , kind = "unknown"
            , nullable = False
            , default = Nothing
            , foreignKey = Nothing
            , comment = Nothing
            }

        ComplexColumn c ->
            { name = c.alias
            , kind = "unknown"
            , nullable = False
            , default = Nothing
            , foreignKey = Nothing
            , comment = Nothing
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
        |> List.filter (\line -> not (String.isEmpty (String.trim line.text) || String.startsWith "--" line.text || hasOnlyComment line))
        |> List.foldr
            (\line ( currentStatementLines, statements, nestedBlock ) ->
                if (line.text |> String.trim |> String.toUpper) == "BEGIN" then
                    ( line :: currentStatementLines, statements, nestedBlock + 1 )

                else if (line.text |> String.trim |> String.toUpper) == "END" || (line.text |> String.trim |> String.toUpper) == "END;" then
                    ( line :: currentStatementLines, statements, nestedBlock - 1 )

                else if (line.text |> String.endsWith ";") && nestedBlock == 0 then
                    ( line :: [], addStatement currentStatementLines statements, nestedBlock )

                else
                    ( line :: currentStatementLines, statements, nestedBlock )
            )
            ( [], [], 0 )
        |> (\( cur, res, _ ) -> addStatement cur res)
        |> List.filter (\s -> not (statementIsEmpty s))


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


parseLines : FileName -> FileContent -> List SqlLine
parseLines fileName fileContent =
    fileContent
        |> String.split "\n"
        |> List.indexedMap (\i line -> { file = fileName, line = i + 1, text = line })
