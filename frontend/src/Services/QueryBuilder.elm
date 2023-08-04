module Services.QueryBuilder exposing (ColumnMatch, FilterOperation(..), FilterOperator(..), RowQuery, TableFilter, TableQuery, decodeRowQuery, encodeColumnMatch, encodeRowQuery, filterTable, findRow, limitResults, operationHasValue, operationToString, operations, operationsForType, operatorToString, operators, stringToOperation, stringToOperator)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Libs.Bool as Bool
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Libs.Nel as Nel exposing (Nel)
import Libs.Regex as Regex
import Models.JsValue as JsValue exposing (JsValue)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.TableId as TableId exposing (TableId)


type alias TableQuery =
    { table : Maybe TableId, filters : List TableFilter }


type alias TableFilter =
    { operator : FilterOperator, column : ColumnPath, kind : ColumnType, nullable : Bool, operation : FilterOperation, value : JsValue }


type alias RowQuery =
    { table : TableId, primaryKey : Nel ColumnMatch }


type alias ColumnMatch =
    { column : ColumnPath, value : JsValue }


filterTable : DatabaseKind -> TableQuery -> String
filterTable db query =
    if db == DatabaseKind.PostgreSQL then
        query.table |> Maybe.map (\table -> "SELECT * FROM " ++ formatTable db table ++ formatFilters db query.filters ++ ";") |> Maybe.withDefault ""

    else
        ""


findRow : DatabaseKind -> RowQuery -> String
findRow db query =
    if db == DatabaseKind.PostgreSQL then
        "SELECT * FROM " ++ formatTable db query.table ++ " WHERE " ++ formatMatcher db query.primaryKey ++ " LIMIT 1;"

    else
        ""


limitResults : DatabaseKind -> String -> String
limitResults db query =
    if db == DatabaseKind.PostgreSQL then
        case query |> Regex.matches "^(.+?)( limit \\d+)?( offset \\d+)?;$" of
            (Just q) :: Nothing :: Nothing :: [] ->
                q ++ " LIMIT 100;"

            (Just q) :: Nothing :: (Just offset) :: [] ->
                q ++ " LIMIT 100" ++ offset ++ ";"

            _ ->
                query

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


stringToOperator : String -> Maybe FilterOperator
stringToOperator op =
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
            table

        else
            schema ++ "." ++ table

    else
        ""


formatFilters : DatabaseKind -> List TableFilter -> String
formatFilters db filters =
    if db == DatabaseKind.PostgreSQL then
        if filters |> List.isEmpty then
            ""

        else
            " WHERE "
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
        formatColumn db filter.column ++ formatOperation db filter.operation filter.value

    else
        ""


formatOperation : DatabaseKind -> FilterOperation -> JsValue -> String
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


formatMatcher : DatabaseKind -> Nel ColumnMatch -> String
formatMatcher db matches =
    if db == DatabaseKind.PostgreSQL then
        matches |> Nel.toList |> List.map (\m -> formatColumn db m.column ++ "=" ++ formatValue db m.value) |> String.join " AND "

    else
        ""


formatColumn : DatabaseKind -> ColumnPath -> String
formatColumn db column =
    if db == DatabaseKind.PostgreSQL then
        column.head ++ (column.tail |> List.map (\c -> "->>'" ++ c ++ "'") |> String.join "")

    else
        ""


formatValue : DatabaseKind -> JsValue -> String
formatValue db value =
    if db == DatabaseKind.PostgreSQL then
        case value of
            JsValue.String s ->
                "'" ++ s ++ "'"

            JsValue.Int i ->
                String.fromInt i

            JsValue.Float f ->
                String.fromFloat f

            JsValue.Bool b ->
                Bool.cond b "true" "false"

            JsValue.Null ->
                "null"

            _ ->
                "'" ++ JsValue.toJson value ++ "'"

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


encodeRowQuery : RowQuery -> Value
encodeRowQuery value =
    Encode.object
        [ ( "table", value.table |> TableId.encode )
        , ( "primaryKey", value.primaryKey |> Encode.nel encodeColumnMatch )
        ]


decodeRowQuery : Decoder RowQuery
decodeRowQuery =
    Decode.map2 RowQuery
        (Decode.field "table" TableId.decode)
        (Decode.field "primaryKey" (Decode.nel decodeColumnMatch))


encodeColumnMatch : ColumnMatch -> Value
encodeColumnMatch value =
    Encode.object
        [ ( "column", value.column |> ColumnPath.encode )
        , ( "value", value.value |> JsValue.encode )
        ]


decodeColumnMatch : Decoder ColumnMatch
decodeColumnMatch =
    Decode.map2 ColumnMatch
        (Decode.field "column" ColumnPath.decode)
        (Decode.field "value" JsValue.decode)
