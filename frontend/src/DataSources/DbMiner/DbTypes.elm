module DataSources.DbMiner.DbTypes exposing (DbColumnRef, FilterOperation(..), FilterOperator(..), IncomingRowsQuery, RowQuery, TableFilter, TableQuery, operationFromString, operationHasValue, operationToString, operationsForType, operatorFromString, operatorToString, operators)

import Libs.Nel exposing (Nel)
import Models.DbValue exposing (DbValue)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType as ColumnType exposing (ColumnType)
import Models.Project.RowPrimaryKey exposing (RowPrimaryKey)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.TableId exposing (TableId)


type alias TableQuery =
    { table : TableId, filters : List TableFilter }


type alias TableFilter =
    { operator : FilterOperator, column : ColumnPath, operation : FilterOperation, value : DbValue }


type alias DbColumnRef =
    { source : SourceId, table : TableId, column : ColumnPath }


type alias RowQuery =
    { source : SourceId, table : TableId, primaryKey : RowPrimaryKey }


type alias IncomingRowsQuery =
    { primaryKey : Nel ( ColumnPath, ColumnType ), foreignKeys : List ( ColumnPath, ColumnType ), altCols : List ( ColumnPath, ColumnType ) }



-- Filter Operator


type FilterOperator
    = DbAnd
    | DbOr


operators : List FilterOperator
operators =
    [ DbAnd, DbOr ]


operatorToString : FilterOperator -> String
operatorToString op =
    case op of
        DbAnd ->
            "AND"

        DbOr ->
            "OR"


operatorFromString : String -> Maybe FilterOperator
operatorFromString op =
    case op of
        "AND" ->
            Just DbAnd

        "OR" ->
            Just DbOr

        _ ->
            Nothing



-- Filter Operation


type FilterOperation
    = DbEqual
    | DbNotEqual
    | DbIsNull
    | DbIsNotNull
    | DbGreaterThan
    | DbLesserThan
    | DbLike


operations : List FilterOperation
operations =
    [ DbEqual, DbNotEqual, DbIsNull, DbIsNotNull, DbGreaterThan, DbLesserThan, DbLike ]


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
    [ DbEqual, DbNotEqual, DbIsNull, DbIsNotNull, DbGreaterThan, DbLesserThan, DbLike ]


operationsNumber : List FilterOperation
operationsNumber =
    [ DbEqual, DbNotEqual, DbIsNull, DbIsNotNull, DbGreaterThan, DbLesserThan ]


operationsBool : List FilterOperation
operationsBool =
    [ DbEqual, DbNotEqual, DbIsNull, DbIsNotNull ]


operationsDate : List FilterOperation
operationsDate =
    [ DbEqual, DbNotEqual, DbIsNull, DbIsNotNull, DbGreaterThan, DbLesserThan ]


operationsDefault : List FilterOperation
operationsDefault =
    [ DbEqual, DbNotEqual, DbIsNull, DbIsNotNull ]


operationToString : FilterOperation -> String
operationToString op =
    case op of
        DbEqual ->
            "equal"

        DbNotEqual ->
            "not equal"

        DbIsNull ->
            "is null"

        DbIsNotNull ->
            "is not null"

        DbGreaterThan ->
            "greater than"

        DbLesserThan ->
            "lesser than"

        DbLike ->
            "like"


operationFromString : String -> Maybe FilterOperation
operationFromString op =
    case op of
        "equal" ->
            Just DbEqual

        "not equal" ->
            Just DbNotEqual

        "is null" ->
            Just DbIsNull

        "is not null" ->
            Just DbIsNotNull

        "greater than" ->
            Just DbGreaterThan

        "lesser than" ->
            Just DbLesserThan

        "like" ->
            Just DbLike

        _ ->
            Nothing


operationHasValue : FilterOperation -> Bool
operationHasValue op =
    isNullOperation op |> not


isNullOperation : FilterOperation -> Bool
isNullOperation op =
    op == DbIsNull || op == DbIsNotNull
