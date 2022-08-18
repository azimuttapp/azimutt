module Models.Project.CustomTypeId exposing (CustomTypeId, fromColumnType)

import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.CustomTypeName exposing (CustomTypeName)
import Models.Project.SchemaName exposing (SchemaName)


type alias CustomTypeId =
    ( SchemaName, CustomTypeName )


fromColumnType : ColumnType -> CustomTypeId
fromColumnType kind =
    case kind |> String.split "." of
        schema :: name :: [] ->
            ( schema, name )

        _ ->
            ( "", kind )
