module Models.ColumnOrder exposing (ColumnOrder(..), all, decode, encode, fromString, show, sortBy, toString)

import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import Libs.List as L
import Libs.Maybe as M
import Models.Project.Column as Column exposing (Column)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Table as Table exposing (Table)


type ColumnOrder
    = SqlOrder
    | Property
    | Name
    | Type


all : List ColumnOrder
all =
    [ Property, Name, SqlOrder, Type ]


show : ColumnOrder -> String
show order =
    case order of
        SqlOrder ->
            "By SQL order"

        Property ->
            "By property"

        Name ->
            "By name"

        Type ->
            "By type"


sortBy : ColumnOrder -> Table -> List Relation -> List Column -> List Column
sortBy order table relations columns =
    let
        tableRelations : List Relation
        tableRelations =
            relations |> Relation.withTableSrc table.id
    in
    case order of
        SqlOrder ->
            columns |> List.sortBy .index

        Property ->
            columns
                |> List.sortBy
                    (\c ->
                        if c.name |> Table.inPrimaryKey table |> M.isJust then
                            ( 0 + sortOffset c.nullable, c.name |> String.toLower )

                        else if c.name |> Relation.inOutRelation tableRelations |> L.nonEmpty then
                            ( 1 + sortOffset c.nullable, c.name |> String.toLower )

                        else if c.name |> Table.inUniques table |> L.nonEmpty then
                            ( 2 + sortOffset c.nullable, c.name |> String.toLower )

                        else if c.name |> Table.inIndexes table |> L.nonEmpty then
                            ( 3 + sortOffset c.nullable, c.name |> String.toLower )

                        else
                            ( 4 + sortOffset c.nullable, c.name |> String.toLower )
                    )

        Name ->
            columns |> List.sortBy (\c -> c.name |> String.toLower)

        Type ->
            columns |> List.sortBy (\c -> c.kind |> String.toLower |> Column.withNullableInfo c.nullable)


sortOffset : Bool -> Float
sortOffset b =
    if b then
        0.5

    else
        0


toString : ColumnOrder -> String
toString order =
    case order of
        SqlOrder ->
            "sql"

        Property ->
            "property"

        Name ->
            "name"

        Type ->
            "type"


fromString : String -> ColumnOrder
fromString order =
    case order of
        "sql" ->
            SqlOrder

        "property" ->
            Property

        "name" ->
            Name

        "type" ->
            Type

        _ ->
            SqlOrder


encode : ColumnOrder -> Value
encode value =
    value |> toString |> Encode.string


decode : Decode.Decoder ColumnOrder
decode =
    Decode.string |> Decode.map fromString
