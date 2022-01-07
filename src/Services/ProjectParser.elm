module Services.ProjectParser exposing (init, update)

import DataSources.SqlParser.FileParser as FileParser
import Dict
import Libs.Dict as D
import Libs.Maybe as M
import Libs.Models exposing (FileContent)
import Services.SourceParsing.Models exposing (ParsingMsg(..), ParsingState)


init : FileContent -> (ParsingMsg -> msg) -> msg -> ParsingState msg
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


update : ParsingMsg -> ParsingState msg -> ( ParsingState msg, msg )
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


incCpt : ParsingState msg -> ParsingState msg
incCpt model =
    { model | cpt = model.cpt + 1 }
