module Models.Project.CustomTypeId exposing (CustomTypeId)

import Models.Project.CustomTypeName exposing (CustomTypeName)
import Models.Project.SchemaName exposing (SchemaName)


type alias CustomTypeId =
    ( SchemaName, CustomTypeName )
