module Services.JsonSource exposing (Model, Msg(..), gotLocalFile, gotRemoteFile, init, kind, update, viewInput, viewParsing)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.FileInput as FileInput
import DataSources.JsonSourceParser.JsonAdapter as JsonAdapter
import DataSources.JsonSourceParser.JsonSource as JsonSource exposing (JsonSource)
import FileValue exposing (File)
import Html exposing (Html, div, p, span, text)
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.Maybe as Maybe
import Libs.Models exposing (FileContent)
import Libs.Models.FileUrl exposing (FileUrl)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Task as T
import Models.Project.SampleKey exposing (SampleKey)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId exposing (SourceId)
import Models.SourceInfo as SourceInfo exposing (SourceInfo)
import Ports
import Services.Lenses exposing (setParsedSchema, setParsedSource)
import Time
import Track


type alias Model msg =
    { source : Maybe Source
    , selectedLocalFile : Maybe File
    , selectedRemoteFile : Maybe FileUrl
    , loadedFile : Maybe ( SourceInfo, FileContent )
    , parsedSchema : Maybe (Result Decode.Error JsonSource)
    , parsedSource : Maybe (Result String Source)
    , callback : Result String Source -> msg
    }


type Msg
    = UpdateRemoteFile FileUrl
    | SelectRemoteFile FileUrl
    | SelectLocalFile File
    | FileLoaded SourceInfo FileContent
    | ParseSource
    | BuildSource



-- INIT


init : Maybe Source -> (Result String Source -> msg) -> Model msg
init source callback =
    { source = source
    , selectedLocalFile = Nothing
    , selectedRemoteFile = Nothing
    , loadedFile = Nothing
    , parsedSchema = Nothing
    , parsedSource = Nothing
    , callback = callback
    }



-- UPDATE


update : (Msg -> msg) -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap msg model =
    case msg of
        UpdateRemoteFile url ->
            ( { model | selectedRemoteFile = B.cond (url == "") Nothing (Just url) }, Cmd.none )

        SelectRemoteFile url ->
            ( init model.source model.callback |> (\m -> { m | selectedRemoteFile = Just url })
            , Ports.readRemoteFile kind url Nothing
            )

        SelectLocalFile file ->
            ( init model.source model.callback |> (\m -> { m | selectedLocalFile = Just file })
            , Ports.readLocalFile kind file
            )

        FileLoaded sourceInfo fileContent ->
            ( { model | loadedFile = Just ( sourceInfo, fileContent ) }
            , T.send (ParseSource |> wrap)
            )

        ParseSource ->
            model.loadedFile
                |> Maybe.map (\( _, json ) -> ( model |> setParsedSchema (json |> Decode.decodeString JsonSource.decode |> Just), T.send (BuildSource |> wrap) ))
                |> Maybe.withDefault ( model, Cmd.none )

        BuildSource ->
            Maybe.map2 (\( info, _ ) schema -> schema |> Result.map (JsonAdapter.buildJsonSource info) |> Result.mapError Decode.errorToString)
                model.loadedFile
                model.parsedSchema
                |> Maybe.map (\source -> ( model |> setParsedSource (source |> Just), Cmd.batch [ T.send (model.callback source), Ports.track (Track.parsedJsonSource source) ] ))
                |> Maybe.withDefault ( model, Cmd.none )



-- SUBSCRIPTIONS


kind : String
kind =
    "json-source"


gotLocalFile : Time.Posix -> SourceId -> File -> FileContent -> Msg
gotLocalFile now sourceId file content =
    FileLoaded (SourceInfo.jsonLocal now sourceId file) content


gotRemoteFile : Time.Posix -> SourceId -> FileUrl -> FileContent -> Maybe SampleKey -> Msg
gotRemoteFile now sourceId url content sample =
    FileLoaded (SourceInfo.jsonRemote now sourceId url content sample) content



-- VIEW


viewInput : HtmlId -> (File -> msg) -> msg -> Html msg
viewInput htmlId onSelect noop =
    FileInput.input
        { id = htmlId
        , onDrop = \f _ -> onSelect f
        , onOver = \_ _ -> noop
        , onLeave = Nothing
        , onSelect = onSelect
        , content =
            div [ css [ "space-y-1 text-center" ] ]
                [ Icon.outline2x DocumentAdd "mx-auto"
                , p [] [ span [ css [ "text-primary-600" ] ] [ text "Upload your JSON schema" ], text " or drag and drop" ]
                , p [ css [ "text-xs" ] ] [ text ".json file only" ]
                ]
        , mimes = [ ".json" ]
        }


viewParsing : (Msg -> msg) -> Model msg -> Html msg
viewParsing _ model =
    div []
        [ div [] [ text "viewParsing JSON source" ]
        , div [] [ text (model.loadedFile |> Maybe.mapOrElse (\_ -> "is loaded") "not loaded") ]
        , div [] [ text (model.parsedSchema |> Maybe.mapOrElse (\_ -> "is parsed") "not parsed") ]
        , div [] [ text (model.parsedSource |> Maybe.mapOrElse (\_ -> "is build") "not build") ]
        ]
