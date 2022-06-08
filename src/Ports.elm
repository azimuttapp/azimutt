port module Ports exposing (JsMsg(..), LoginInfo(..), MetaInfos, autofocusWithin, blur, click, confetti, confettiPride, createProject, downloadFile, dropProject, focus, fullscreen, getOwners, getUser, listProjects, listenHotkeys, loadProject, loadRemoteProject, login, logout, mouseDown, moveProjectTo, observeSize, observeTableSize, observeTablesSize, onJsMessage, readLocalFile, readRemoteFile, scrollTo, setMeta, setOwners, track, trackError, trackJsonError, trackPage, unhandledJsMsgError, updateProject, updateUser)

import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode as Decode exposing (Decoder, Value, errorToString)
import Json.Encode as Encode
import Libs.Delta as Delta exposing (Delta)
import Libs.Hotkey exposing (Hotkey, hotkeyEncoder)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Models exposing (FileContent, SizeChange, TrackEvent)
import Libs.Models.Email exposing (Email)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size
import Libs.Tailwind as Color exposing (Color)
import Models.Project as Project exposing (Project)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.GridPosition as GridPosition
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.ProjectStorage as ProjectStorage exposing (ProjectStorage)
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Route as Route exposing (Route)
import Models.User as User exposing (User)
import Models.UserId as UserId exposing (UserId)
import PagesComponents.Projects.Id_.Models.ProjectInfo as ProjectInfo exposing (ProjectInfo)
import Storage.ProjectV2 exposing (decodeProject)
import Time
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


login : LoginInfo -> Maybe String -> Cmd msg
login info redirect =
    messageToJs (Login info redirect)


logout : Cmd msg
logout =
    messageToJs Logout


setMeta : MetaInfos -> Cmd msg
setMeta payload =
    messageToJs (SetMeta payload)


listProjects : Cmd msg
listProjects =
    messageToJs ListProjects


loadProject : ProjectId -> Cmd msg
loadProject id =
    messageToJs (LoadProject id)


loadRemoteProject : String -> Cmd msg
loadRemoteProject projectUrl =
    messageToJs (LoadRemoteProject projectUrl)


createProject : Project -> Cmd msg
createProject project =
    messageToJs (CreateProject project)


updateProject : Project -> Cmd msg
updateProject project =
    messageToJs (UpdateProject project)


moveProjectTo : Project -> ProjectStorage -> Cmd msg
moveProjectTo project storage =
    messageToJs (MoveProjectTo project storage)


getUser : Email -> Cmd msg
getUser email =
    messageToJs (GetUser email)


updateUser : User -> Cmd msg
updateUser user =
    messageToJs (UpdateUser user)


getOwners : ProjectId -> Cmd msg
getOwners projectId =
    messageToJs (GetOwners projectId)


setOwners : ProjectId -> List UserId -> Cmd msg
setOwners projectId owners =
    messageToJs (SetOwners projectId owners)


downloadFile : FileName -> FileContent -> Cmd msg
downloadFile filename content =
    messageToJs (DownloadFile filename content)


dropProject : ProjectInfo -> Cmd msg
dropProject project =
    Cmd.batch [ messageToJs (DropProject project), track (Track.deleteProject project) ]


readLocalFile : Maybe ProjectId -> Maybe SourceId -> File -> Cmd msg
readLocalFile project source file =
    messageToJs (GetLocalFile project source file)


readRemoteFile : Maybe ProjectId -> Maybe SourceId -> FileUrl -> Maybe SampleKey -> Cmd msg
readRemoteFile project source url sample =
    messageToJs (GetRemoteFile project source url sample)


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
    | Login LoginInfo (Maybe String)
    | Logout
    | ListProjects
    | LoadProject ProjectId
    | LoadRemoteProject FileUrl
    | CreateProject Project
    | UpdateProject Project
    | MoveProjectTo Project ProjectStorage
    | GetUser Email
    | UpdateUser User
    | GetOwners ProjectId
    | SetOwners ProjectId (List UserId)
    | DownloadFile FileName FileContent
    | DropProject ProjectInfo
    | GetLocalFile (Maybe ProjectId) (Maybe SourceId) File
    | GetRemoteFile (Maybe ProjectId) (Maybe SourceId) FileUrl (Maybe SampleKey)
    | ObserveSizes (List HtmlId)
    | ListenKeys (Dict String (List Hotkey))
    | Confetti HtmlId
    | ConfettiPride
    | TrackPage String
    | TrackEvent String Value
    | TrackError String Value


type LoginInfo
    = Github
    | MagicLink Email


type JsMsg
    = GotSizes (List SizeChange)
    | GotLogin User
    | GotLogout
    | GotProjects ( List ( ProjectId, Decode.Error ), List ProjectInfo )
    | GotProject (Maybe (Result Decode.Error Project))
    | GotUser Email (Maybe User)
    | GotOwners ProjectId (List User)
    | ProjectDropped ProjectId
    | GotLocalFile Time.Posix ProjectId SourceId File FileContent
    | GotRemoteFile Time.Posix ProjectId SourceId FileUrl FileContent (Maybe SampleKey)
    | GotHotkey String
    | GotKeyHold String Bool
    | GotToast String String
    | GotTableShow TableId (Maybe Position)
    | GotTableHide TableId
    | GotTableToggleColumns TableId
    | GotTablePosition TableId Position
    | GotTableMove TableId Delta
    | GotTableSelect TableId
    | GotTableColor TableId Color
    | GotColumnShow ColumnRef
    | GotColumnHide ColumnRef
    | GotColumnMove ColumnRef Int
    | GotFitToScreen
    | GotResetCanvas
    | Error Decode.Error


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
                    callback (Error error)
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

        Login info redirect ->
            Encode.object [ ( "kind", "Login" |> Encode.string ), ( "info", info |> encodeLoginInfo ), ( "redirect", redirect |> Encode.maybe Encode.string ) ]

        Logout ->
            Encode.object [ ( "kind", "Logout" |> Encode.string ) ]

        ListProjects ->
            Encode.object [ ( "kind", "ListProjects" |> Encode.string ) ]

        LoadProject id ->
            Encode.object [ ( "kind", "LoadProject" |> Encode.string ), ( "id", id |> ProjectId.encode ) ]

        LoadRemoteProject projectUrl ->
            Encode.object [ ( "kind", "LoadRemoteProject" |> Encode.string ), ( "projectUrl", projectUrl |> Encode.string ) ]

        CreateProject project ->
            Encode.object [ ( "kind", "CreateProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        UpdateProject project ->
            Encode.object [ ( "kind", "UpdateProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        MoveProjectTo project storage ->
            Encode.object [ ( "kind", "MoveProjectTo" |> Encode.string ), ( "project", project |> Project.encode ), ( "storage", storage |> ProjectStorage.encode ) ]

        GetUser email ->
            Encode.object [ ( "kind", "GetUser" |> Encode.string ), ( "email", email |> Encode.string ) ]

        UpdateUser user ->
            Encode.object [ ( "kind", "UpdateUser" |> Encode.string ), ( "user", user |> User.encode ) ]

        GetOwners project ->
            Encode.object [ ( "kind", "GetOwners" |> Encode.string ), ( "project", project |> ProjectId.encode ) ]

        SetOwners project users ->
            Encode.object [ ( "kind", "SetOwners" |> Encode.string ), ( "project", project |> ProjectId.encode ), ( "owners", users |> Encode.list UserId.encode ) ]

        DownloadFile filename content ->
            Encode.object [ ( "kind", "DownloadFile" |> Encode.string ), ( "filename", filename |> Encode.string ), ( "content", content |> Encode.string ) ]

        DropProject project ->
            Encode.object [ ( "kind", "DropProject" |> Encode.string ), ( "project", project |> ProjectInfo.encode ) ]

        GetLocalFile project source file ->
            Encode.object [ ( "kind", "GetLocalFile" |> Encode.string ), ( "project", project |> Encode.maybe ProjectId.encode ), ( "source", source |> Encode.maybe SourceId.encode ), ( "file", file |> FileValue.encode ) ]

        GetRemoteFile project source url sample ->
            Encode.object [ ( "kind", "GetRemoteFile" |> Encode.string ), ( "project", project |> Encode.maybe ProjectId.encode ), ( "source", source |> Encode.maybe SourceId.encode ), ( "url", url |> Encode.string ), ( "sample", sample |> Encode.maybe Encode.string ) ]

        ObserveSizes ids ->
            Encode.object [ ( "kind", "ObserveSizes" |> Encode.string ), ( "ids", ids |> Encode.list Encode.string ) ]

        ListenKeys keys ->
            Encode.object [ ( "kind", "ListenKeys" |> Encode.string ), ( "keys", keys |> Encode.dict identity (Encode.list hotkeyEncoder) ) ]

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
                                (Decode.field "position" GridPosition.decode)
                                (Decode.field "size" Size.decode)
                                -- don't round seeds, use Position instead of GridPosition
                                (Decode.field "seeds" Position.decode)
                                |> Decode.list
                            )
                        )

                "GotLogin" ->
                    Decode.map GotLogin (Decode.field "user" User.decode)

                "GotLogout" ->
                    Decode.succeed GotLogout

                "GotProjects" ->
                    Decode.map GotProjects (Decode.field "projects" projectInfosDecoder)

                "GotProject" ->
                    Decode.map GotProject (Decode.maybeField "project" projectDecoder)

                "GotUser" ->
                    Decode.map2 GotUser
                        (Decode.field "email" Decode.string)
                        (Decode.maybeField "user" User.decode)

                "GotOwners" ->
                    Decode.map2 GotOwners
                        (Decode.field "project" ProjectId.decode)
                        (Decode.field "owners" (Decode.list User.decode))

                "ProjectDropped" ->
                    Decode.map ProjectDropped (Decode.field "id" ProjectId.decode)

                "GotLocalFile" ->
                    Decode.map5 GotLocalFile
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "projectId" ProjectId.decode)
                        (Decode.field "sourceId" SourceId.decode)
                        (Decode.field "file" FileValue.decoder)
                        (Decode.field "content" Decode.string)

                "GotRemoteFile" ->
                    Decode.map6 GotRemoteFile
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "projectId" ProjectId.decode)
                        (Decode.field "sourceId" SourceId.decode)
                        (Decode.field "url" Decode.string)
                        (Decode.field "content" Decode.string)
                        (Decode.maybeField "sample" Decode.string)

                "GotHotkey" ->
                    Decode.map GotHotkey (Decode.field "id" Decode.string)

                "GotKeyHold" ->
                    Decode.map2 GotKeyHold (Decode.field "key" Decode.string) (Decode.field "start" Decode.bool)

                "GotToast" ->
                    Decode.map2 GotToast (Decode.field "level" Decode.string) (Decode.field "message" Decode.string)

                "GotTableShow" ->
                    Decode.map2 GotTableShow (Decode.field "id" TableId.decode) (Decode.maybeField "position" GridPosition.decode)

                "GotTableHide" ->
                    Decode.map GotTableHide (Decode.field "id" TableId.decode)

                "GotTableToggleColumns" ->
                    Decode.map GotTableToggleColumns (Decode.field "id" TableId.decode)

                "GotTablePosition" ->
                    Decode.map2 GotTablePosition (Decode.field "id" TableId.decode) (Decode.field "position" GridPosition.decode)

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

                "GotResetCanvas" ->
                    Decode.succeed GotResetCanvas

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


encodeLoginInfo : LoginInfo -> Encode.Value
encodeLoginInfo info =
    case info of
        Github ->
            Encode.object [ ( "kind", "Github" |> Encode.string ) ]

        MagicLink email ->
            Encode.object [ ( "kind", "MagicLink" |> Encode.string ), ( "email", email |> Encode.string ) ]


unhandledJsMsgError : JsMsg -> String
unhandledJsMsgError msg =
    "Unhandled JsMessage: "
        ++ (case msg of
                GotSizes _ ->
                    "GotSizes"

                GotLogin _ ->
                    "GotLogin"

                GotLogout ->
                    "GotLogout"

                GotProjects _ ->
                    "GotProjects"

                GotProject _ ->
                    "GotProject"

                GotUser _ _ ->
                    "GotUser"

                GotOwners _ _ ->
                    "GotOwners"

                ProjectDropped _ ->
                    "ProjectDropped"

                GotLocalFile _ _ _ _ _ ->
                    "GotLocalFile"

                GotRemoteFile _ _ _ _ _ _ ->
                    "GotRemoteFile"

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

                GotResetCanvas ->
                    "GotResetCanvas"

                Error _ ->
                    "Error"
           )


port elmToJs : Value -> Cmd msg


port jsToElm : (Value -> msg) -> Sub msg
