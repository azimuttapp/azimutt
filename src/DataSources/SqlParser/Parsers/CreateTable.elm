module DataSources.SqlParser.Parsers.CreateTable exposing (ParsedCheck, ParsedColumn, ParsedForeignKey, ParsedIndex, ParsedPrimaryKey, ParsedTable, ParsedUnique, parseCreateTable, parseCreateTableColumn, parseCreateTableColumnForeignKey, parseCreateTableForeignKey, parseCreateTableKey)

import DataSources.Helpers exposing (defaultUniqueName)
import DataSources.SqlParser.Parsers.AlterTable as AlterTable exposing (TableConstraint(..), parseAlterTableAddConstraint)
import DataSources.SqlParser.Utils.Helpers exposing (buildColumnName, buildColumnType, buildComment, buildConstraintName, buildRawSql, buildSchemaName, buildSqlLine, buildTableName, commaSplit, sqlTriggers)
import DataSources.SqlParser.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlColumnType, SqlColumnValue, SqlComment, SqlConstraintName, SqlForeignKeyRef, SqlPredicate, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Libs.Result as Result
import Libs.String as String
import Regex


type alias ParsedTable =
    { schema : Maybe SqlSchemaName
    , table : SqlTableName
    , columns : Nel ParsedColumn
    , primaryKey : Maybe ParsedPrimaryKey
    , foreignKeys : List ParsedForeignKey
    , uniques : List ParsedUnique
    , indexes : List ParsedIndex
    , checks : List ParsedCheck
    }


type alias ParsedColumn =
    { name : SqlColumnName
    , kind : SqlColumnType
    , nullable : Bool
    , default : Maybe SqlColumnValue
    , primaryKey : Maybe SqlConstraintName
    , foreignKey : Maybe ( Maybe SqlConstraintName, SqlForeignKeyRef )
    , unique : Maybe String
    , check : Maybe SqlPredicate
    , comment : Maybe SqlComment
    }


type alias ParsedPrimaryKey =
    { name : Maybe SqlConstraintName, columns : Nel SqlColumnName }


type alias ParsedForeignKey =
    { name : Maybe SqlConstraintName, src : SqlColumnName, ref : SqlForeignKeyRef }


type alias ParsedUnique =
    { name : SqlConstraintName, columns : Nel SqlColumnName, definition : String }


type alias ParsedIndex =
    { name : SqlConstraintName, columns : Nel SqlColumnName, definition : String }


type alias ParsedCheck =
    { name : SqlConstraintName, columns : List SqlColumnName, predicate : SqlPredicate }


parseCreateTable : SqlStatement -> Result (List ParseError) ParsedTable
parseCreateTable statement =
    -- TODO: handle https://www.postgresql.org/docs/current/ddl-inherit.html
    case statement |> buildSqlLine |> Regex.matches "^CREATE(?:\\s+UNLOGGED)? TABLE(?:\\s+IF NOT EXISTS)?\\s+(?:(?<db>[^ .]+)\\.)?(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .]+)\\s*(?<rest>\\(.+\\).*);$" of
        db :: schema :: (Just table) :: (Just rest) :: [] ->
            let
                schemaName : Maybe SqlSchemaName
                schemaName =
                    schema |> Maybe.orElse db |> Maybe.map buildSchemaName

                tableName : SqlTableName
                tableName =
                    table |> buildTableName

                ( constraints, columns ) =
                    (rest |> extractBody |> Tuple.first |> commaSplit |> List.map String.trim |> List.filter String.nonEmpty)
                        |> List.partition (\col -> col |> String.toUpper |> (\colUp -> [ "CONSTRAINT ", "PRIMARY KEY ", "FOREIGN KEY", "UNIQUE KEY ", "KEY `" ] |> List.any (\cons -> colUp |> String.startsWith cons)))
            in
            Result.map6
                (\cols pk fks uniques indexes parsedConstraints ->
                    { schema = schemaName
                    , table = tableName
                    , columns = cols
                    , primaryKey = (pk ++ (parsedConstraints |> List.filterMap primaryKeyConstraints)) |> List.head
                    , foreignKeys = fks ++ (parsedConstraints |> List.filterMap foreignKeyConstraints)
                    , uniques = uniques ++ (cols |> Nel.filterMap (columnUniqueKey tableName)) ++ (parsedConstraints |> List.filterMap uniqueKeyConstraints)
                    , indexes = indexes
                    , checks = parsedConstraints |> List.filterMap checkConstraints
                    }
                )
                (columns |> List.map parseCreateTableColumn |> List.resultSeq |> Result.andThen (\cols -> cols |> Nel.fromList |> Result.fromMaybe [ "Create table can't have empty columns" ]))
                (constraints |> List.filter (String.toUpper >> String.startsWith "PRIMARY KEY") |> List.map parseCreateTablePrimaryKey |> List.resultSeq)
                (constraints |> List.filter (String.toUpper >> String.startsWith "FOREIGN KEY") |> List.map parseCreateTableForeignKey |> List.resultSeq)
                (constraints |> List.filter (String.toUpper >> String.startsWith "UNIQUE KEY") |> List.map parseCreateTableUniqueKey |> List.resultSeq)
                (constraints |> List.filter (String.toUpper >> String.startsWith "KEY") |> List.map parseCreateTableKey |> List.resultSeq)
                (constraints |> List.filter (String.toUpper >> String.startsWith "CONSTRAINT") |> List.map (\c -> ("ADD " ++ c) |> parseAlterTableAddConstraint) |> List.resultSeq |> Result.mapError (\errs -> errs |> List.concatMap identity))

        _ ->
            Err [ "Can't parse table: '" ++ buildRawSql statement ++ "'" ]


extractBody : String -> ( String, String )
extractBody rest =
    rest
        |> String.foldl
            (\char ( body, options, ( nesting, isBody ) ) ->
                if not isBody then
                    ( body, char :: options, ( nesting, isBody ) )

                else if char == '(' && List.isEmpty body then
                    ( body, options, ( nesting, True ) )

                else if char == '(' then
                    ( char :: body, options, ( char :: nesting, isBody ) )

                else if char == ')' && List.isEmpty nesting then
                    ( body, options, ( nesting, False ) )

                else if char == ')' then
                    ( char :: body, options, ( nesting |> List.tail |> Maybe.withDefault [], isBody ) )

                else
                    ( char :: body, options, ( nesting, isBody ) )
            )
            ( [], [], ( [], True ) )
        |> (\( body, options, _ ) -> ( body |> List.reverse |> String.fromList, options |> List.reverse |> String.fromList |> String.trim ))


parseCreateTableColumn : RawSql -> Result ParseError ParsedColumn
parseCreateTableColumn sql =
    case sql |> Regex.matches "^(?<name>[^ ]+)\\s+(?<type>.*?)(?:\\s+COLLATE [^ ]+)?(?:\\s+DEFAULT\\s+(?<default1>.*?))?(?<nullable>\\s+NOT NULL)?(?:\\s+COLLATE [^ ]+)?(?:\\s+DEFAULT\\s+(?<default2>.*?))?(?:\\s+CONSTRAINT\\s+(?<constraint>.*))?(?:\\s+(?<reference>REFERENCES\\s+.*?))?(?: AUTO_INCREMENT)?( PRIMARY KEY)?( UNIQUE)?(?: CHECK\\((?<check>.*?)\\))?( GENERATED .*?)?(?: COMMENT '(?<comment>(?:[^']|'')+)')?$" of
        (Just name) :: (Just kind) :: default1 :: nullable :: default2 :: maybeConstraints :: maybeReference :: maybePrimary :: maybeUnique :: maybeCheck :: maybeGenerated :: maybeComment :: [] ->
            maybeConstraints
                |> Maybe.mapOrElse (Regex.split (Regex.asRegexI " *constraint *")) []
                |> (\constraints -> constraints ++ List.filterMap identity [ maybeReference, maybePrimary ])
                |> List.foldl
                    (\constraint acc ->
                        acc
                            |> Result.andThen
                                (\( primary, foreign, null ) ->
                                    if constraint |> String.toUpper |> String.contains "PRIMARY KEY" then
                                        parseCreateTableColumnPrimaryKey constraint |> Result.map (\pk -> ( Just pk, foreign, null ))

                                    else if constraint |> String.toUpper |> String.contains "REFERENCES" then
                                        parseCreateTableColumnForeignKey constraint |> Result.map (\fk -> ( primary, Just fk, null ))

                                    else if constraint |> String.toUpper |> String.contains "NOT NULL" then
                                        Ok ( primary, foreign, False )

                                    else
                                        Err ("Constraint not handled: '" ++ constraint ++ "' in create table")
                                )
                    )
                    (Ok ( Nothing, Nothing, True ))
                |> Result.map
                    (\( primaryKey, foreignKey, nullable2 ) ->
                        { name = name |> buildColumnName
                        , kind = kind |> buildColumnType
                        , nullable = nullable == Nothing && nullable2
                        , default = default1 |> Maybe.orElse default2 |> Maybe.orElse (maybeGenerated |> Maybe.map String.trim)
                        , primaryKey = primaryKey
                        , foreignKey = foreignKey
                        , unique = maybeUnique |> Maybe.map String.trim
                        , check = maybeCheck
                        , comment = maybeComment |> Maybe.map buildComment
                        }
                    )

        _ ->
            Err ("Can't parse column: '" ++ sql ++ "'")


parseCreateTableColumnPrimaryKey : RawSql -> Result ParseError SqlConstraintName
parseCreateTableColumnPrimaryKey constraint =
    case constraint |> Regex.matches "^(?<constraint>[^ ]+)?\\s+PRIMARY KEY$" of
        constraintName :: [] ->
            Ok (constraintName |> Maybe.withDefault "")

        _ ->
            Err ("Can't parse primary key: '" ++ constraint ++ "' in create table")


parseCreateTableColumnForeignKey : RawSql -> Result ParseError ( Maybe SqlConstraintName, SqlForeignKeyRef )
parseCreateTableColumnForeignKey constraint =
    case constraint |> Regex.matches "^(?<constraint>[^ ]+)\\s+REFERENCES\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .]+)(?:\\.(?<column>[^ .]+))?$" of
        constraintName :: (Just table) :: (Just column) :: Nothing :: [] ->
            Ok ( constraintName, { schema = Nothing, table = table |> buildTableName, column = Just (column |> buildColumnName) } )

        constraintName :: schema :: (Just table) :: column :: [] ->
            Ok ( constraintName, { schema = schema |> Maybe.map buildSchemaName, table = table |> buildTableName, column = column |> Maybe.map buildColumnName } )

        _ ->
            case constraint |> Regex.matches ("^(?:(?<constraint>[^ ]+)\\s+)?REFERENCES\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .(]+)(?:\\s*\\((?<column>[^ .]+)\\))?" ++ sqlTriggers ++ "$") of
                constraintName :: schema :: (Just table) :: column :: [] ->
                    Ok ( constraintName, { schema = schema |> Maybe.map buildSchemaName, table = table |> buildTableName, column = column |> Maybe.map buildColumnName } )

                _ ->
                    Err ("Can't parse foreign key: '" ++ constraint ++ "' in create table")


parseCreateTablePrimaryKey : RawSql -> Result ParseError ParsedPrimaryKey
parseCreateTablePrimaryKey sql =
    case sql |> Regex.matches "^PRIMARY KEY \\((?<columns>[^)]+)\\)(?:\\s+USING [^ ]+)?$" of
        (Just columns) :: [] ->
            columns
                |> String.split ","
                |> List.map buildColumnName
                |> Nel.fromList
                |> Maybe.map (\cols -> { name = Nothing, columns = cols })
                |> Result.fromMaybe "Primary key can't have no column"

        _ ->
            Err ("Can't parse table primary key: '" ++ sql ++ "'")


parseCreateTableForeignKey : RawSql -> Result ParseError ParsedForeignKey
parseCreateTableForeignKey sql =
    case sql |> Regex.matches ("^FOREIGN KEY\\s*\\((?<src>[^)]+)\\)\\s*REFERENCES\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .(]+)\\s*\\((?<column>[^ .)]+)\\)" ++ sqlTriggers ++ "$") of
        (Just src) :: schema :: (Just table) :: (Just column) :: [] ->
            Ok { name = Nothing, src = src |> buildColumnName, ref = { schema = schema |> Maybe.map buildSchemaName, table = table |> buildTableName, column = Just (column |> buildColumnName) } }

        _ ->
            Err ("Can't parse table foreign key: '" ++ sql ++ "'")


parseCreateTableUniqueKey : RawSql -> Result ParseError ParsedUnique
parseCreateTableUniqueKey sql =
    case sql |> Regex.matches "^UNIQUE KEY (?<name>[^ ]+) \\((?<columns>[^)]+)\\)(?:\\s+USING [^ ]+)?$" of
        (Just name) :: (Just columns) :: [] ->
            columns
                |> String.split ","
                |> List.map buildColumnName
                |> Nel.fromList
                |> Result.fromMaybe "Unique key can't have no column"
                |> Result.map (\cols -> { name = name |> buildConstraintName, columns = cols, definition = sql })

        _ ->
            Err ("Can't parse table unique key: '" ++ sql ++ "'")


parseCreateTableKey : RawSql -> Result ParseError ParsedIndex
parseCreateTableKey sql =
    case sql |> Regex.matches "^KEY (?<name>[^ ]+) \\((?<columns>.+)\\)(?:\\s+USING [^ ]+)?$" of
        (Just name) :: (Just columns) :: [] ->
            columns
                |> String.split ","
                |> List.map buildColumnName
                |> Nel.fromList
                |> Result.fromMaybe "Key can't have no column"
                |> Result.map (\cols -> { name = name |> buildConstraintName, columns = cols, definition = sql })

        _ ->
            Err ("Can't parse table key: '" ++ sql ++ "'")


primaryKeyConstraints : TableConstraint -> Maybe ParsedPrimaryKey
primaryKeyConstraints constraint =
    case constraint of
        AlterTable.ParsedPrimaryKey name columns ->
            Just { name = name, columns = columns }

        _ ->
            Nothing


foreignKeyConstraints : TableConstraint -> Maybe ParsedForeignKey
foreignKeyConstraints constraint =
    case constraint of
        AlterTable.ParsedForeignKey name fks ->
            -- FIXME: handle multi-column foreign key!
            Just { name = name, src = fks.head.column, ref = fks.head.ref }

        _ ->
            Nothing


uniqueKeyConstraints : TableConstraint -> Maybe ParsedUnique
uniqueKeyConstraints constraint =
    case constraint of
        AlterTable.ParsedUnique name { columns, definition } ->
            Just { name = name, columns = columns, definition = definition }

        _ ->
            Nothing


checkConstraints : TableConstraint -> Maybe ParsedCheck
checkConstraints constraint =
    case constraint of
        AlterTable.ParsedCheck name { columns, predicate } ->
            Just { name = name, columns = columns, predicate = predicate }

        _ ->
            Nothing


columnUniqueKey : SqlTableName -> ParsedColumn -> Maybe ParsedUnique
columnUniqueKey table col =
    col.unique |> Maybe.map (\u -> { name = defaultUniqueName table col.name, columns = Nel col.name [], definition = u })
