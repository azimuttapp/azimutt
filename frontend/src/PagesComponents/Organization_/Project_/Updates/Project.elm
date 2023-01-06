module PagesComponents.Organization_.Project_.Updates.Project exposing (createProject, moveProject, triggerSaveProject, updateProject)

import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Models.Organization exposing (Organization)
import Models.OrganizationId exposing (OrganizationId)
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectName exposing (ProjectName)
import Models.Project.ProjectStorage exposing (ProjectStorage)
import PagesComponents.Organization_.Project_.Components.ProjectSaveDialog as ProjectSaveDialog
import PagesComponents.Organization_.Project_.Models exposing (Model, Msg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd
import Ports
import Services.Toasts as Toasts


triggerSaveProject : Maybe OrganizationId -> List Organization -> Model -> ( Model, Cmd Msg )
triggerSaveProject urlOrganization organizations model =
    let
        preselectedOrg : Maybe Organization
        preselectedOrg =
            urlOrganization |> Maybe.andThen (\id -> organizations |> List.findBy .id id) |> Maybe.orElse (organizations |> List.one)
    in
    ( model
    , model.erd
        |> Maybe.mapOrElse
            (\e ->
                e.project.organization
                    |> Maybe.map (\_ -> UpdateProject |> T.send)
                    |> Maybe.withDefault
                        (if e.project.id == ProjectId.zero then
                            Cmd.batch [ ProjectSaveDialog.Open e.project.name preselectedOrg |> ProjectSaveMsg |> T.send, e |> Erd.unpack |> Ports.updateProjectTmp, Ports.projectDirty False ]

                         else
                            ProjectSaveDialog.Open e.project.name preselectedOrg |> ProjectSaveMsg |> T.send
                        )
            )
            Cmd.none
    )


createProject : ProjectName -> Organization -> ProjectStorage -> Model -> ( Model, Cmd Msg )
createProject name organization storage model =
    if model.conf.save then
        ( model
        , Cmd.batch
            ((model.erd |> Maybe.map Erd.unpack)
                |> Maybe.mapOrElse
                    (\p ->
                        p.organization
                            |> Maybe.map (\_ -> [ "Project already created" |> Toasts.warning |> Toast |> T.send ])
                            |> Maybe.withDefault [ Ports.createProject organization.id storage { p | name = name } ]
                    )
                    [ "No project to save" |> Toasts.warning |> Toast |> T.send ]
            )
        )

    else
        ( model, Cmd.none )


updateProject : Model -> ( Model, Cmd Msg )
updateProject model =
    if model.conf.save then
        ( model
        , Cmd.batch
            ((model.erd |> Maybe.map Erd.unpack)
                |> Maybe.mapOrElse
                    (\p ->
                        p.organization
                            |> Maybe.map (\_ -> [ Ports.updateProject p ])
                            |> Maybe.withDefault [ "Project doesn't exist" |> Toasts.warning |> Toast |> T.send ]
                    )
                    [ "No project to save" |> Toasts.warning |> Toast |> T.send ]
            )
        )

    else
        ( model, Cmd.none )


moveProject : ProjectStorage -> Model -> ( Model, Cmd Msg )
moveProject storage model =
    if model.conf.save then
        ( model
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
