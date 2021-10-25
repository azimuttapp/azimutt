module Models.Project.SchemaName exposing (SchemaName)


type alias SchemaName =
    -- needs to be comparable to have TableId in Dict key
    String
