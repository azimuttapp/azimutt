module DataSources.SqlParser.Parsers.AlterTable exposing (CheckInner, ColumnUpdate(..), ForeignKeyInner, PrimaryKeyInner, SqlUser, TableConstraint(..), TableUpdate(..), UniqueInner, parseAlterTable, parseAlterTableAddConstraint, parseAlterTableAddConstraintForeignKey)

import DataSources.SqlParser.Utils.Helpers exposing (buildColumnName, buildConstraintName, buildRawSql, buildSchemaName, buildSqlLine, buildTableName, parseIndexDefinition)
import DataSources.SqlParser.Utils.Types exposing (ParseError, RawSql, SqlColumnName, SqlColumnValue, SqlConstraintName, SqlForeignKeyRef, SqlPredicate, SqlSchemaName, SqlStatement, SqlTableName)
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex


type TableUpdate
    = AddTableConstraint (Maybe SqlSchemaName) SqlTableName TableConstraint
    | AlterColumn (Maybe SqlSchemaName) SqlTableName ColumnUpdate
    | AddTableOwner (Maybe SqlSchemaName) SqlTableName SqlUser
    | AttachPartition (Maybe SqlSchemaName) SqlTableName
    | DropConstraint (Maybe SqlSchemaName) SqlTableName SqlConstraintName


type TableConstraint
    = ParsedPrimaryKey (Maybe SqlConstraintName) PrimaryKeyInner
    | ParsedForeignKey SqlConstraintName ForeignKeyInner
    | ParsedUnique SqlConstraintName UniqueInner
    | ParsedCheck SqlConstraintName CheckInner


type alias PrimaryKeyInner =
    Nel SqlColumnName


type alias ForeignKeyInner =
    { column : SqlColumnName, ref : SqlForeignKeyRef }


type alias UniqueInner =
    { columns : Nel SqlColumnName, definition : String }


type alias CheckInner =
    { columns : List SqlColumnName, predicate : SqlPredicate }


type ColumnUpdate
    = ColumnDefault SqlColumnName SqlColumnValue
    | ColumnStatistics SqlColumnName Int


type alias SqlUser =
    String


parseAlterTable : SqlStatement -> Result (List ParseError) TableUpdate
parseAlterTable statement =
    case statement |> buildSqlLine |> Regex.matches "^ALTER TABLE(?:\\s+ONLY)?(?:\\s+IF EXISTS)?\\s+(?:(?<schema>[^ .]+)\\.)?(?<table>[^ .]+)\\s+(?<command>.*);$" of
        schema :: (Just table) :: (Just command) :: [] ->
            -- FIXME manage multiple commands, ex: "ADD PRIMARY KEY (`id`), ADD KEY `IDX_ABC` (`user_id`), ADD KEY `IDX_DEF` (`event_id`)"
            -- TODO try to merge "ADD PRIMARY KEY" with "ADD CONSTRAINT" (make CONSTRAINT optional)
            let
                schemaName : Maybe SqlSchemaName
                schemaName =
                    schema |> Maybe.map buildSchemaName

                tableName : SqlTableName
                tableName =
                    table |> buildTableName
            in
            if command |> String.toUpper |> String.startsWith "ADD PRIMARY KEY " then
                parseAlterTableAddConstraintPrimaryKey (command |> String.dropLeft 4) |> Result.map (\r -> AddTableConstraint schemaName tableName (ParsedPrimaryKey Nothing r))

            else if command |> String.toUpper |> String.startsWith "ADD CONSTRAINT " then
                parseAlterTableAddConstraint command |> Result.map (AddTableConstraint schemaName tableName)

            else if command |> String.toUpper |> String.startsWith "ALTER COLUMN " then
                parseAlterTableAlterColumn command |> Result.map (AlterColumn schemaName tableName)

            else if command |> String.toUpper |> String.startsWith "OWNER TO " then
                parseAlterTableOwnerTo command |> Result.map (AddTableOwner schemaName tableName)

            else if command |> String.toUpper |> String.startsWith "ATTACH PARTITION " then
                Ok (AttachPartition schemaName tableName)

            else if command |> String.toUpper |> String.startsWith "DROP CONSTRAINT " then
                parseAlterTableDropConstraint command |> Result.map (DropConstraint schemaName tableName)

            else
                Err [ "Command not handled: '" ++ command ++ "'" ]

        _ ->
            Err [ "Can't parse alter table: '" ++ buildRawSql statement ++ "'" ]


parseAlterTableAddConstraint : RawSql -> Result (List ParseError) TableConstraint
parseAlterTableAddConstraint command =
    case command |> Regex.matches ("^ADD CONSTRAINT\\s+(?<name>[^ ]+)\\s+(?<constraint>.*?)(?:\\s+match simple)?" ++ sqlTriggers ++ "$") of
        (Just name) :: (Just constraint) :: [] ->
            if constraint |> String.toUpper |> String.startsWith "PRIMARY KEY" then
                parseAlterTableAddConstraintPrimaryKey constraint |> Result.map (ParsedPrimaryKey (Just (name |> buildConstraintName)))

            else if constraint |> String.toUpper |> String.startsWith "FOREIGN KEY" then
                parseAlterTableAddConstraintForeignKey constraint |> Result.map (ParsedForeignKey (name |> buildConstraintName))

            else if constraint |> String.toUpper |> String.startsWith "UNIQUE" then
                parseAlterTableAddConstraintUnique constraint |> Result.map (ParsedUnique (name |> buildConstraintName))

            else if constraint |> String.toUpper |> String.startsWith "CHECK" then
                parseAlterTableAddConstraintCheck constraint |> Result.map (ParsedCheck (name |> buildConstraintName))

            else
                Err [ "Constraint not handled: '" ++ constraint ++ "'" ]

        _ ->
            Err [ "Can't parse add constraint: '" ++ command ++ "'" ]


parseAlterTableAddConstraintPrimaryKey : RawSql -> Result (List ParseError) PrimaryKeyInner
parseAlterTableAddConstraintPrimaryKey constraint =
    case constraint |> Regex.matches "^PRIMARY KEY\\s*\\((?<columns>[^)]+)\\)$" of
        (Just columns) :: [] ->
            columns |> String.split "," |> List.map buildColumnName |> Nel.fromList |> Result.fromMaybe [ "Primary key can't have empty columns" ]

        _ ->
            Err [ "Can't parse primary key: '" ++ constraint ++ "'" ]


parseAlterTableAddConstraintForeignKey : RawSql -> Result (List ParseError) ForeignKeyInner
parseAlterTableAddConstraintForeignKey constraint =
    let
        deferrable : String
        deferrable =
            "(?:(?:\\s+NOT)?\\s+DEFERRABLE)?"
    in
    case constraint |> Regex.matches ("^FOREIGN KEY\\s+\\((?<column>[^, )]+)\\)\\s+REFERENCES\\s+(?:(?<schema_b>[^ .]+)\\.)?(?<table_b>[^ .(]+)(?:\\s*\\((?<column_b>[^)]+)\\))?(?:\\s+NOT VALID)?" ++ sqlTriggers ++ deferrable ++ "$") of
        (Just column) :: schemaDest :: (Just tableDest) :: columnDest :: [] ->
            Ok
                { column = column |> buildColumnName
                , ref = { schema = schemaDest |> Maybe.map buildSchemaName, table = tableDest |> buildTableName, column = columnDest |> Maybe.map buildColumnName }
                }

        _ ->
            case constraint |> Regex.matches "^FOREIGN KEY\\s+\\((?<column>[^, )]+)\\)\\s+REFERENCES\\s+(?:(?<schema_b>[^ .]+)\\.)?(?<table_b>[^ .(]+)(?:\\((?<column_b>[^ .]+)\\))?$" of
                (Just column) :: schemaDest :: (Just tableDest) :: columnDest :: [] ->
                    Ok
                        { column = column |> buildColumnName
                        , ref = { schema = schemaDest |> Maybe.map buildSchemaName, table = tableDest |> buildTableName, column = columnDest |> Maybe.map buildColumnName }
                        }

                _ ->
                    Err [ "Can't parse foreign key: '" ++ constraint ++ "'" ]


parseAlterTableAddConstraintUnique : RawSql -> Result (List ParseError) UniqueInner
parseAlterTableAddConstraintUnique constraint =
    case constraint |> Regex.matches "^UNIQUE\\s+(?<definition>.+)$" of
        (Just definition) :: [] ->
            parseIndexDefinition definition
                |> Result.andThen (\columns -> columns |> List.map buildColumnName |> Nel.fromList |> Result.fromMaybe [ "Unique index can't have empty columns" ])
                |> Result.map (\columns -> { columns = columns, definition = definition })

        _ ->
            Err [ "Can't parse unique constraint: '" ++ constraint ++ "'" ]


parseAlterTableAddConstraintCheck : RawSql -> Result (List ParseError) CheckInner
parseAlterTableAddConstraintCheck constraint =
    case constraint |> Regex.matches "^CHECK\\s+(?<predicate>.*)$" of
        (Just predicate) :: [] ->
            Ok { columns = [], predicate = predicate }

        _ ->
            Err [ "Can't parse check constraint: '" ++ constraint ++ "'" ]


parseAlterTableAlterColumn : RawSql -> Result (List ParseError) ColumnUpdate
parseAlterTableAlterColumn command =
    case command |> Regex.matches "^ALTER COLUMN\\s+(?<column>[^ .]+)\\s+SET\\s+(?<property>.+)$" of
        (Just column) :: (Just property) :: [] ->
            if property |> String.toUpper |> String.startsWith "DEFAULT" then
                parseAlterTableAlterColumnDefault property |> Result.map (ColumnDefault column)

            else if property |> String.toUpper |> String.startsWith "STATISTICS" then
                parseAlterTableAlterColumnStatistics property |> Result.map (ColumnStatistics column)

            else
                Err [ "Column update not handled: '" ++ property ++ "'" ]

        _ ->
            Err [ "Can't parse alter column: '" ++ command ++ "'" ]


parseAlterTableAlterColumnDefault : RawSql -> Result (List ParseError) SqlColumnValue
parseAlterTableAlterColumnDefault property =
    case property |> Regex.matches "^DEFAULT\\s+(?<value>.+)$" of
        (Just value) :: [] ->
            Ok value

        _ ->
            Err [ "Can't parse default value: '" ++ property ++ "'" ]


parseAlterTableAlterColumnStatistics : RawSql -> Result (List ParseError) Int
parseAlterTableAlterColumnStatistics property =
    case property |> Regex.matches "^STATISTICS\\s+(?<value>[0-9]+)$" of
        (Just value) :: [] ->
            String.toInt value |> Result.fromMaybe [ "Statistics value is not a number: '" ++ value ++ "'" ]

        _ ->
            Err [ "Can't parse statistics: '" ++ property ++ "'" ]


parseAlterTableOwnerTo : RawSql -> Result (List ParseError) SqlUser
parseAlterTableOwnerTo command =
    case command |> Regex.matches "^OWNER TO\\s+(?<user>.+)$" of
        (Just user) :: [] ->
            Ok user

        _ ->
            Err [ "Can't parse alter column: '" ++ command ++ "'" ]


parseAlterTableDropConstraint : RawSql -> Result (List ParseError) SqlConstraintName
parseAlterTableDropConstraint command =
    case command |> Regex.matches "^DROP CONSTRAINT(?:\\s+IF EXISTS)? (?<name>.+)$" of
        (Just name) :: [] ->
            Ok name

        _ ->
            Err [ "Can't parse drop constraint: '" ++ command ++ "'" ]


sqlTriggers : String
sqlTriggers =
    "(?:\\s+(?:ON UPDATE|ON DELETE)\\s+(?:NO ACTION|CASCADE|SET NULL|SET DEFAULT|RESTRICT))*"
