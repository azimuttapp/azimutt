module Services.QueryBuilder exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, SqlFragment, SqlQuery, TableFilter, TableQuery, filterTable, findRow, incomingRows, incomingRowsLimit, limitResults, operationHasValue, operationToString, operations, operationsForType, operatorFromString, operatorToString, operators, stringToOperation)

import Dict exposing (Dict)
import Libs.Bool as Bool
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.DbValue as DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType, ParsedColumnType)
import Models.Project.RowPrimaryKey exposing (RowPrimaryKey)
import Models.Project.RowValue exposing (RowValue)
import Models.Project.TableId as TableId exposing (TableId)



-- FIXME merge DatabaseQueries here


type alias SqlQuery =
    String


type alias SqlFragment =
    String


type alias TableQuery =
    { table : TableId, filters : List TableFilter }


type alias TableFilter =
    { operator : FilterOperator, column : ColumnPath, operation : FilterOperation, value : DbValue }


filterTable : DatabaseKind -> TableQuery -> SqlQuery
filterTable db query =
    if db == DatabaseKind.PostgreSQL then
        "SELECT *\nFROM " ++ formatTable db query.table ++ formatFilters db query.filters ++ ";\n"

    else
        ""


type alias RowQuery =
    { table : TableId, primaryKey : RowPrimaryKey }


findRow : DatabaseKind -> RowQuery -> SqlQuery
findRow db query =
    if db == DatabaseKind.PostgreSQL then
        "SELECT *\nFROM " ++ formatTable db query.table ++ "\nWHERE " ++ formatMatcher db query.primaryKey ++ "\nLIMIT 1;\n"

    else
        ""


limitResults : DatabaseKind -> SqlQuery -> SqlQuery
limitResults db query =
    if db == DatabaseKind.PostgreSQL then
        case query |> String.trim |> Regex.matches "^([\\s\\S]+?)(\\slimit \\d+)?(\\soffset \\d+)?;$" of
            (Just q) :: Nothing :: Nothing :: [] ->
                q ++ "\nLIMIT 100;\n"

            (Just q) :: Nothing :: (Just offset) :: [] ->
                q ++ "\nLIMIT 100" ++ offset ++ ";\n"

            _ ->
                query

    else
        ""


type alias IncomingRowsQuery =
    { primaryKey : Nel ( ColumnPath, ColumnType ), foreignKeys : List ( ColumnPath, ColumnType ) }


incomingRowsLimit : Int
incomingRowsLimit =
    20


incomingRows : DatabaseKind -> Dict TableId IncomingRowsQuery -> RowQuery -> SqlQuery
incomingRows db relations query =
    if db == DatabaseKind.PostgreSQL then
        "SELECT\n"
            ++ (relations
                    |> Dict.toList
                    |> List.map
                        (\( table, q ) ->
                            "  array(SELECT json_build_object("
                                ++ (q.primaryKey |> Nel.toList |> List.map (\( col, kind ) -> "'" ++ (col |> ColumnPath.toString) ++ "', " ++ formatColumn db "s" col (ColumnType.parse kind)) |> String.join ", ")
                                ++ ")"
                                ++ " FROM "
                                ++ formatTable db table
                                ++ " s WHERE "
                                ++ (q.foreignKeys |> List.map (\( fk, kind ) -> formatColumn db "s" fk (ColumnType.parse kind) ++ " = " ++ formatColumn db "m" query.primaryKey.head.column (DbValue.toType query.primaryKey.head.value)) |> String.join " OR ")
                                ++ " LIMIT "
                                ++ String.fromInt incomingRowsLimit
                                ++ ") as \""
                                ++ TableId.toString table
                                ++ "\""
                        )
                    |> String.join ",\n"
               )
            ++ "\nFROM "
            ++ formatTable db query.table
            ++ " m\nWHERE "
            ++ formatMatcher db query.primaryKey
            ++ "\nLIMIT 1;\n"

    else
        ""


type FilterOperator
    = OpAnd
    | OpOr


operators : List FilterOperator
operators =
    [ OpAnd, OpOr ]


operatorToString : FilterOperator -> String
operatorToString op =
    case op of
        OpAnd ->
            "AND"

        OpOr ->
            "OR"


operatorFromString : String -> Maybe FilterOperator
operatorFromString op =
    case op of
        "AND" ->
            Just OpAnd

        "OR" ->
            Just OpOr

        _ ->
            Nothing


type FilterOperation
    = OpEqual
    | OpNotEqual
    | OpIsNull
    | OpIsNotNull
    | OpGreaterThan
    | OpLesserThan
    | OpLike


operations : List FilterOperation
operations =
    [ OpEqual, OpNotEqual, OpIsNull, OpIsNotNull, OpGreaterThan, OpLesserThan, OpLike ]


operationsForType : ColumnType -> Bool -> List FilterOperation
operationsForType kind nullable =
    (case ColumnType.parse kind of
        ColumnType.Unknown _ ->
            operations

        ColumnType.Array _ ->
            operations

        ColumnType.Text ->
            operationsText

        ColumnType.Int ->
            operationsNumber

        ColumnType.Float ->
            operationsNumber

        ColumnType.Bool ->
            operationsBool

        ColumnType.Date ->
            operationsDate

        ColumnType.Time ->
            operationsDate

        ColumnType.Instant ->
            operationsDate

        ColumnType.Interval ->
            operationsDefault

        ColumnType.Uuid ->
            operationsDefault

        ColumnType.Ip ->
            operationsDefault

        ColumnType.Json ->
            operationsDefault

        ColumnType.Binary ->
            operationsDefault
    )
        |> filterNullableOperations nullable


filterNullableOperations : Bool -> List FilterOperation -> List FilterOperation
filterNullableOperations nullable ops =
    if nullable then
        ops

    else
        ops |> List.filter (isNullOperation >> not)


operationsText : List FilterOperation
operationsText =
    [ OpEqual, OpNotEqual, OpIsNull, OpIsNotNull, OpGreaterThan, OpLesserThan, OpLike ]


operationsNumber : List FilterOperation
operationsNumber =
    [ OpEqual, OpNotEqual, OpIsNull, OpIsNotNull, OpGreaterThan, OpLesserThan ]


operationsBool : List FilterOperation
operationsBool =
    [ OpEqual, OpNotEqual, OpIsNull, OpIsNotNull ]


operationsDate : List FilterOperation
operationsDate =
    [ OpEqual, OpNotEqual, OpIsNull, OpIsNotNull, OpGreaterThan, OpLesserThan ]


operationsDefault : List FilterOperation
operationsDefault =
    [ OpEqual, OpNotEqual, OpIsNull, OpIsNotNull ]


operationToString : FilterOperation -> String
operationToString op =
    case op of
        OpEqual ->
            "equal"

        OpNotEqual ->
            "not equal"

        OpIsNull ->
            "is null"

        OpIsNotNull ->
            "is not null"

        OpGreaterThan ->
            "greater than"

        OpLesserThan ->
            "lesser than"

        OpLike ->
            "like"


stringToOperation : String -> Maybe FilterOperation
stringToOperation op =
    case op of
        "equal" ->
            Just OpEqual

        "not equal" ->
            Just OpNotEqual

        "is null" ->
            Just OpIsNull

        "is not null" ->
            Just OpIsNotNull

        "greater than" ->
            Just OpGreaterThan

        "lesser than" ->
            Just OpLesserThan

        "like" ->
            Just OpLike

        _ ->
            Nothing


operationHasValue : FilterOperation -> Bool
operationHasValue op =
    isNullOperation op |> not


isNullOperation : FilterOperation -> Bool
isNullOperation op =
    op == OpIsNull || op == OpIsNotNull


formatTable : DatabaseKind -> TableId -> String
formatTable db ( schema, table ) =
    if db == DatabaseKind.PostgreSQL then
        if schema == "" then
            "\"" ++ table ++ "\""

        else
            "\"" ++ schema ++ "\"" ++ "." ++ "\"" ++ table ++ "\""

    else
        ""


formatFilters : DatabaseKind -> List TableFilter -> String
formatFilters db filters =
    if db == DatabaseKind.PostgreSQL then
        if filters |> List.isEmpty then
            ""

        else
            "\nWHERE "
                ++ (filters
                        |> List.indexedMap
                            (\i f ->
                                if i == 0 then
                                    formatFilter db f

                                else
                                    formatOperator db f.operator ++ " " ++ formatFilter db f
                            )
                        |> String.join " "
                   )

    else
        ""


formatFilter : DatabaseKind -> TableFilter -> String
formatFilter db filter =
    if db == DatabaseKind.PostgreSQL then
        formatColumn db "" filter.column (DbValue.toType filter.value) ++ formatOperation db filter.operation filter.value

    else
        ""


formatOperation : DatabaseKind -> FilterOperation -> DbValue -> String
formatOperation db op value =
    if db == DatabaseKind.PostgreSQL then
        case op of
            OpEqual ->
                "=" ++ formatValue db value

            OpNotEqual ->
                "!=" ++ formatValue db value

            OpIsNull ->
                " IS NULL"

            OpIsNotNull ->
                " IS NOT NULL"

            OpGreaterThan ->
                ">" ++ formatValue db value

            OpLesserThan ->
                "<" ++ formatValue db value

            OpLike ->
                " LIKE " ++ formatValue db value

    else
        ""


formatMatcher : DatabaseKind -> Nel RowValue -> String
formatMatcher db matches =
    if db == DatabaseKind.PostgreSQL then
        matches |> Nel.toList |> List.map (\m -> formatColumn db "" m.column (DbValue.toType m.value) ++ "=" ++ formatValue db m.value) |> String.join " AND "

    else
        ""


formatColumn : DatabaseKind -> String -> ColumnPath -> ParsedColumnType -> String
formatColumn db prefix column kind =
    if db == DatabaseKind.PostgreSQL then
        let
            baseCol : String
            baseCol =
                if prefix == "" then
                    "\"" ++ column.head ++ "\""

                else
                    prefix ++ ".\"" ++ column.head ++ "\""
        in
        case column.tail |> List.reverse of
            last :: rest ->
                baseCol ++ (rest |> List.reverse |> List.map (\c -> "->'" ++ c ++ "'") |> String.join "") ++ "->>'" ++ last ++ "'" |> formatColumnCast kind

            [] ->
                baseCol

    else
        ""


formatColumnCast : ParsedColumnType -> String -> String
formatColumnCast kind sqlColumn =
    case kind of
        ColumnType.Int ->
            "(" ++ sqlColumn ++ ")::int"

        ColumnType.Float ->
            "(" ++ sqlColumn ++ ")::float"

        ColumnType.Bool ->
            "(" ++ sqlColumn ++ ")::boolean"

        ColumnType.Uuid ->
            "(" ++ sqlColumn ++ ")::uuid"

        _ ->
            sqlColumn


formatValue : DatabaseKind -> DbValue -> String
formatValue db value =
    if db == DatabaseKind.PostgreSQL then
        case value of
            DbString s ->
                "'" ++ s ++ "'"

            DbInt i ->
                String.fromInt i

            DbFloat f ->
                String.fromFloat f

            DbBool b ->
                Bool.cond b "true" "false"

            DbNull ->
                "null"

            _ ->
                "'" ++ DbValue.toJson value ++ "'"

    else
        ""


formatOperator : DatabaseKind -> FilterOperator -> String
formatOperator db op =
    if db == DatabaseKind.PostgreSQL then
        case op of
            OpAnd ->
                "AND"

            OpOr ->
                "OR"

    else
        ""
