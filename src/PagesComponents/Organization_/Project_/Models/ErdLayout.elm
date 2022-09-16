module PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout, create, empty, unpack)

import Dict exposing (Dict)
import Libs.Dict as Dict
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Layout exposing (Layout)
import Models.Project.Relation exposing (Relation)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout as ErdTableLayout exposing (ErdTableLayout)
import Set
import Time


type alias ErdLayout =
    { canvas : CanvasProps
    , tables : List ErdTableLayout -- list order is used for z-index
    , createdAt : Time.Posix
    , updatedAt : Time.Posix
    }


empty : Time.Posix -> ErdLayout
empty now =
    { canvas = CanvasProps.empty
    , tables = []
    , createdAt = now
    , updatedAt = now
    }


create : Dict TableId (List Relation) -> Layout -> ErdLayout
create relationsByTable layout =
    { canvas = layout.canvas
    , tables = layout.tables |> List.map (\t -> t |> ErdTableLayout.create (layout.tables |> List.map .id |> Set.fromList) (relationsByTable |> Dict.getOrElse t.id []))
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }


unpack : ErdLayout -> Layout
unpack layout =
    { canvas = layout.canvas
    , tables = layout.tables |> List.map (\t -> t |> ErdTableLayout.unpack)
    , hiddenTables = []
    , createdAt = layout.createdAt
    , updatedAt = layout.updatedAt
    }
