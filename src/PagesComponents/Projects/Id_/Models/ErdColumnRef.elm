module PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef, create, unpack)

import Dict exposing (Dict)
import Libs.Maybe as M
import Libs.Ned as Ned
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)


type alias ErdColumnRef =
    { table : TableId
    , column : ColumnName
    , nullable : Bool
    }


create : Dict TableId Table -> ColumnRef -> ErdColumnRef
create tables ref =
    { table = ref.table
    , column = ref.column
    , nullable = tables |> Dict.get ref.table |> Maybe.andThen (.columns >> Ned.get ref.column) |> M.mapOrElse .nullable False
    }


unpack : ErdColumnRef -> ColumnRef
unpack ref =
    { table = ref.table, column = ref.column }
