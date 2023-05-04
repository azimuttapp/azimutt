module PagesComponents.Organization_.Project_.Updates.Groups exposing (Model, handleGroups)

import Libs.List as List
import Models.Project.Group as Group exposing (Group)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Models exposing (GroupMsg(..), Msg(..), NotesDialog)
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import Services.Lenses exposing (mapErdM, mapGroups, mapLayoutsD)


type alias Model x =
    { x | erd : Maybe Erd }


handleGroups : GroupMsg -> Model x -> ( Model x, Cmd Msg )
handleGroups msg model =
    case msg of
        GCreate ->
            ( model |> mapErdM (\erd -> erd |> mapLayoutsD erd.currentLayout (mapGroups (List.add (createGroup erd)))), Cmd.none )


createGroup : Erd -> Group
createGroup erd =
    let
        selectedTables : List TableId
        selectedTables =
            erd |> Erd.currentLayout |> .tables |> List.filter (.props >> .selected) |> List.map .id
    in
    Group.init selectedTables
