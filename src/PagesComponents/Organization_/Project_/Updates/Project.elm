module PagesComponents.Organization_.Project_.Updates.Project exposing (moveProject, saveProject, triggerSaveProject)

import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Organization exposing (Organization)
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage exposing (ProjectStorage)
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import Ports
import Services.Lenses exposing (mapUploadM)
import Services.Toasts as Toasts
import Track


triggerSaveProject : List Organization -> Model -> ( Model, Cmd Msg )
triggerSaveProject organizations model =
    -- FIXME: open create project modal (choose orga & save mode)
    ( model, organizations |> List.head |> Maybe.mapOrElse (SaveProject >> T.send) Cmd.none )


saveProject : Organization -> Model -> ( Model, Cmd Msg )
saveProject organization model =
    if model.conf.save then
        ( model
        , Cmd.batch
            (model.erd
                |> Maybe.map Erd.unpack
                |> Maybe.mapOrElse
                    (\p ->
                        if p.id == ProjectId.zero then
                            -- FIXME: handle legacy projects here
                            [ Ports.createProjectLocal organization.id p, Ports.track (Track.createProject p) ]

                        else
                            [ Ports.updateProject p, Ports.track (Track.updateProject p) ]
                    )
                    [ "No project to save" |> Toasts.warning |> Toast |> T.send ]
            )
        )

    else
        ( model, Cmd.none )


moveProject : ProjectStorage -> Model -> ( Model, Cmd Msg )
moveProject storage model =
    if model.conf.save then
        ( model |> mapUploadM (\u -> { u | movingProject = True })
        , Cmd.batch
            (model.erd
                |> Maybe.map Erd.unpack
                |> Maybe.mapOrElse
                    (\p -> [ Ports.moveProjectTo p storage ])
                    [ "No project to move" |> Toasts.warning |> Toast |> T.send ]
            )
        )

    else
        ( model, Cmd.none )
