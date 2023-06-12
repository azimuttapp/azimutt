module PagesComponents.Organization_.Project_.Components.EmbedSourceParsingDialog exposing (Model, Msg(..), init, update, view)

import Components.Atoms.Button as Button
import Components.Molecules.Modal as Modal
import Conf
import Html exposing (Html, div, h3, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Libs.Maybe as Maybe
import Libs.Models.DatabaseUrl as DatabaseUrl
import Libs.Models.FileUrl as FileUrl
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Result as Result
import Libs.Tailwind as Tw
import Models.Project.Source exposing (Source)
import Models.ProjectInfo exposing (ProjectInfo)
import Services.DatabaseSource as DatabaseSource
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapDatabaseSourceMCmd, mapJsonSourceMCmd, mapPrismaSourceMCmd, mapSqlSourceMCmd)
import Services.PrismaSource as PrismaSource
import Services.SqlSource as SqlSource
import Time


type alias Model msg =
    { id : HtmlId
    , databaseSource : Maybe (DatabaseSource.Model msg)
    , sqlSource : Maybe (SqlSource.Model msg)
    , prismaSource : Maybe (PrismaSource.Model msg)
    , jsonSource : Maybe (JsonSource.Model msg)
    }


type Msg
    = EmbedDatabaseSource DatabaseSource.Msg
    | EmbedSqlSource SqlSource.Msg
    | EmbedPrismaSource PrismaSource.Msg
    | EmbedJsonSource JsonSource.Msg



-- INIT


init : (Source -> msg) -> (msg -> msg) -> (String -> msg) -> Maybe String -> Maybe String -> Maybe String -> Maybe String -> Maybe (Model msg)
init sourceParsed modalClose noop databaseSource sqlSource prismaSource jsonSource =
    databaseSource
        |> Maybe.orElse sqlSource
        |> Maybe.orElse prismaSource
        |> Maybe.orElse jsonSource
        |> Maybe.map
            (\_ ->
                { id = Conf.ids.sourceParsingDialog
                , databaseSource = databaseSource |> Maybe.map (\_ -> DatabaseSource.init Nothing (Result.fold (\_ -> noop "embed-load-database-has-errors") (sourceParsed >> modalClose)))
                , sqlSource =
                    sqlSource
                        |> Maybe.map
                            (\_ ->
                                SqlSource.init
                                    Nothing
                                    (\( parser, source ) ->
                                        if parser |> Maybe.any SqlSource.hasErrors then
                                            noop "embed-parse-sql-has-errors"

                                        else
                                            source |> Result.fold (\_ -> noop "embed-load-sql-has-errors") (sourceParsed >> modalClose)
                                    )
                            )
                , prismaSource = prismaSource |> Maybe.map (\_ -> PrismaSource.init Nothing (Result.fold (\_ -> noop "embed-load-prisma-has-errors") (sourceParsed >> modalClose)))
                , jsonSource = jsonSource |> Maybe.map (\_ -> JsonSource.init Nothing (Result.fold (\_ -> noop "embed-load-json-has-errors") (sourceParsed >> modalClose)))
                }
            )



-- UPDATE


update : (Msg -> msg) -> Time.Posix -> Maybe ProjectInfo -> Msg -> Model msg -> ( Model msg, Cmd msg )
update wrap now project msg model =
    case msg of
        EmbedDatabaseSource message ->
            model |> mapDatabaseSourceMCmd (DatabaseSource.update (EmbedDatabaseSource >> wrap) now project message)

        EmbedSqlSource message ->
            model |> mapSqlSourceMCmd (SqlSource.update (EmbedSqlSource >> wrap) now project message)

        EmbedPrismaSource message ->
            model |> mapPrismaSourceMCmd (PrismaSource.update (EmbedPrismaSource >> wrap) now project message)

        EmbedJsonSource message ->
            model |> mapJsonSourceMCmd (JsonSource.update (EmbedJsonSource >> wrap) now project message)



-- VIEW


view : (Msg -> msg) -> (Source -> msg) -> (msg -> msg) -> (String -> msg) -> Bool -> Model msg -> Html msg
view wrap sourceParsed modalClose noop opened model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal
        { id = model.id
        , titleId = titleId
        , isOpen = opened
        , onBackgroundClick = noop "close-source-parsing"
        }
        ((model.databaseSource |> Maybe.map (viewDatabaseSourceParsing wrap sourceParsed modalClose))
            |> Maybe.orElse (model.sqlSource |> Maybe.map (viewSqlSourceParsing wrap sourceParsed modalClose))
            |> Maybe.orElse (model.prismaSource |> Maybe.map (viewPrismaSourceParsing wrap sourceParsed modalClose))
            |> Maybe.orElse (model.jsonSource |> Maybe.map (viewJsonSourceParsing wrap sourceParsed modalClose))
            -- default case should not happen, see init function if it happen (at least one should be present)
            |> Maybe.withDefault [ div [] [ text "No source to parse in embed... Should never happen!" ] ]
        )


viewDatabaseSourceParsing : (Msg -> msg) -> (Source -> msg) -> (msg -> msg) -> DatabaseSource.Model msg -> List (Html msg)
viewDatabaseSourceParsing wrap sourceParsed modalClose model =
    viewParsing
        sourceParsed
        modalClose
        ((model.selectedUrl |> Maybe.andThen Result.toMaybe |> Maybe.map DatabaseUrl.databaseName)
            |> Maybe.withDefault "your"
        )
        (DatabaseSource.viewParsing (EmbedDatabaseSource >> wrap) model)
        model.parsedSource


viewSqlSourceParsing : (Msg -> msg) -> (Source -> msg) -> (msg -> msg) -> SqlSource.Model msg -> List (Html msg)
viewSqlSourceParsing wrap sourceParsed modalClose model =
    viewParsing
        sourceParsed
        modalClose
        ((model.selectedLocalFile |> Maybe.map .name)
            |> Maybe.orElse (model.selectedRemoteFile |> Maybe.andThen Result.toMaybe |> Maybe.map FileUrl.filename)
            |> Maybe.withDefault "your"
        )
        (SqlSource.viewParsing (EmbedSqlSource >> wrap) model)
        model.parsedSource


viewPrismaSourceParsing : (Msg -> msg) -> (Source -> msg) -> (msg -> msg) -> PrismaSource.Model msg -> List (Html msg)
viewPrismaSourceParsing wrap sourceParsed modalClose model =
    viewParsing
        sourceParsed
        modalClose
        ((model.selectedLocalFile |> Maybe.map .name)
            |> Maybe.orElse (model.selectedRemoteFile |> Maybe.andThen Result.toMaybe |> Maybe.map FileUrl.filename)
            |> Maybe.withDefault "your"
        )
        (PrismaSource.viewParsing (EmbedPrismaSource >> wrap) model)
        model.parsedSource


viewJsonSourceParsing : (Msg -> msg) -> (Source -> msg) -> (msg -> msg) -> JsonSource.Model msg -> List (Html msg)
viewJsonSourceParsing wrap sourceParsed modalClose model =
    viewParsing
        sourceParsed
        modalClose
        ((model.selectedLocalFile |> Maybe.map .name)
            |> Maybe.orElse (model.selectedRemoteFile |> Maybe.andThen Result.toMaybe |> Maybe.map FileUrl.filename)
            |> Maybe.withDefault "your"
        )
        (JsonSource.viewParsing (EmbedJsonSource >> wrap) model)
        model.parsedSource


viewParsing : (Source -> msg) -> (msg -> msg) -> String -> Html msg -> Maybe (Result String Source) -> List (Html msg)
viewParsing sourceParsed modalClose sourceName parsing parsedSource =
    [ h3 [ class "px-6 pt-6 text-lg leading-6 font-medium text-gray-900" ] [ text ("Parsing " ++ sourceName ++ " source...") ]
    , div [ class "px-6" ] [ parsing ]
    , div [ class "px-6 py-3 mt-6 flex items-center justify-between flex-row-reverse bg-gray-50 rounded-b-lg" ]
        [ Button.primary3 Tw.primary (parsedSource |> Maybe.andThen Result.toMaybe |> Maybe.mapOrElse (\source -> [ onClick (source |> sourceParsed |> modalClose) ]) [ disabled True ]) [ text "Open schema" ]
        ]
    ]
