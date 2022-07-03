module Models.ColumnOrder exposing (ColumnOrder(..), all, decode, encode, fromString, show, sortBy, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as List
import Libs.Maybe as Maybe
import Models.Project.Column as Column exposing (ColumnLike)
import Models.Project.Relation as Relation exposing (RelationLike)
import Models.Project.Table as Table exposing (TableLike)


type ColumnOrder
    = OrderByIndex
    | OrderByProperty
    | OderByName
    | OderByType


all : List ColumnOrder
all =
    [ OrderByProperty, OderByName, OrderByIndex, OderByType ]


show : ColumnOrder -> String
show order =
    case order of
        OrderByIndex ->
            "By SQL order"

        OrderByProperty ->
            "By property"

        OderByName ->
            "By name"

        OderByType ->
            "By type"


sortBy : ColumnOrder -> TableLike a b -> List (RelationLike c d) -> List (ColumnLike e) -> List (ColumnLike e)
sortBy order table relations columns =
    let
        tableRelations : List (RelationLike c d)
        tableRelations =
            relations |> List.filter (\r -> r.src.table == table.id)
    in
    case order of
        OrderByIndex ->
            columns |> List.sortBy .index

        OrderByProperty ->
            columns
                |> List.sortBy
                    (\c ->
                        if c.name |> Table.inPrimaryKey table |> Maybe.isJust then
                            ( 0 + sortOffset c.nullable, c.name |> String.toLower )

                        else if c.name |> Relation.inOutRelation tableRelations |> List.nonEmpty then
                            ( 1 + sortOffset c.nullable, c.name |> String.toLower )

                        else if c.name |> Table.inUniques table |> List.nonEmpty then
                            ( 2 + sortOffset c.nullable, c.name |> String.toLower )

                        else if c.name |> Table.inIndexes table |> List.nonEmpty then
                            ( 3 + sortOffset c.nullable, c.name |> String.toLower )

                        else
                            ( 4 + sortOffset c.nullable, c.name |> String.toLower )
                    )

        OderByName ->
            columns |> List.sortBy (\c -> c.name |> String.toLower)

        OderByType ->
            columns |> List.sortBy (\c -> c.kind |> String.toLower |> Column.withNullable c)


sortOffset : Bool -> Float
sortOffset b =
    if b then
        0.5

    else
        0


toString : ColumnOrder -> String
toString order =
    case order of
        OrderByIndex ->
            "sql"

        OrderByProperty ->
            "property"

        OderByName ->
            "name"

        OderByType ->
            "type"


fromString : String -> ColumnOrder
fromString order =
    case order of
        "sql" ->
            OrderByIndex

        "property" ->
            OrderByProperty

        "name" ->
            OderByName

        "type" ->
            OderByType

        _ ->
            OrderByIndex


encode : ColumnOrder -> Value
encode value =
    value |> toString |> Encode.string


decode : Decode.Decoder ColumnOrder
decode =
    Decode.string |> Decode.map fromString
