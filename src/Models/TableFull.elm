module Models.TableFull exposing (TableFull)

import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)


type alias TableFull =
    { id : TableId, index : Int, table : Table, props : TableProps }
