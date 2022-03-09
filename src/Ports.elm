port module Ports exposing (HtmlContainers, JsMsg(..), autofocusWithin, blur, click, downloadFile, dropProject, focus, fullscreen, getSourceId, listenHotkeys, loadProjects, loadRemoteProject, mouseDown, observeSize, observeTableSize, observeTablesSize, onJsMessage, readLocalFile, readRemoteFile, saveProject, scrollTo, setClasses, track, trackError, trackJsonError, trackPage)

import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode as Decode exposing (Decoder, Value, errorToString)
import Json.Encode as Encode
import Libs.Hotkey exposing (Hotkey, hotkeyEncoder)
import Libs.Json.Decode as Decode
import Libs.Json.Encode as Encode
import Libs.List as List
import Libs.Models exposing (FileContent, SizeChange, TrackEvent)
import Libs.Models.FileName exposing (FileName)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Position as Position
import Libs.Models.Size as Size
import Models.Project as Project exposing (Project)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.TableId as TableId exposing (TableId)
import Storage.ProjectV2 exposing (decodeProject)
import Time


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


setClasses : HtmlContainers -> Cmd msg
setClasses payload =
    messageToJs (SetClasses payload)


loadProjects : Cmd msg
loadProjects =
    messageToJs LoadProjects


loadRemoteProject : String -> Cmd msg
loadRemoteProject projectUrl =
    messageToJs (LoadRemoteProject projectUrl)


saveProject : Project -> Cmd msg
saveProject project =
    messageToJs (SaveProject project)


downloadFile : FileName -> FileContent -> Cmd msg
downloadFile filename content =
    messageToJs (DownloadFile filename content)


dropProject : Project -> Cmd msg
dropProject project =
    messageToJs (DropProject project)


readLocalFile : Maybe ProjectId -> Maybe SourceId -> File -> Cmd msg
readLocalFile project source file =
    messageToJs (GetLocalFile project source file)


readRemoteFile : Maybe ProjectId -> Maybe SourceId -> FileUrl -> Maybe SampleKey -> Cmd msg
readRemoteFile project source url sample =
    messageToJs (GetRemoteFile project source url sample)


getSourceId : ColumnRef -> ColumnRef -> Cmd msg
getSourceId src ref =
    messageToJs (GetSourceId src ref)


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


type alias HtmlContainers =
    { html : String, body : String }


type ElmMsg
    = Click HtmlId
    | MouseDown HtmlId
    | Focus HtmlId
    | Blur HtmlId
    | ScrollTo HtmlId String
    | Fullscreen (Maybe HtmlId)
    | SetClasses HtmlContainers
    | AutofocusWithin HtmlId
    | LoadProjects
    | LoadRemoteProject FileUrl
    | SaveProject Project
    | DownloadFile FileName FileContent
    | DropProject Project
    | GetLocalFile (Maybe ProjectId) (Maybe SourceId) File
    | GetRemoteFile (Maybe ProjectId) (Maybe SourceId) FileUrl (Maybe SampleKey)
    | GetSourceId ColumnRef ColumnRef
    | ObserveSizes (List HtmlId)
    | ListenKeys (Dict String (List Hotkey))
    | TrackPage String
    | TrackEvent String Value
    | TrackError String Value


type JsMsg
    = GotSizes (List SizeChange)
    | GotProjects ( List ( ProjectId, Decode.Error ), List Project )
    | GotLocalFile Time.Posix ProjectId SourceId File FileContent
    | GotRemoteFile Time.Posix ProjectId SourceId FileUrl FileContent (Maybe SampleKey)
    | GotSourceId Time.Posix SourceId ColumnRef ColumnRef
    | GotHotkey String
    | GotKeyHold String Bool
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

        SetClasses { html, body } ->
            Encode.object [ ( "kind", "SetClasses" |> Encode.string ), ( "html", html |> Encode.string ), ( "body", body |> Encode.string ) ]

        AutofocusWithin id ->
            Encode.object [ ( "kind", "AutofocusWithin" |> Encode.string ), ( "id", id |> Encode.string ) ]

        LoadProjects ->
            Encode.object [ ( "kind", "LoadProjects" |> Encode.string ) ]

        LoadRemoteProject projectUrl ->
            Encode.object [ ( "kind", "LoadRemoteProject" |> Encode.string ), ( "projectUrl", projectUrl |> Encode.string ) ]

        SaveProject project ->
            Encode.object [ ( "kind", "SaveProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        DownloadFile filename content ->
            Encode.object [ ( "kind", "DownloadFile" |> Encode.string ), ( "filename", filename |> Encode.string ), ( "content", content |> Encode.string ) ]

        DropProject project ->
            Encode.object [ ( "kind", "DropProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        GetLocalFile project source file ->
            Encode.object [ ( "kind", "GetLocalFile" |> Encode.string ), ( "project", project |> Encode.maybe ProjectId.encode ), ( "source", source |> Encode.maybe SourceId.encode ), ( "file", file |> FileValue.encode ) ]

        GetRemoteFile project source url sample ->
            Encode.object [ ( "kind", "GetRemoteFile" |> Encode.string ), ( "project", project |> Encode.maybe ProjectId.encode ), ( "source", source |> Encode.maybe SourceId.encode ), ( "url", url |> Encode.string ), ( "sample", sample |> Encode.maybe Encode.string ) ]

        GetSourceId src ref ->
            Encode.object [ ( "kind", "GetSourceId" |> Encode.string ), ( "src", src |> ColumnRef.encode ), ( "ref", ref |> ColumnRef.encode ) ]

        ObserveSizes ids ->
            Encode.object [ ( "kind", "ObserveSizes" |> Encode.string ), ( "ids", ids |> Encode.list Encode.string ) ]

        ListenKeys keys ->
            Encode.object [ ( "kind", "ListenKeys" |> Encode.string ), ( "keys", keys |> Encode.dict identity (Encode.list hotkeyEncoder) ) ]

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
                    Decode.field "sizes"
                        (Decode.map4 SizeChange
                            (Decode.field "id" Decode.string)
                            (Decode.field "position" Position.decode)
                            (Decode.field "size" Size.decode)
                            (Decode.field "seeds" Position.decode)
                            |> Decode.list
                        )
                        |> Decode.map GotSizes

                "GotProjects" ->
                    Decode.field "projects" projectsDecoder |> Decode.map GotProjects

                "GotLocalFile" ->
                    Decode.map5 GotLocalFile
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "projectId" Decode.string)
                        (Decode.field "sourceId" SourceId.decode)
                        (Decode.field "file" FileValue.decoder)
                        (Decode.field "content" Decode.string)

                "GotRemoteFile" ->
                    Decode.map6 GotRemoteFile
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "projectId" Decode.string)
                        (Decode.field "sourceId" SourceId.decode)
                        (Decode.field "url" Decode.string)
                        (Decode.field "content" Decode.string)
                        (Decode.maybeField "sample" Decode.string)

                "GotSourceId" ->
                    Decode.map4 GotSourceId
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "sourceId" SourceId.decode)
                        (Decode.field "src" ColumnRef.decode)
                        (Decode.field "ref" ColumnRef.decode)

                "GotHotkey" ->
                    Decode.field "id" Decode.string |> Decode.map GotHotkey

                "GotKeyHold" ->
                    Decode.map2 GotKeyHold
                        (Decode.field "key" Decode.string)
                        (Decode.field "start" Decode.bool)

                other ->
                    Decode.fail ("Not supported kind of JsMsg '" ++ other ++ "'")
        )


projectsDecoder : Decoder ( List ( ProjectId, Decode.Error ), List Project )
projectsDecoder =
    Decode.list (Decode.tuple Decode.string Decode.value)
        |> Decode.map
            (\list ->
                list
                    |> List.map
                        (\( k, v ) ->
                            v
                                |> Decode.decodeValue decodeProject
                                |> Result.mapError (\e -> ( k, e ))
                        )
                    |> List.resultCollect
            )


port elmToJs : Value -> Cmd msg


port jsToElm : (Value -> msg) -> Sub msg
