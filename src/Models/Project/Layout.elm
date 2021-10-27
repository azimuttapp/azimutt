module Models.Project.Layout exposing (Layout)

import Models.Project.CanvasProps exposing (CanvasProps)
import Models.Project.TableProps exposing (TableProps)
import Time


type alias Layout =
    { canvas : CanvasProps
    , tables : List TableProps
    , hiddenTables : List TableProps
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }
