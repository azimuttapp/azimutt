port module Ports exposing (JsMsg(..), activateTooltipsAndPopovers, click, dropProject, getSourceId, hideModal, hideOffcanvas, listenHotkeys, loadProjects, observeSize, observeTableSize, observeTablesSize, onJsMessage, readLocalFile, readRemoteFile, saveProject, showModal, toastError, toastInfo, toastWarning, track, trackError, trackJsonError, trackPage)

import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode as Decode exposing (Decoder, Value, errorToString)
import Json.Encode as Encode
import Libs.Hotkey exposing (Hotkey, hotkeyEncoder)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodePosition, decodeSize)
import Libs.List as L
import Libs.Models exposing (FileContent, FileUrl, SizeChange, Text, TrackEvent)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project as Project exposing (Project)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ProjectId as ProjectId exposing (ProjectId)
import Models.Project.SampleName exposing (SampleName)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.TableId as TableId exposing (TableId)
import Time


click : HtmlId -> Cmd msg
click id =
    messageToJs (Click id)


showModal : HtmlId -> Cmd msg
showModal id =
    messageToJs (ShowModal id)


hideModal : HtmlId -> Cmd msg
hideModal id =
    messageToJs (HideModal id)


hideOffcanvas : HtmlId -> Cmd msg
hideOffcanvas id =
    messageToJs (HideOffcanvas id)


activateTooltipsAndPopovers : Cmd msg
activateTooltipsAndPopovers =
    messageToJs ActivateTooltipsAndPopovers


toastInfo : Text -> Cmd msg
toastInfo message =
    showToast { kind = "info", message = message }


toastWarning : Text -> Cmd msg
toastWarning message =
    showToast { kind = "warning", message = message }


toastError : Text -> Cmd msg
toastError message =
    showToast { kind = "error", message = message }


showToast : Toast -> Cmd msg
showToast toast =
    messageToJs (ShowToast toast)


loadProjects : Cmd msg
loadProjects =
    messageToJs LoadProjects


saveProject : Project -> Cmd msg
saveProject project =
    messageToJs (SaveProject project)


dropProject : Project -> Cmd msg
dropProject project =
    messageToJs (DropProject project)


readLocalFile : Maybe ProjectId -> Maybe SourceId -> File -> Cmd msg
readLocalFile project source file =
    messageToJs (GetLocalFile project source file)


readRemoteFile : Maybe ProjectId -> Maybe SourceId -> FileUrl -> Maybe SampleName -> Cmd msg
readRemoteFile project source url sample =
    messageToJs (GetRemoteFile project source url sample)


getSourceId : ColumnRef -> ColumnRef -> Cmd msg
getSourceId src ref =
    messageToJs (GetSourceId src ref)


observeSizes : List HtmlId -> Cmd msg
observeSizes ids =
    messageToJs (ObserveSizes ids)


observeSize : HtmlId -> Cmd msg
observeSize id =
    observeSizes [ id ]


observeTableSize : TableId -> Cmd msg
observeTableSize id =
    observeSizes [ TableId.toHtmlId id ]


observeTablesSize : List TableId -> Cmd msg
observeTablesSize ids =
    observeSizes (List.map TableId.toHtmlId ids)


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


type ElmMsg
    = Click HtmlId
    | ShowModal HtmlId
    | HideModal HtmlId
    | HideOffcanvas HtmlId
    | ActivateTooltipsAndPopovers
    | ShowToast Toast
    | LoadProjects
    | SaveProject Project
    | DropProject Project
    | GetLocalFile (Maybe ProjectId) (Maybe SourceId) File
    | GetRemoteFile (Maybe ProjectId) (Maybe SourceId) FileUrl (Maybe SampleName)
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
    | GotRemoteFile Time.Posix ProjectId SourceId FileUrl FileContent (Maybe SampleName)
    | GotSourceId Time.Posix SourceId ColumnRef ColumnRef
    | GotHotkey String
    | Error Decode.Error


type alias Toast =
    { kind : String, message : Text }


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

        ShowModal id ->
            Encode.object [ ( "kind", "ShowModal" |> Encode.string ), ( "id", id |> Encode.string ) ]

        HideModal id ->
            Encode.object [ ( "kind", "HideModal" |> Encode.string ), ( "id", id |> Encode.string ) ]

        HideOffcanvas id ->
            Encode.object [ ( "kind", "HideOffcanvas" |> Encode.string ), ( "id", id |> Encode.string ) ]

        ActivateTooltipsAndPopovers ->
            Encode.object [ ( "kind", "ActivateTooltipsAndPopovers" |> Encode.string ) ]

        ShowToast toast ->
            Encode.object [ ( "kind", "ShowToast" |> Encode.string ), ( "toast", toast |> toastEncoder ) ]

        LoadProjects ->
            Encode.object [ ( "kind", "LoadProjects" |> Encode.string ) ]

        SaveProject project ->
            Encode.object [ ( "kind", "SaveProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        DropProject project ->
            Encode.object [ ( "kind", "DropProject" |> Encode.string ), ( "project", project |> Project.encode ) ]

        GetLocalFile project source file ->
            Encode.object [ ( "kind", "GetLocalFile" |> Encode.string ), ( "project", project |> E.maybe ProjectId.encode ), ( "source", source |> E.maybe SourceId.encode ), ( "file", file |> FileValue.encode ) ]

        GetRemoteFile project source url sample ->
            Encode.object [ ( "kind", "GetRemoteFile" |> Encode.string ), ( "project", project |> E.maybe ProjectId.encode ), ( "source", source |> E.maybe SourceId.encode ), ( "url", url |> Encode.string ), ( "sample", sample |> E.maybe Encode.string ) ]

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


toastEncoder : Toast -> Value
toastEncoder toast =
    Encode.object [ ( "kind", toast.kind |> Encode.string ), ( "message", toast.message |> Encode.string ) ]


jsDecoder : Decoder JsMsg
jsDecoder =
    D.matchOn "kind"
        (\kind ->
            case kind of
                "GotSizes" ->
                    Decode.field "sizes"
                        (Decode.map3 SizeChange
                            (Decode.field "id" Decode.string)
                            (Decode.field "position" decodePosition)
                            (Decode.field "size" decodeSize)
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
                        (D.maybeField "sample" Decode.string)

                "GotSourceId" ->
                    Decode.map4 GotSourceId
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "sourceId" SourceId.decode)
                        (Decode.field "src" ColumnRef.decode)
                        (Decode.field "ref" ColumnRef.decode)

                "GotHotkey" ->
                    Decode.field "id" Decode.string |> Decode.map GotHotkey

                other ->
                    Decode.fail ("Not supported kind of JsMsg '" ++ other ++ "'")
        )


projectsDecoder : Decoder ( List ( ProjectId, Decode.Error ), List Project )
projectsDecoder =
    Decode.list (D.tuple Decode.string Decode.value)
        |> Decode.map
            (\list ->
                list
                    |> List.map
                        (\( k, v ) ->
                            v
                                |> Decode.decodeValue Project.decode
                                |> Result.mapError (\e -> ( k, e ))
                        )
                    |> L.resultCollect
            )


port elmToJs : Value -> Cmd msg


port jsToElm : (Value -> msg) -> Sub msg
