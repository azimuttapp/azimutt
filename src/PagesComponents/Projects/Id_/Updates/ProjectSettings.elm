module PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import DataSources.SqlParser.ProjectAdapter exposing (buildSourceFromSql)
import Dict
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Ned as Ned
import Libs.Task as T
import Models.ColumnOrder as ColumnOrder exposing (ColumnOrder)
import Models.Project as Project exposing (Project)
import Models.Project.Column exposing (Column)
import Models.Project.Layout exposing (Layout)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Table exposing (Table)
import Models.Project.TableProps exposing (TableProps)
import PagesComponents.App.Updates.Helpers exposing (setLayout, setProject, setSettings)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), PSParsingMsg(..), ProjectSettingsDialog, ProjectSettingsMsg(..), SourceParsing, SourceUploadDialog, toastInfo)
import Ports exposing (observeTablesSize, readLocalFile, track)
import Services.ProjectParser as ProjectParser
import Services.SourceParsing.Models exposing (ParsingMsg(..))
import Tracking


type alias Model x =
    { x
        | project : Maybe Project
        , settings : Maybe ProjectSettingsDialog
        , sourceUpload : Maybe SourceUploadDialog
    }


handleProjectSettings : ProjectSettingsMsg -> Project -> Model x -> ( Model x, Cmd Msg )
handleProjectSettings msg project model =
    case msg of
        PSOpen ->
            ( { model | settings = Just { id = Conf.ids.settingsDialog } }, T.sendAfter 1 (ModalOpen Conf.ids.settingsDialog) )

        PSClose ->
            ( { model | settings = Nothing }, Cmd.none )

        PSToggleSource source ->
            ( model |> setProject (Project.updateSource source.id (\s -> { s | enabled = not s.enabled }))
            , Cmd.batch
                [ observeTablesSize (model.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) [])
                , T.send (toastInfo ("Source " ++ source.name ++ " set to " ++ B.cond source.enabled "hidden" "visible" ++ "."))
                ]
            )

        PSDeleteSource source ->
            ( model |> setProject (Project.deleteSource source.id), T.send (toastInfo ("Source " ++ source.name ++ " has been deleted from your project.")) )

        PSSourceUploadOpen source ->
            ( { model | sourceUpload = Just { id = Conf.ids.sourceUploadDialog, source = source, parsing = { projectId = project.id, sourceId = source |> Maybe.map .id, selectedLocalFile = Nothing, selectedSample = Nothing, loadedFile = Nothing, parsedSchema = Nothing, parsedSource = Nothing } } }, T.sendAfter 1 (ModalOpen Conf.ids.sourceUploadDialog) )

        PSSourceUploadClose ->
            ( { model | sourceUpload = Nothing }, Cmd.none )

        PSSourceParsingMsg message ->
            model |> setParsingWithCmd (handleParsing message (PSSourceParsingMsg >> ProjectSettingsMsg))

        PSSourceRefresh source ->
            ( model |> setProject (Project.refreshSource source), T.send (ModalClose (ProjectSettingsMsg PSSourceUploadClose)) )

        PSToggleSchema schema ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedSchemas = s.removedSchemas |> L.toggle schema })

        PSToggleRemoveViews ->
            model |> updateSettingsAndComputeProject (\s -> { s | removeViews = not s.removeViews })

        PSUpdateRemovedTables values ->
            model |> updateSettingsAndComputeProject (\s -> { s | removedTables = values })

        PSUpdateHiddenColumns values ->
            ( model |> setProject (\p -> p |> setSettings (\s -> { s | hiddenColumns = values }) |> setLayout (hideColumns (ProjectSettings.isColumnHidden values) p)), Cmd.none )

        PSUpdateColumnOrder order ->
            ( model |> setProject (\p -> p |> setSettings (\s -> { s | columnOrder = order }) |> setLayout (sortColumns order p)), Cmd.none )


handleParsing : PSParsingMsg -> (PSParsingMsg -> msg) -> SourceParsing msg -> ( SourceParsing msg, Cmd msg )
handleParsing msg wrap model =
    -- FIXME: mutualize this with src/Pages/Projects/New.elm
    case msg of
        PSSelectLocalFile file ->
            ( { model | selectedLocalFile = Just file }, readLocalFile (Just model.projectId) model.sourceId file )

        PSFileLoaded projectId sourceInfo fileContent ->
            ( { model
                | loadedFile = Just ( projectId, sourceInfo, fileContent )
                , parsedSchema = Just (ProjectParser.init fileContent (PSParseMsg >> wrap) (PSBuildSource |> wrap))
              }
            , T.send (BuildLines |> PSParseMsg |> wrap)
            )

        PSParseMsg parseMsg ->
            model.parsedSchema
                |> Maybe.map
                    (\p ->
                        p
                            |> ProjectParser.update parseMsg
                            |> (\( parsed, message ) ->
                                    ( { model | parsedSchema = Just parsed }
                                    , B.cond ((parsed.cpt |> modBy 342) == 1) (T.sendAfter 1 message) (T.send message)
                                    )
                               )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        PSBuildSource ->
            model.parsedSchema
                |> Maybe.andThen (\p -> p.schema |> Maybe.map3 (\( _, sourceInfo, _ ) lines schema -> ( buildSourceFromSql sourceInfo lines schema, p )) model.loadedFile p.lines)
                |> Maybe.map (\( source, parser ) -> ( { model | parsedSource = Just source }, track (Tracking.events.parsedSource parser source) ))
                |> Maybe.withDefault ( model, Cmd.none )


setParsingWithCmd : (SourceParsing Msg -> ( SourceParsing Msg, Cmd Msg )) -> { item | sourceUpload : Maybe SourceUploadDialog } -> ( { item | sourceUpload : Maybe SourceUploadDialog }, Cmd Msg )
setParsingWithCmd transform item =
    item.sourceUpload |> M.mapOrElse (\su -> su.parsing |> transform |> Tuple.mapFirst (\parsing -> { item | sourceUpload = Just { su | parsing = parsing } })) ( item, Cmd.none )


updateSettingsAndComputeProject : (ProjectSettings -> ProjectSettings) -> Model x -> ( Model x, Cmd Msg )
updateSettingsAndComputeProject transform model =
    model
        |> setProject (setSettings transform >> Project.compute)
        |> (\m -> ( m, observeTablesSize (m.project |> M.mapOrElse (\p -> p.layout.tables |> List.map .id) []) ))


hideColumns : (Column -> Bool) -> Project -> Layout -> Layout
hideColumns isColumnHidden project layout =
    { layout
        | tables = layout.tables |> List.map (hideTableColumns isColumnHidden project)
        , hiddenTables = layout.hiddenTables |> List.map (hideTableColumns isColumnHidden project)
    }


sortColumns : ColumnOrder -> Project -> Layout -> Layout
sortColumns order project layout =
    { layout
        | tables = layout.tables |> List.map (sortTableColumns order project)
        , hiddenTables = layout.hiddenTables |> List.map (sortTableColumns order project)
    }


hideTableColumns : (Column -> Bool) -> Project -> TableProps -> TableProps
hideTableColumns isColumnHidden project props =
    updateProps (\_ -> L.filterNot isColumnHidden) project props


sortTableColumns : ColumnOrder -> Project -> TableProps -> TableProps
sortTableColumns order project props =
    updateProps (\table -> ColumnOrder.sortBy order table (project.relations |> List.filter (\r -> r.src.table == table.id))) project props


updateProps : (Table -> List Column -> List Column) -> Project -> TableProps -> TableProps
updateProps transform project props =
    project.tables
        |> Dict.get props.id
        |> M.mapOrElse
            (\table ->
                { props
                    | columns =
                        props.columns
                            |> List.filterMap (\c -> table.columns |> Ned.get c)
                            |> transform table
                            |> List.map .name
                }
            )
            props
