module PagesComponents.Projects.Id_.Updates.Project exposing (moveProject, saveProject)

import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Organization exposing (Organization)
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage exposing (ProjectStorage)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..))
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import Ports
import Services.Lenses exposing (mapUploadM)
import Services.Toasts as Toasts
import Track


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
