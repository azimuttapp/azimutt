port module Ports exposing (JsMsg(..), MetaInfos, autofocusWithin, blur, click, confetti, confettiPride, createProjectLocal, createProjectRemote, createProjectTmp, deleteProject, downloadFile, focus, fullscreen, getOwners, getProject, getUser, listProjects, listenHotkeys, loadProject, mouseDown, moveProjectTo, observeSize, observeTableSize, observeTablesSize, onJsMessage, readLocalFile, scrollTo, setMeta, setOwners, track, trackError, trackJsonError, trackPage, unhandledJsMsgError, updateProject)

import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode as Decode exposing (Decoder, Value, errorToString)
import Json.Encode as Encode
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Models exposing (FileContent, SizeChange, TrackEvent)
import Libs.Models.Delta as Delta exposing (Delta)
import Libs.Models.Email exposing (Email)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.Hotkey as Hotkey exposing (Hotkey)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Tailwind as Color exposing (Color)
import Models.OrganizationId as OrganizationId exposing (OrganizationId)
import Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.TableId as TableId exposing (TableId)
import Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Models.Route as Route exposing (Route)
import Models.Size as Size
import Models.UserId as UserId exposing (UserId)
import Models.UserLegacy as UserLegacy exposing (UserLegacy)
import Storage.ProjectV2 exposing (decodeProject)
import Track


click : HtmlId -> Cmd msg
click id =
    messageToJs (Click id)


mouseDown : HtmlId -> Cmd msg
mouseDown id =
    messageToJs (MouseDown id)


focus : HtmlId -> Cmd msg
focus id =
    messageToJs (Focus id)


blur : HtmlId -> Cmd msg
blur id =
    messageToJs (Blur id)


scrollTo : HtmlId -> String -> Cmd msg
scrollTo id position =
    messageToJs (ScrollTo id position)


fullscreen : Maybe HtmlId -> Cmd msg
fullscreen maybeId =
    messageToJs (Fullscreen maybeId)


autofocusWithin : HtmlId -> Cmd msg
autofocusWithin id =
    messageToJs (AutofocusWithin id)


setMeta : MetaInfos -> Cmd msg
setMeta payload =
    messageToJs (SetMeta payload)


getProject : OrganizationId -> ProjectId -> Cmd msg
getProject organization project =
    messageToJs (GetProject organization project)


listProjects : Cmd msg
listProjects =
    messageToJs ListProjects


loadProject : ProjectId -> Cmd msg
loadProject id =
    messageToJs (LoadProject id)


createProjectTmp : Project -> Cmd msg
createProjectTmp project =
    messageToJs (CreateProjectTmp project)


createProjectLocal : OrganizationId -> Project -> Cmd msg
createProjectLocal organization project =
    messageToJs (CreateProjectLocal organization project)


createProjectRemote : Project -> Cmd msg
createProjectRemote project =
    messageToJs (CreateProjectRemote project)


updateProject : Project -> Cmd msg
updateProject project =
    messageToJs (UpdateProject project)


moveProjectTo : Project -> ProjectStorage -> Cmd msg
moveProjectTo project storage =
    messageToJs (MoveProjectTo project storage)


getUser : Email -> Cmd msg
getUser email =
    messageToJs (GetUser email)


getOwners : ProjectId -> Cmd msg
getOwners projectId =
    messageToJs (GetOwners projectId)


setOwners : ProjectId -> List UserId -> Cmd msg
setOwners projectId owners =
    messageToJs (SetOwners projectId owners)


downloadFile : FileName -> FileContent -> Cmd msg
downloadFile filename content =
    messageToJs (DownloadFile filename content)


deleteProject : ProjectInfo -> Cmd msg
deleteProject project =
    Cmd.batch [ messageToJs (DeleteProject project), track (Track.deleteProject project) ]


readLocalFile : String -> File -> Cmd msg
readLocalFile sourceKind file =
    messageToJs (GetLocalFile sourceKind file)


observeSize : HtmlId -> Cmd msg
observeSize id =
    observeSizes [ id ]


observeTableSize : TableId -> Cmd msg
observeTableSize id =
    observeSizes [ TableId.toHtmlId id ]


observeTablesSize : List TableId -> Cmd msg
observeTablesSize ids =
    observeSizes (List.map TableId.toHtmlId ids)


observeSizes : List HtmlId -> Cmd msg
observeSizes ids =
    if ids |> List.isEmpty then
        Cmd.none

    else
        messageToJs (ObserveSizes ids)


listenHotkeys : Dict String (List Hotkey) -> Cmd msg
listenHotkeys keys =
    messageToJs (ListenKeys keys)


confetti : HtmlId -> Cmd msg
confetti id =
    messageToJs (Confetti id)


confettiPride : Cmd msg
confettiPride =
    messageToJs ConfettiPride


track : TrackEvent -> Cmd msg
track event =
    if event.enabled then
        messageToJs (TrackEvent event.name (Encode.object (event.details |> List.map (\( k, v ) -> ( k, v |> Encode.string )))))

    else
        Cmd.none


trackPage : String -> Cmd msg
trackPage name =
    messageToJs (TrackPage name)


trackJsonError : String -> Decode.Error -> Cmd msg
trackJsonError name error =
    messageToJs (TrackError name (Encode.object [ ( "message", errorToString error |> Encode.string ) ]))


trackError : String -> String -> Cmd msg
trackError name error =
    messageToJs (TrackError name (Encode.object [ ( "error", error |> Encode.string ) ]))


type alias MetaInfos =
    { title : Maybe String
    , description : Maybe String
    , canonical : Maybe Route
    , html : Maybe String
    , body : Maybe String
    }


type ElmMsg
    = Click HtmlId
    | MouseDown HtmlId
    | Focus HtmlId
    | Blur HtmlId
    | ScrollTo HtmlId String
    | Fullscreen (Maybe HtmlId)
    | SetMeta MetaInfos
    | AutofocusWithin HtmlId
    | GetProject OrganizationId ProjectId
    | ListProjects
    | LoadProject ProjectId
    | CreateProjectTmp Project
    | CreateProjectLocal OrganizationId Project
    | CreateProjectRemote Project
    | UpdateProject Project
    | MoveProjectTo Project ProjectStorage
    | DeleteProject ProjectInfo
    | GetUser Email
    | GetOwners ProjectId
    | SetOwners ProjectId (List UserId)
    | DownloadFile FileName FileContent
    | GetLocalFile String File
    | ObserveSizes (List HtmlId)
    | ListenKeys (Dict String (List Hotkey))
    | Confetti HtmlId
    | ConfettiPride
    | TrackPage String
    | TrackEvent String Value
    | TrackError String Value


type JsMsg
    = GotSizes (List SizeChange)
    | GotProjects ( List ( ProjectId, Decode.Error ), List ProjectInfo )
    | GotProject (Maybe (Result Decode.Error Project))
    | ProjectDeleted ProjectId
    | GotUser Email (Maybe UserLegacy)
    | GotOwners ProjectId (List UserLegacy)
    | GotLocalFile String File FileContent
    | GotHotkey String
    | GotKeyHold String Bool
    | GotToast String String
    | GotTableShow TableId (Maybe Position.CanvasGrid)
    | GotTableHide TableId
    | GotTableToggleColumns TableId
    | GotTablePosition TableId Position.CanvasGrid
    | GotTableMove TableId Delta
    | GotTableSelect TableId
    | GotTableColor TableId Color
    | GotColumnShow ColumnRef
    | GotColumnHide ColumnRef
    | GotColumnMove ColumnRef Int
    | GotFitToScreen
    | Error Value Decode.Error


messageToJs : ElmMsg -> Cmd msg
messageToJs message =
    elmToJs (elmEncoder message)


onJsMessage : (JsMsg -> msg) -> Sub msg
onJsMessage callback =
    jsToElm
        (\value ->
            case Decode.decodeValue jsDecoder value of
                Ok message ->
                    callback message

                Err error ->
                    callback (Error value error)
        )


elmEncoder : ElmMsg -> Value
elmEncoder elm =
    case elm of
        Click id ->
            Encode.object [ ( "kind", "Click" |> Encode.string ), ( "id", id |> Encode.string ) ]

        MouseDown id ->
            Encode.object [ ( "kind", "MouseDown" |> Encode.string ), ( "id", id |> Encode.string ) ]

        Focus id ->
            Encode.object [ ( "kind", "Focus" |> Encode.string ), ( "id", id |> Encode.string ) ]

        Blur id ->
            Encode.object [ ( "kind", "Blur" |> Encode.string ), ( "id", id |> Encode.string ) ]

        ScrollTo id position ->
            Encode.object [ ( "kind", "ScrollTo" |> Encode.string ), ( "id", id |> Encode.string ), ( "position", position |> Encode.string ) ]

        Fullscreen maybeId ->
            Encode.object [ ( "kind", "Fullscreen" |> Encode.string ), ( "maybeId", maybeId |> Encode.maybe Encode.string ) ]

        SetMeta meta ->
            Encode.object
                [ ( "kind", "SetMeta" |> Encode.string )
                , ( "title", meta.title |> Encode.maybe Encode.string )
                , ( "description", meta.description |> Encode.maybe Encode.string )
                , ( "canonical", meta.canonical |> Maybe.map Route.toUrl |> Encode.maybe Encode.string )
                , ( "html", meta.html |> Encode.maybe Encode.string )
                , ( "body", meta.body |> Encode.maybe Encode.string )
                ]

        AutofocusWithin id ->
            Encode.object [ ( "kind", "AutofocusWithin" |> Encode.string ), ( "id", id |> Encode.string ) ]

        GetProject organization project ->
            Encode.object [ ( "kind", "GetProject" |> Encode.string ), ( "organization", organization |> OrganizationId.encode ), ( "project", project |> ProjectId.encode ) ]

        ListProjects ->
            Encode.object [ ( "kind", "ListProjects" |> Encode.string ) ]

        LoadProject id ->
            Encode.object [ ( "kind", "LoadProject" |> Encode.string ), ( "id", id |> ProjectId.encode ) ]

        CreateProjectTmp project ->
            Encode.object [ ( "kind", "CreateProjectTmp" |> Encode.string ), ( "project", project |> Project.encode ) ]

        CreateProjectLocal organization project ->
            Encode.object [ ( "kind", "CreateProjectLocal" |> Encode.string ), ( "organization", organization |> OrganizationId.encode ), ( "project", project |> Project.encode ) ]

        CreateProjectRemote project ->
            Encode.object [ ( "kind", "CreateProjectRemote" |> Encode.string ), ( "project", project |> Project.encode ) ]

        UpdateProject project ->
            Encode.object [ ( "kind", "UpdateProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        MoveProjectTo project storage ->
            Encode.object [ ( "kind", "MoveProjectTo" |> Encode.string ), ( "project", project |> Project.encode ), ( "storage", storage |> ProjectStorage.encode ) ]

        DeleteProject project ->
            Encode.object [ ( "kind", "DeleteProject" |> Encode.string ), ( "project", project |> ProjectInfo.encode ) ]

        GetUser email ->
            Encode.object [ ( "kind", "GetUser" |> Encode.string ), ( "email", email |> Encode.string ) ]

        GetOwners project ->
            Encode.object [ ( "kind", "GetOwners" |> Encode.string ), ( "project", project |> ProjectId.encode ) ]

        SetOwners project users ->
            Encode.object [ ( "kind", "SetOwners" |> Encode.string ), ( "project", project |> ProjectId.encode ), ( "owners", users |> Encode.list UserId.encode ) ]

        DownloadFile filename content ->
            Encode.object [ ( "kind", "DownloadFile" |> Encode.string ), ( "filename", filename |> Encode.string ), ( "content", content |> Encode.string ) ]

        GetLocalFile sourceKind file ->
            Encode.object [ ( "kind", "GetLocalFile" |> Encode.string ), ( "sourceKind", sourceKind |> Encode.string ), ( "file", file |> FileValue.encode ) ]

        ObserveSizes ids ->
            Encode.object [ ( "kind", "ObserveSizes" |> Encode.string ), ( "ids", ids |> Encode.list Encode.string ) ]

        ListenKeys keys ->
            Encode.object [ ( "kind", "ListenKeys" |> Encode.string ), ( "keys", keys |> Encode.dict identity (Encode.list Hotkey.encode) ) ]

        Confetti id ->
            Encode.object [ ( "kind", "Confetti" |> Encode.string ), ( "id", id |> Encode.string ) ]

        ConfettiPride ->
            Encode.object [ ( "kind", "ConfettiPride" |> Encode.string ) ]

        TrackPage name ->
            Encode.object [ ( "kind", "TrackPage" |> Encode.string ), ( "name", name |> Encode.string ) ]

        TrackEvent name details ->
            Encode.object [ ( "kind", "TrackEvent" |> Encode.string ), ( "name", name |> Encode.string ), ( "details", details ) ]

        TrackError name details ->
            Encode.object [ ( "kind", "TrackError" |> Encode.string ), ( "name", name |> Encode.string ), ( "details", details ) ]


jsDecoder : Decoder JsMsg
jsDecoder =
    Decode.matchOn "kind"
        (\kind ->
            case kind of
                "GotSizes" ->
                    Decode.map GotSizes
                        (Decode.field "sizes"
                            (Decode.map4 SizeChange
                                (Decode.field "id" Decode.string)
                                (Decode.field "position" Position.decodeViewport)
                                (Decode.field "size" Size.decodeViewport)
                                (Decode.field "seeds" Delta.decode)
                                |> Decode.list
                            )
                        )

                "GotProjects" ->
                    Decode.map GotProjects (Decode.field "projects" projectInfosDecoder)

                "GotProject" ->
                    Decode.map GotProject (Decode.maybeField "project" projectDecoder)

                "ProjectDeleted" ->
                    Decode.map ProjectDeleted (Decode.field "id" ProjectId.decode)

                "GotUser" ->
                    Decode.map2 GotUser
                        (Decode.field "email" Decode.string)
                        (Decode.maybeField "user" UserLegacy.decode)

                "GotOwners" ->
                    Decode.map2 GotOwners
                        (Decode.field "project" ProjectId.decode)
                        (Decode.field "owners" (Decode.list UserLegacy.decode))

                "GotLocalFile" ->
                    Decode.map3 GotLocalFile
                        (Decode.field "sourceKind" Decode.string)
                        (Decode.field "file" FileValue.decoder)
                        (Decode.field "content" Decode.string)

                "GotHotkey" ->
                    Decode.map GotHotkey (Decode.field "id" Decode.string)

                "GotKeyHold" ->
                    Decode.map2 GotKeyHold (Decode.field "key" Decode.string) (Decode.field "start" Decode.bool)

                "GotToast" ->
                    Decode.map2 GotToast (Decode.field "level" Decode.string) (Decode.field "message" Decode.string)

                "GotTableShow" ->
                    Decode.map2 GotTableShow (Decode.field "id" TableId.decode) (Decode.maybeField "position" Position.decodeCanvasGrid)

                "GotTableHide" ->
                    Decode.map GotTableHide (Decode.field "id" TableId.decode)

                "GotTableToggleColumns" ->
                    Decode.map GotTableToggleColumns (Decode.field "id" TableId.decode)

                "GotTablePosition" ->
                    Decode.map2 GotTablePosition (Decode.field "id" TableId.decode) (Decode.field "position" Position.decodeCanvasGrid)

                "GotTableMove" ->
                    Decode.map2 GotTableMove (Decode.field "id" TableId.decode) (Decode.field "delta" Delta.decode)

                "GotTableSelect" ->
                    Decode.map GotTableSelect (Decode.field "id" TableId.decode)

                "GotTableColor" ->
                    Decode.map2 GotTableColor
                        (Decode.field "id" TableId.decode)
                        (Decode.field "color" Color.decodeColor)

                "GotColumnShow" ->
                    Decode.map GotColumnShow (Decode.field "ref" Decode.string |> Decode.map ColumnRef.fromString)

                "GotColumnHide" ->
                    Decode.map GotColumnHide (Decode.field "ref" Decode.string |> Decode.map ColumnRef.fromString)

                "GotColumnMove" ->
                    Decode.map2 GotColumnMove (Decode.field "ref" Decode.string |> Decode.map ColumnRef.fromString) (Decode.field "index" Decode.int)

                "GotFitToScreen" ->
                    Decode.succeed GotFitToScreen

                other ->
                    Decode.fail ("Not supported kind of JsMsg '" ++ other ++ "'")
        )


projectInfosDecoder : Decoder ( List ( ProjectId, Decode.Error ), List ProjectInfo )
projectInfosDecoder =
    Decode.list (Decode.tuple Decode.string Decode.value)
        |> Decode.map
            (\list ->
                list
                    |> List.map
                        (\( k, v ) ->
                            v
                                |> Decode.decodeValue ProjectInfo.decode
                                |> Result.mapError (\e -> ( k, e ))
                        )
                    |> List.resultCollect
            )


projectDecoder : Decoder (Result Decode.Error Project)
projectDecoder =
    Decode.map (Decode.decodeValue decodeProject) Decode.value


unhandledJsMsgError : JsMsg -> String
unhandledJsMsgError msg =
    "Unhandled JsMessage: "
        ++ (case msg of
                GotSizes _ ->
                    "GotSizes"

                GotProjects _ ->
                    "GotProjects"

                GotProject _ ->
                    "GotProject"

                ProjectDeleted _ ->
                    "ProjectDeleted"

                GotUser _ _ ->
                    "GotUser"

                GotOwners _ _ ->
                    "GotOwners"

                GotLocalFile _ _ _ ->
                    "GotLocalFile"

                GotHotkey _ ->
                    "GotHotkey"

                GotKeyHold _ _ ->
                    "GotKeyHold"

                GotToast _ _ ->
                    "GotToast"

                GotTableShow _ _ ->
                    "GotTableShow"

                GotTableHide _ ->
                    "GotTableHide"

                GotTableToggleColumns _ ->
                    "GotTableToggleColumns"

                GotTablePosition _ _ ->
                    "GotTablePosition"

                GotTableMove _ _ ->
                    "GotTableMove"

                GotTableSelect _ ->
                    "GotTableSelect"

                GotTableColor _ _ ->
                    "GotTableColor"

                GotColumnShow _ ->
                    "GotColumnShow"

                GotColumnHide _ ->
                    "GotColumnHide"

                GotColumnMove _ _ ->
                    "GotColumnMove"

                GotFitToScreen ->
                    "GotFitToScreen"

                Error _ _ ->
                    "Error"
           )


port elmToJs : Value -> Cmd msg


port jsToElm : (Value -> msg) -> Sub msg
