module Models.Project.ColumnPath exposing (ColumnPath, child, fromName, isNested, key, parents, root)

import Libs.List as List
import Libs.Nel as Nel exposing (Nel)
import Models.Project.ColumnName exposing (ColumnName)


type alias ColumnPath =
    -- for nested columns
    Nel ColumnName


separator : String
separator =
    "%"


fromName : ColumnName -> ColumnPath
fromName name =
    name |> String.split separator |> Nel.fromList |> Maybe.withDefault (Nel name [])


root : ColumnName -> ColumnName
root name =
    name |> String.split separator |> List.head |> Maybe.withDefault name


parents : ColumnPath -> Maybe ColumnPath
parents path =
    path |> Nel.toList |> List.dropRight 1 |> Nel.fromList


child : ColumnName -> ColumnPath -> ColumnPath
child name path =
    path |> Nel.add name


key : ColumnPath -> ColumnName
key path =
    path |> Nel.toList |> String.join separator


isNested : ColumnName -> Bool
isNested name =
    name |> String.contains separator
