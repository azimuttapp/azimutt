module Models.Project.TableRow exposing (TableRow, TableRowValue)

import Models.JsValue exposing (JsValue)
import Models.Position as Position
import Models.Project.SourceId exposing (SourceId)
import Models.Size as Size
import Services.QueryBuilder exposing (RowQuery)
import Set exposing (Set)
import Time


type alias TableRow =
    { position : Position.Grid
    , size : Size.Canvas
    , source : SourceId
    , query : RowQuery
    , values : List TableRowValue
    , hidden : Set String
    , expanded : Set String
    , showHidden : Bool
    , loadedAt : Time.Posix
    }


type alias TableRowValue =
    { column : String, value : JsValue }
