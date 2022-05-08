module Pages.Projects.New exposing (Model, Msg, page)

import Components.Molecules.Dropdown as Dropdown
import Conf exposing (SampleSchema)
import Dict
import Gen.Params.Projects.New exposing (Params)
import Gen.Route as Route
import Libs.Bool as B
import Libs.Maybe as Maybe
import Libs.Models.FileUrl as FileUrl
import Libs.String as String
import Libs.Task as T
import Models.Project as Project
import Page
import PagesComponents.Projects.New.Models as Models exposing (Msg(..), Tab(..), toastError)
import PagesComponents.Projects.New.View exposing (viewNewProject)
import Ports exposing (JsMsg(..))
import Request
import Services.Lenses exposing (mapList, mapOpenedDialogs, mapProjectImportM, mapProjectImportMCmd, mapSampleSelectionM, mapSampleSelectionMCmd, mapSqlSourceUploadM, mapSqlSourceUploadMCmd, mapToasts, setConfirm, setIsOpen, setToastIdx)
import Services.ProjectImport as ProjectImport
import Services.SqlSourceUpload as SqlSourceUpload
import Shared
import Time
import Track
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init req
        , update = update req
        , view = view shared req
        , subscriptions = subscriptions
        }


type alias Model =
    Models.Model


type alias Msg =
    Models.Msg



-- INIT


title : String
title =
    Conf.constants.defaultTitle


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    let
        sample : Maybe SampleSchema
        sample =
            req.query |> Dict.get "sample" |> Maybe.andThen (\key -> Conf.schemaSamples |> Dict.get key)

        tab : Maybe String
        tab =
            req.query |> Dict.get "tab"

        selectedTab : Tab
        selectedTab =
            (sample |> Maybe.map (\_ -> Sample))
                |> Maybe.withDefault
                    (case tab of
                        Just "schema" ->
                            Schema

                        Just "import" ->
                            Import

                        Just "sample" ->
                            Sample

                        _ ->
                            Schema
                    )
    in
    ( { selectedMenu = "New project"
      , mobileMenuOpen = False
      , openedCollapse = ""
      , projects = []
      , selectedTab = Sample
      , sqlSourceUpload = Nothing
      , projectImport = Nothing
      , sampleSelection = Nothing
      , openedDropdown = ""
      , toastIdx = 0
      , toasts = []
      , confirm = Nothing
      , openedDialogs = []
      }
        |> setSelectedTab selectedTab
    , Cmd.batch
        ([ Ports.setMeta
            { title = Just title
            , description = Just Conf.constants.defaultDescription
            , canonical = Just { route = Route.Projects__New, query = Dict.empty }
            , html = Just "h-full bg-gray-100"
            , body = Just "h-full"
            }
         , Ports.trackPage "new-project"
         , Ports.loadProjects
         ]
            ++ (sample |> Maybe.mapOrElse (\s -> [ T.send (SampleSelectMsg (ProjectImport.SelectRemoteFile s.url (Just s.key))) ]) [])
        )
    )


setSelectedTab : Tab -> Model -> Model
setSelectedTab tab model =
    case tab of
        Schema ->
            { model | selectedTab = tab, sqlSourceUpload = Just (SqlSourceUpload.init Nothing Nothing (\_ -> Noop "select-tab-source-upload")), projectImport = Nothing, sampleSelection = Nothing }

        Import ->
            { model | selectedTab = tab, sqlSourceUpload = Nothing, projectImport = Just ProjectImport.init, sampleSelection = Nothing }

        Sample ->
            { model | selectedTab = tab, sqlSourceUpload = Nothing, projectImport = Nothing, sampleSelection = Just ProjectImport.init }



-- UPDATE


update : Request.With Params -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    case msg of
        SelectMenu menu ->
            ( { model | selectedMenu = menu }, Cmd.none )

        Logout ->
            ( model, Ports.logout )

        ToggleCollapse id ->
            ( { model | openedCollapse = B.cond (model.openedCollapse == id) "" id }, Cmd.none )

        SelectTab tab ->
            ( model |> setSelectedTab tab, Cmd.none )

        SqlSourceUploadMsg message ->
            model |> mapSqlSourceUploadMCmd (SqlSourceUpload.update message SqlSourceUploadMsg)

        SqlSourceUploadDrop ->
            ( model |> mapSqlSourceUploadM (\_ -> SqlSourceUpload.init Nothing Nothing (\_ -> Noop "drop-source-upload")), Cmd.none )

        SqlSourceUploadCreate projectId source ->
            Project.create projectId (String.unique (model.projects |> List.map .name) source.name) source
                |> (\project ->
                        ( model, Cmd.batch [ Ports.saveProject project, Ports.track (Track.createProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )
                   )

        ProjectImportMsg message ->
            model |> mapProjectImportMCmd (ProjectImport.update message)

        ProjectImportDrop ->
            ( model |> mapProjectImportM (\_ -> ProjectImport.init), Cmd.none )

        ProjectImportCreate project ->
            ( model, Cmd.batch [ Ports.saveProject project, Ports.track (Track.importProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        ProjectImportCreateNew id project ->
            { project | id = id, name = String.unique (model.projects |> List.map .name) project.name }
                |> (\p ->
                        ( model, Cmd.batch [ Ports.saveProject p, Ports.track (Track.importProject p), Request.pushRoute (Route.Projects__Id_ { id = p.id }) req ] )
                   )

        SampleSelectMsg message ->
            model |> mapSampleSelectionMCmd (ProjectImport.update message)

        SampleSelectDrop ->
            ( model |> mapSampleSelectionM (\_ -> ProjectImport.init), Cmd.none )

        SampleSelectCreate project ->
            ( model, Cmd.batch [ Ports.saveProject project, Ports.track (Track.importProject project), Request.pushRoute (Route.Projects__Id_ { id = project.id }) req ] )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

        ToastAdd millis toast ->
            model.toastIdx |> String.fromInt |> (\key -> ( model |> setToastIdx (model.toastIdx + 1) |> mapToasts (\t -> { key = key, content = toast, isOpen = False } :: t), T.sendAfter 1 (ToastShow millis key) ))

        ToastShow millis key ->
            ( model |> mapToasts (mapList .key key (setIsOpen True)), millis |> Maybe.mapOrElse (\delay -> T.sendAfter delay (ToastHide key)) Cmd.none )

        ToastHide key ->
            ( model |> mapToasts (mapList .key key (setIsOpen False)), T.sendAfter 300 (ToastRemove key) )

        ToastRemove key ->
            ( model |> mapToasts (List.filter (\t -> t.key /= key)), Cmd.none )

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Conf.ui.closeDuration message )

        JsMessage message ->
            model |> handleJsMessage message

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage msg model =
    case msg of
        GotProjects ( _, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }, Cmd.none )

        GotLocalFile now projectId sourceId file content ->
            if file.name |> String.endsWith ".json" then
                ( model, T.send (ProjectImport.gotLocalFile projectId content |> ProjectImportMsg) )

            else if file.name |> String.endsWith ".sql" then
                ( model, T.send (SqlSourceUpload.gotLocalFile now projectId sourceId file content |> SqlSourceUploadMsg) )

            else
                ( model, T.send (toastError ("File should end with .json or .sql, " ++ file.name ++ " is not handled :(")) )

        GotRemoteFile now projectId sourceId url content sample ->
            if url |> FileUrl.filename |> String.endsWith ".json" then
                if sample == Nothing then
                    ( model, T.send (ProjectImport.gotRemoteFile projectId content |> ProjectImportMsg) )

                else
                    ( model, T.send (ProjectImport.gotRemoteFile projectId content |> SampleSelectMsg) )

            else if url |> FileUrl.filename |> String.endsWith ".sql" then
                ( model, T.send (SqlSourceUpload.gotRemoteFile now projectId sourceId url content sample |> SqlSourceUploadMsg) )

            else
                ( model, T.send (toastError ("File should end with .json or .sql, " ++ url ++ " is not handled :(")) )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        ([ Ports.onJsMessage JsMessage ]
            ++ Dropdown.subscriptions model DropdownToggle (Noop "dropdown already opened")
        )



-- VIEW


view : Shared.Model -> Request.With Params -> Model -> View Msg
view shared req model =
    { title = title, body = model |> viewNewProject shared.zone shared.user req.route }
