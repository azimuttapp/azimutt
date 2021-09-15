port module Ports exposing (JsMsg(..), activateTooltipsAndPopovers, click, dropProject, hideModal, hideOffcanvas, listenHotkeys, loadFile, loadProjects, observeSize, observeTableSize, observeTablesSize, onJsMessage, readFile, saveProject, showModal, toastError, toastInfo, toastWarning, track, trackErrorList, trackJsonError, trackPage)

import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode as Decode exposing (Decoder, Value, errorToString)
import Json.Encode as Encode
import Libs.Hotkey exposing (Hotkey, hotkeyEncoder)
import Libs.Json.Decode as D
import Libs.Json.Encode as E
import Libs.Json.Formats exposing (decodeSize)
import Libs.List as L
import Libs.Models exposing (FileContent, FileUrl, HtmlId, SizeChange, Text, TrackEvent)
import Models.Project exposing (Project, ProjectId, ProjectSourceId, SampleName, TableId, decodeProject, encodeProject, tableIdAsHtmlId)
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


readFile : File -> Cmd msg
readFile file =
    messageToJs (ReadFile file)


loadFile : FileUrl -> Maybe SampleName -> Cmd msg
loadFile url sample =
    messageToJs (LoadFile url sample)


observeSizes : List HtmlId -> Cmd msg
observeSizes ids =
    messageToJs (ObserveSizes ids)


observeSize : HtmlId -> Cmd msg
observeSize id =
    observeSizes [ id ]


observeTableSize : TableId -> Cmd msg
observeTableSize id =
    observeSizes [ tableIdAsHtmlId id ]


observeTablesSize : List TableId -> Cmd msg
observeTablesSize ids =
    observeSizes (List.map tableIdAsHtmlId ids)


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


trackErrorList : String -> List String -> Cmd msg
trackErrorList name errors =
    messageToJs (TrackError name (Encode.object [ ( "errors", errors |> Encode.list Encode.string ) ]))


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
    | ReadFile File
    | LoadFile FileUrl (Maybe SampleName)
    | ObserveSizes (List HtmlId)
    | ListenKeys (Dict String (List Hotkey))
    | TrackPage String
    | TrackEvent String Value
    | TrackError String Value


type JsMsg
    = ProjectsLoaded ( List ( ProjectId, Decode.Error ), List Project )
    | FileRead Time.Posix ProjectId ProjectSourceId File FileContent
    | FileLoaded Time.Posix ProjectId ProjectSourceId FileUrl FileContent (Maybe SampleName)
    | SizesChanged (List SizeChange)
    | HotkeyUsed String
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
            Encode.object [ ( "kind", "SaveProject" |> Encode.string ), ( "project", project |> encodeProject ) ]

        DropProject project ->
            Encode.object [ ( "kind", "DropProject" |> Encode.string ), ( "project", project |> encodeProject ) ]

        ReadFile file ->
            Encode.object [ ( "kind", "ReadFile" |> Encode.string ), ( "file", file |> FileValue.encode ) ]

        LoadFile url sample ->
            Encode.object [ ( "kind", "LoadFile" |> Encode.string ), ( "url", url |> Encode.string ), ( "sample", sample |> E.maybe Encode.string ) ]

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
                "ProjectsLoaded" ->
                    Decode.field "projects" projectsDecoder |> Decode.map ProjectsLoaded

                "FileRead" ->
                    Decode.map5 FileRead
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "projectId" Decode.string)
                        (Decode.field "sourceId" Decode.string)
                        (Decode.field "file" FileValue.decoder)
                        (Decode.field "content" Decode.string)

                "FileLoaded" ->
                    Decode.map6 FileLoaded
                        (Decode.field "now" Decode.int |> Decode.map Time.millisToPosix)
                        (Decode.field "projectId" Decode.string)
                        (Decode.field "sourceId" Decode.string)
                        (Decode.field "url" Decode.string)
                        (Decode.field "content" Decode.string)
                        (D.maybeField "sample" Decode.string)

                "SizesChanged" ->
                    Decode.field "sizes"
                        (Decode.map2 (\id size -> { id = id, size = size })
                            (Decode.field "id" Decode.string)
                            (Decode.field "size" decodeSize)
                            |> Decode.list
                        )
                        |> Decode.map SizesChanged

                "HotkeyUsed" ->
                    Decode.field "id" Decode.string |> Decode.map HotkeyUsed

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
                                |> Decode.decodeValue decodeProject
                                |> Result.mapError (\e -> ( k, e ))
                        )
                    |> L.resultCollect
            )


port elmToJs : Value -> Cmd msg


port jsToElm : (Value -> msg) -> Sub msg
