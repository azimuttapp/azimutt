module PagesComponents.Organization_.Project_.Updates.ProjectSettings exposing (Model, handleProjectSettings)

import Conf
import Libs.Bool as B
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Task as T
import Libs.Tuple as Tuple
import Models.OpenAIModel as OpenAIModel
import Models.Project.ProjectSettings as ProjectSettings
import Models.Project.Source as Source exposing (Source)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Organization_.Project_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Organization_.Project_.Models exposing (Msg(..), ProjectSettingsDialog, ProjectSettingsMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty, setDirtyM)
import Ports
import Services.Lenses exposing (mapCollapseTableColumns, mapColumnBasicTypes, mapEnabled, mapErdM, mapErdMT, mapHiddenColumns, mapLlm, mapLlmM, mapProps, mapRelations, mapRemoveViews, mapRemovedSchemas, mapSourceUpdateT, setColumnOrder, setDefaultSchema, setKey, setList, setMax, setModel, setRelationStyle, setRemovedTables, setSettings)
import Services.Toasts as Toasts
import Time
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
        , settings : Maybe ProjectSettingsDialog
        , sourceUpdate : Maybe (SourceUpdateDialog.Model Msg)
    }


handleProjectSettings : Time.Posix -> ProjectSettingsMsg -> Model x -> ( Model x, Extra Msg )
handleProjectSettings now msg model =
    case msg of
        PSOpen ->
            ( model |> setSettings (Just { id = Conf.ids.settingsDialog }), ModalOpen Conf.ids.settingsDialog |> T.sendAfter 1 |> Extra.cmd )

        PSClose ->
            ( model |> setSettings Nothing, Extra.none )

        PSSourceToggle source ->
            model
                |> mapErdM (Erd.mapSource source.id (mapEnabled not))
                |> (\newModel ->
                        ( newModel
                        , Extra.cmdL
                            [ Ports.observeTablesSize (newModel.erd |> getShownTables)
                            , "'" ++ source.name ++ "' source set to " ++ B.cond source.enabled "hidden" "visible" ++ "." |> Toasts.info |> Toast |> T.send
                            ]
                        )
                   )
                |> setDirty

        PSSourceDelete sourceId ->
            model
                |> mapErdMT
                    (Erd.mapSourcesT
                        (\sources ->
                            case sources |> List.zipWithIndex |> List.partition (\( s, _ ) -> s.id == sourceId) of
                                ( ( deleted, index ) :: _, kept ) ->
                                    ( kept |> List.map Tuple.first
                                    , Extra.newCL
                                        [ "'" ++ deleted.name ++ "' source removed from project." |> Toasts.info |> Toast |> T.send, Ports.deleteSource sourceId, Track.sourceDeleted model.erd deleted ]
                                        (( PSSourceUnDelete_ index deleted, msg ) |> Tuple.map ProjectSettingsMsg)
                                    )

                                _ ->
                                    ( sources, Extra.none )
                        )
                    )
                |> setDirtyM

        PSSourceUnDelete_ index source ->
            model
                |> mapErdM (Erd.mapSources (List.insertAt index source))
                |> (\newModel -> ( newModel, Ports.observeTablesSize (newModel.erd |> getShownTables) |> Extra.cmd ) |> setDirty)

        PSSourceUpdate message ->
            model |> mapSourceUpdateT (SourceUpdateDialog.update (PSSourceUpdate >> ProjectSettingsMsg) ModalOpen Noop now (model.erd |> Maybe.map .project) message)

        PSSourceSet source ->
            model
                |> mapErdMT
                    (Erd.mapSourcesT
                        (\sources ->
                            let
                                close : Cmd Msg
                                close =
                                    model.sourceUpdate |> Maybe.map (\_ -> SourceUpdateDialog.Close |> PSSourceUpdate |> ProjectSettingsMsg |> ModalClose) |> Maybe.withDefault (Noop "close-source-update") |> T.send
                            in
                            (sources |> List.findBy .id source.id)
                                |> Maybe.mapOrElse
                                    (\s ->
                                        ( sources |> List.mapBy .id source.id (Source.updateWith source)
                                        , Extra.newCL [ close, Track.sourceRefreshed model.erd source ] (( PSSourceSet s, msg ) |> Tuple.map ProjectSettingsMsg)
                                        )
                                    )
                                    ( sources |> List.insert source
                                    , Extra.newCL [ close, Track.sourceAdded model.erd source ] (( PSSourceDelete source.id, msg ) |> Tuple.map ProjectSettingsMsg)
                                    )
                        )
                    )
                |> setDirtyM

        PSDefaultSchemaUpdate value ->
            ( model |> mapErdM (Erd.mapSettings (setDefaultSchema value)), Extra.none ) |> setDirty

        PSSchemaToggle schema ->
            model |> mapErdM (Erd.mapSettings (mapRemovedSchemas (List.toggle schema))) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) |> Extra.cmd )) |> setDirty

        PSRemoveViewsToggle ->
            model |> mapErdM (Erd.mapSettings (mapRemoveViews not)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) |> Extra.cmd )) |> setDirty

        PSRemovedTablesUpdate values ->
            model |> mapErdM (Erd.mapSettings (setRemovedTables values >> ProjectSettings.fillFindPath)) |> (\m -> ( m, Ports.observeTablesSize (m.erd |> getShownTables) |> Extra.cmd )) |> setDirty

        PSHiddenColumnsListUpdate values ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setList values) >> ProjectSettings.fillFindPath)), Extra.none ) |> setDirty

        PSHiddenColumnsMaxUpdate value ->
            ( value |> String.toInt |> Maybe.mapOrElse (\max -> model |> mapErdM (Erd.mapSettings (mapHiddenColumns (setMax max) >> ProjectSettings.fillFindPath))) model, Extra.none ) |> setDirty

        PSHiddenColumnsPropsToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapProps not))), Extra.none ) |> setDirty

        PSHiddenColumnsRelationsToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapHiddenColumns (mapRelations not))), Extra.none ) |> setDirty

        PSColumnOrderUpdate order ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setColumnOrder order)), Extra.none ) |> setDirty

        PSRelationStyleUpdate style ->
            ( model |> mapErdM (\e -> e |> Erd.mapSettings (setRelationStyle style)), Extra.none ) |> setDirty

        PSColumnBasicTypesToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapColumnBasicTypes not)), Extra.none ) |> setDirty

        PSCollapseTableOnShowToggle ->
            ( model |> mapErdM (Erd.mapSettings (mapCollapseTableColumns not)), Extra.none ) |> setDirty

        PSLlmKeyUpdate key ->
            ( model |> mapErdM (Erd.mapSettings (mapLlm (\llm -> B.cond (key == "") Nothing (llm |> Maybe.mapOrElse (setKey key) { key = key, model = OpenAIModel.default } |> Just)))), Extra.none ) |> setDirty

        PSLlmModelUpdate m ->
            ( model |> mapErdM (Erd.mapSettings (mapLlmM (setModel m))), Extra.none ) |> setDirty


getShownTables : Maybe Erd -> List TableId
getShownTables erd =
    erd |> Maybe.mapOrElse (Erd.currentLayout >> .tables >> List.map .id) []
