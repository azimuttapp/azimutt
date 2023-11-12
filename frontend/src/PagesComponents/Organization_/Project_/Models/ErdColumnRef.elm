module PagesComponents.Organization_.Project_.Models.ErdColumnRef exposing (ErdColumnRef, create, toId, unpack)

import Dict exposing (Dict)
import Libs.Maybe as Maybe
import Models.Project.ColumnId exposing (ColumnId)
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin as TableWithOrigin exposing (TableWithOrigin)


type alias ErdColumnRef =
    { table : TableId
    , column : ColumnPath
    , nullable : Bool
    }


toId : ErdColumnRef -> ColumnId
toId ref =
    ( ref.table, ref.column |> ColumnPath.toString )


create : Dict TableId TableWithOrigin -> ColumnRef -> ErdColumnRef
create tables ref =
    { table = ref.table
    , column = ref.column
    , nullable = tables |> Dict.get ref.table |> Maybe.andThen (TableWithOrigin.getColumn ref.column) |> Maybe.mapOrElse .nullable False
    }


unpack : ErdColumnRef -> ColumnRef
unpack ref =
    { table = ref.table, column = ref.column }
