module Models.Project.TableName exposing (TableName)


type alias TableName =
    -- needs to be comparable to have TableId in Dict key
    String
