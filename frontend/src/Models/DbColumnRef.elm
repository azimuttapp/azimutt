module Models.DbColumnRef exposing (DbColumnRef, from)

import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.TableId exposing (TableId)


type alias DbColumnRef =
    -- same as ColumnRef but for a specific source
    { source : SourceId, table : TableId, column : ColumnPath }


from : SourceId -> { c | table : TableId, column : ColumnPath } -> DbColumnRef
from source ref =
    { source = source, table = ref.table, column = ref.column }
