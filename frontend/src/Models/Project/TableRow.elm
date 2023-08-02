module Models.Project.TableRow exposing (TableRow)

import Models.JsValue exposing (JsValue)
import Models.Project.SourceId exposing (SourceId)
import Models.Project.TableId exposing (TableId)


type alias TableRow =
    { source : SourceId
    , table : TableId
    , values : List { column : String, value : JsValue }
    }
