module PagesComponents.Projects.Id_.Models.ErdRelationProps exposing (ErdRelationProps, create)

import Models.Project.TableId exposing (TableId)


type alias ErdRelationProps =
    { shown : Bool }


create : List TableId -> TableId -> ErdRelationProps
create shownTables id =
    { shown = shownTables |> List.any (\t -> t == id) }
