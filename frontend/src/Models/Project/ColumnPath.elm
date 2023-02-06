module Models.Project.ColumnPath exposing (ColumnPath, fromName, isNested, key, root)

import Models.Project.ColumnName exposing (ColumnName)


type alias ColumnPath =
    -- for nested columns
    List ColumnName


separator : String
separator =
    "%"


fromName : ColumnName -> ColumnPath
fromName name =
    name |> String.split separator


key : ColumnPath -> ColumnName
key parents =
    parents |> String.join separator


isNested : ColumnName -> Bool
isNested name =
    name |> String.contains separator


root : ColumnName -> ColumnName
root name =
    name |> String.split separator |> List.head |> Maybe.withDefault name
