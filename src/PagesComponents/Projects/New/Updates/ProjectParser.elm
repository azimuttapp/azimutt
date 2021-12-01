module PagesComponents.Projects.New.Updates.ProjectParser exposing (Model, Msg(..), init, update)

import DataSources.SqlParser.FileParser as FileParser exposing (SchemaError, SqlSchema)
import DataSources.SqlParser.StatementParser exposing (Command)
import DataSources.SqlParser.Utils.Types exposing (ParseError, SqlStatement)
import Dict exposing (Dict)
import Libs.Dict as D
import Libs.Maybe as M
import Libs.Models exposing (FileContent, FileLineContent)


type alias Model msg =
    { cpt : Int
    , fileContent : FileContent
    , lines : Maybe (List FileLineContent)
    , statements : Maybe (Dict Int SqlStatement)
    , commands : Maybe (Dict Int ( SqlStatement, Result (List ParseError) Command ))
    , schemaIndex : Int
    , schemaErrors : List (List SchemaError)
    , schema : Maybe SqlSchema
    , buildMsg : Msg -> msg
    , buildProject : msg
    }


type Msg
    = BuildLines
    | BuildStatements
    | BuildCommand
    | EvolveSchema


init : FileContent -> (Msg -> msg) -> msg -> Model msg
init fileContent buildMsg buildProject =
    { cpt = 0
    , fileContent = fileContent
    , lines = Nothing
    , statements = Nothing
    , commands = Nothing
    , schemaIndex = 0
    , schemaErrors = []
    , schema = Nothing
    , buildMsg = buildMsg
    , buildProject = buildProject
    }


update : Msg -> Model msg -> ( Model msg, msg )
update msg model =
    (case msg of
        BuildLines ->
            ( { model | lines = model.fileContent |> FileParser.parseLines |> Just }, model.buildMsg BuildStatements )

        BuildStatements ->
            model.lines |> M.mapOrElse (\l -> l |> FileParser.parseStatements |> (\statements -> ( { model | statements = statements |> D.fromIndexedList |> Just }, model.buildMsg BuildCommand ))) ( model, model.buildMsg BuildStatements )

        BuildCommand ->
            let
                index : Int
                index =
                    model.commands |> Maybe.withDefault Dict.empty |> Dict.size
            in
            model.statements
                |> Maybe.withDefault Dict.empty
                |> Dict.get index
                |> Maybe.map (\s -> ( { model | commands = model.commands |> Maybe.withDefault Dict.empty |> Dict.insert index ( s, s |> FileParser.parseCommand ) |> Just }, model.buildMsg BuildCommand ))
                |> Maybe.withDefault ( model, model.buildMsg EvolveSchema )

        EvolveSchema ->
            model.commands
                |> Maybe.withDefault Dict.empty
                |> Dict.get model.schemaIndex
                |> Maybe.map
                    (\( s, c ) ->
                        case c of
                            Ok cmd ->
                                case model.schema |> Maybe.withDefault Dict.empty |> FileParser.evolve ( s, cmd ) of
                                    Ok schema ->
                                        ( { model | schemaIndex = model.schemaIndex + 1, schema = Just schema }, model.buildMsg EvolveSchema )

                                    Err errors ->
                                        ( { model | schemaIndex = model.schemaIndex + 1, schemaErrors = errors :: model.schemaErrors }, model.buildMsg EvolveSchema )

                            Err _ ->
                                ( { model | schemaIndex = model.schemaIndex + 1 }, model.buildMsg EvolveSchema )
                    )
                |> Maybe.withDefault ( model, model.buildProject )
    )
        |> Tuple.mapFirst incCpt


incCpt : Model msg -> Model msg
incCpt model =
    { model | cpt = model.cpt + 1 }
