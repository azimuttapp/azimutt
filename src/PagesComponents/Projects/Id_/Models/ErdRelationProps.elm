module PagesComponents.Projects.Id_.Models.ErdRelationProps exposing (ErdRelationProps, create)

import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps exposing (TableProps)


type alias ErdRelationProps =
    { shown : Bool }


create : List TableProps -> TableId -> ErdRelationProps
create shownTables id =
    { shown = shownTables |> List.any (\t -> t.id == id) }
