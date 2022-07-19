module PagesComponents.Projects.Id_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Libs.Area as Area exposing (Area, AreaLike)
import Libs.Bool as B
import Libs.Delta as Delta
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Task as T
import Models.Project as Project
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.SourceId as SourceId
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Components.AmlSlidebar as AmlSlidebar
import PagesComponents.Projects.Id_.Components.ProjectTeam as ProjectTeam
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog
import PagesComponents.Projects.Id_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..))
import PagesComponents.Projects.Id_.Models.CursorMode as CursorMode
import PagesComponents.Projects.Id_.Models.DragState as DragState
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Projects.Id_.Models.PositionHint exposing (PositionHint(..))
import PagesComponents.Projects.Id_.Updates.Canvas exposing (fitCanvas, handleWheel, zoomCanvas)
import PagesComponents.Projects.Id_.Updates.Drag exposing (handleDrag)
import PagesComponents.Projects.Id_.Updates.FindPath exposing (handleFindPath)
import PagesComponents.Projects.Id_.Updates.Help exposing (handleHelp)
import PagesComponents.Projects.Id_.Updates.Hotkey exposing (handleHotkey)
import PagesComponents.Projects.Id_.Updates.Layout exposing (handleLayout)
import PagesComponents.Projects.Id_.Updates.Notes exposing (handleNotes)
import PagesComponents.Projects.Id_.Updates.ProjectSettings exposing (handleProjectSettings)
import PagesComponents.Projects.Id_.Updates.Sharing exposing (handleSharing)
import PagesComponents.Projects.Id_.Updates.Source as Source
import PagesComponents.Projects.Id_.Updates.Table exposing (hideColumn, hideColumns, hideRelatedTables, hideTable, hoverColumn, hoverNextColumn, mapTablePropOrSelected, showAllTables, showColumn, showColumns, showRelatedTables, showTable, showTables, sortColumns)
import PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Projects.Id_.Views as Views
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.Backend exposing (BackendUrl)
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSidebarM, mapCanvas, mapColumns, mapConf, mapContextMenuM, mapErdM, mapErdMCmd, mapHoverTable, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapPosition, mapProject, mapPromptM, mapProps, mapSchemaAnalysisM, mapScreen, mapSearch, mapSelected, mapShowHiddenColumns, mapSourceParsingMCmd, mapSqlSourceCmd, mapTables, mapTablesCmd, mapToastsCmd, mapTop, mapUploadCmd, mapUploadM, setActive, setCollapsed, setColor, setConfirm, setContextMenu, setCursorMode, setDragging, setHoverColumn, setHoverTable, setInput, setName, setOpenedDropdown, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setSeed, setShow, setSize, setText)
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Request.With params -> Maybe LayoutName -> Time.Posix -> BackendUrl -> Msg -> Model -> ( Model, Cmd Msg )
update req currentLayout now backendUrl msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none )

        SaveProject ->
            if model.conf.save then
                ( model, Cmd.batch (model.erd |> Maybe.map Erd.unpack |> Maybe.mapOrElse (\p -> [ Ports.updateProject p, Ports.track (Track.updateProject p) ]) [ Toasts.warning Toast "No project to save" ]) )

            else
                ( model, Cmd.none )

        MoveProjectTo storage ->
            if model.conf.save then
                ( model |> mapUploadM (\u -> { u | movingProject = True })
                , Cmd.batch
                    (model.erd
                        |> Maybe.map Erd.unpack
                        |> Maybe.mapOrElse
                            (\p -> [ Ports.moveProjectTo p storage ])
                            [ Toasts.warning Toast "No project to move" ]
                    )
                )

            else
                ( model, Cmd.none )

        RenameProject name ->
            ( model |> mapErdM (mapProject (setName name)), Cmd.none )

        ShowTable id hint ->
            model |> mapErdMCmd (showTable now id hint)

        ShowTables ids hint ->
            model |> mapErdMCmd (showTables now ids hint)

        ShowAllTables ->
            model |> mapErdMCmd (showAllTables now)

        HideTable id ->
            ( model |> mapErdM (hideTable now id) |> mapHoverTable (\h -> B.cond (h == Just id) Nothing h), Cmd.none )

        ShowRelatedTables id ->
            model |> mapErdMCmd (showRelatedTables id)

        HideRelatedTables id ->
            model |> mapErdMCmd (hideRelatedTables id)

        ToggleColumns id ->
            let
                collapsed : Bool
                collapsed =
                    model.erd |> Maybe.andThen (Erd.currentLayout >> .tables >> List.findBy .id id) |> Maybe.mapOrElse (.props >> .collapsed) False
            in
            model |> mapErdMCmd (\erd -> erd |> Erd.mapCurrentLayoutCmd now (mapTablesCmd (mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setCollapsed (not collapsed))))))

        ShowColumn { table, column } ->
            ( model |> mapErdM (showColumn now table column), Cmd.none )

        HideColumn { table, column } ->
            ( model |> mapErdM (hideColumn now table column) |> hoverNextColumn table column, Cmd.none )

        ShowColumns id kind ->
            model |> mapErdMCmd (showColumns now id kind)

        HideColumns id kind ->
            model |> mapErdMCmd (hideColumns now id kind)

        SortColumns id kind ->
            model |> mapErdMCmd (sortColumns now id kind)

        ToggleHiddenColumns id ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.updateBy .id id (mapProps (mapShowHiddenColumns not))))), Cmd.none )

        SelectTable tableId ctrl ->
            if model.dragging |> Maybe.any DragState.hasMoved then
                ( model, Cmd.none )

            else
                ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.map (\t -> t |> mapProps (mapSelected (\s -> B.cond (t.id == tableId) (not s) (B.cond ctrl s False))))))), Cmd.none )

        TableMove id delta ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.updateBy .id id (mapProps (mapPosition (\p -> delta |> Delta.move p)))))), Cmd.none )

        TablePosition id position ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.updateBy .id id (mapProps (setPosition position))))), Cmd.none )

        TableOrder id index ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (\tables -> tables |> List.moveBy .id id (List.length tables - 1 - index)))), Cmd.none )

        TableColor id color ->
            model |> mapErdMCmd (\erd -> erd |> Erd.mapCurrentLayoutCmd now (mapTablesCmd (mapTablePropOrSelected erd.settings.defaultSchema id (mapProps (setColor color)))))

        MoveColumn column position ->
            ( model |> mapErdM (\erd -> erd |> Erd.mapCurrentLayout now (mapTables (List.updateBy .id column.table (mapColumns (List.moveBy .name column.column position))))), Cmd.none )

        ToggleHoverTable table on ->
            ( model |> setHoverTable (B.cond on (Just table) Nothing), Cmd.none )

        ToggleHoverColumn column on ->
            ( model |> setHoverColumn (B.cond on (Just column) Nothing) |> mapErdM (\e -> e |> Erd.mapCurrentLayout now (mapTables (hoverColumn column on e))), Cmd.none )

        CreateUserSource name ->
            ( model |> mapErdM (Source.createUserSource now name) |> (\updated -> updated |> mapAmlSidebarM (AmlSlidebar.setSource (updated.erd |> Maybe.andThen (.sources >> List.last)))), Cmd.none )

        CreateRelation src ref ->
            model |> mapErdMCmd (Source.createRelation now src ref)

        LayoutMsg message ->
            model |> handleLayout now message

        NotesMsg message ->
            model |> handleNotes message

        AmlSidebarMsg message ->
            model |> AmlSlidebar.update now message

        VirtualRelationMsg message ->
            model |> handleVirtualRelation message

        FindPathMsg message ->
            model |> handleFindPath message

        SchemaAnalysisMsg SAOpen ->
            ( model |> setSchemaAnalysis (Just { id = Conf.ids.schemaAnalysisDialog, opened = "" }), Cmd.batch [ T.sendAfter 1 (ModalOpen Conf.ids.schemaAnalysisDialog), Ports.track Track.openSchemaAnalysis ] )

        SchemaAnalysisMsg (SASectionToggle section) ->
            ( model |> mapSchemaAnalysisM (mapOpened (\opened -> B.cond (opened == section) "" section)), Cmd.none )

        SchemaAnalysisMsg SAClose ->
            ( model |> setSchemaAnalysis Nothing, Cmd.none )

        SharingMsg message ->
            model |> handleSharing message

        ProjectUploadDialogMsg message ->
            model |> mapUploadCmd (ProjectUploadDialog.update ModalOpen model.erd message)

        ProjectSettingsMsg message ->
            model |> handleProjectSettings now backendUrl message

        EmbedSourceParsing message ->
            model |> mapSourceParsingMCmd (mapSqlSourceCmd (SqlSource.update EmbedSourceParsing message))

        SourceParsed source ->
            let
                ( projectId, seed ) =
                    model.seed |> Random.step ProjectId.generator
            in
            ( model |> setSeed seed, T.send (JsMessage (GotProject (Just (Ok (Project.create projectId source.name source))))) )

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitContent ->
            ( model |> mapErdM (fitCanvas now model.screen), Cmd.none )

        Fullscreen maybeId ->
            ( model, Ports.fullscreen maybeId )

        OnWheel event ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapCanvas (handleWheel event))), Cmd.none )

        Zoom delta ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapCanvas (zoomCanvas delta model.screen))), Cmd.none )

        Logout ->
            B.cond (model.erd |> Maybe.mapOrElse (\e -> e.project.storage /= ProjectStorage.Browser) False) (Cmd.batch [ Ports.logout, Request.pushRoute Route.Projects req ]) Ports.logout
                |> (\cmd -> ( { model | projects = model.projects |> List.filter (\p -> p.storage == ProjectStorage.Browser) }, cmd ))

        Focus id ->
            ( model, Ports.focus id )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

        DropdownOpen id ->
            ( model |> setOpenedDropdown id, Cmd.none )

        DropdownClose ->
            ( model |> setOpenedDropdown "", Cmd.none )

        PopoverSet id ->
            ( model |> setOpenedPopover id, Cmd.none )

        ContextMenuCreate content event ->
            ( model |> setContextMenu (Just { content = content, position = event.position, show = False }), T.sendAfter 1 ContextMenuShow )

        ContextMenuShow ->
            ( model |> mapContextMenuM (setShow True), Cmd.none )

        ContextMenuClose ->
            ( model |> setContextMenu Nothing, Cmd.none )

        DragStart id pos ->
            model.dragging
                |> Maybe.mapOrElse (\d -> ( model, Toasts.info Toast ("Already dragging " ++ d.id) ))
                    ( { id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag now d False), Cmd.none )

        DragMove pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag now d False) model
            , Cmd.none
            )

        DragEnd pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag now d True) model
            , Cmd.none
            )

        DragCancel ->
            ( model |> setDragging Nothing, Cmd.none )

        Toast message ->
            model |> mapToastsCmd (Toasts.update Toast message)

        ConfirmOpen confirm ->
            ( model |> setConfirm (Just { id = Conf.ids.confirmDialog, content = confirm }), T.sendAfter 1 (ModalOpen Conf.ids.confirmDialog) )

        ConfirmAnswer answer cmd ->
            ( model |> setConfirm Nothing, B.cond answer cmd Cmd.none )

        PromptOpen prompt input ->
            ( model |> setPrompt (Just { id = Conf.ids.promptDialog, content = prompt, input = input }), T.sendAfter 1 (ModalOpen Conf.ids.promptDialog) )

        PromptUpdate input ->
            ( model |> mapPromptM (setInput input), Cmd.none )

        PromptAnswer cmd ->
            ( model |> setPrompt Nothing, cmd )

        ModalOpen id ->
            ( model |> mapOpenedDialogs (\dialogs -> id :: dialogs), Ports.autofocusWithin id )

        ModalClose message ->
            ( model |> mapOpenedDialogs (List.drop 1), T.sendAfter Conf.ui.closeDuration message )

        JsMessage message ->
            model |> handleJsMessage now currentLayout message

        Send cmd ->
            ( model, cmd )

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Time.Posix -> Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage now currentLayout msg model =
    case msg of
        GotSizes sizes ->
            model |> updateSizes sizes

        GotLogin _ ->
            ( model, Cmd.none )

        GotLogout ->
            ( model, Cmd.none )

        GotProjects ( errors, projects ) ->
            ( { model | projects = projects |> List.sortBy (\p -> negate (Time.posixToMillis p.updatedAt)) }
            , Cmd.batch
                (errors
                    |> List.concatMap
                        (\( name, err ) ->
                            [ Toasts.error Toast ("Unable to read project " ++ name ++ ": " ++ Decode.errorToHtml err)
                            , Ports.trackJsonError "decode-project" err
                            ]
                        )
                )
            )

        GotProject res ->
            case res of
                Nothing ->
                    ( { model | loaded = True }, Cmd.none )

                Just (Err err) ->
                    ( { model | loaded = True }, Cmd.batch [ Toasts.error Toast ("Unable to read project: " ++ Decode.errorToHtml err), Ports.trackJsonError "decode-project" err ] )

                Just (Ok project) ->
                    let
                        ( childSeed, newSeed ) =
                            Random.step (Random.int Random.minInt Random.maxInt) model.seed

                        erd : Erd
                        erd =
                            project
                                |> (\p -> currentLayout |> Maybe.mapOrElse (\l -> { p | usedLayout = l }) p)
                                |> Erd.create (Random.initialSeed childSeed)

                        uploadCmd : List (Cmd msg)
                        uploadCmd =
                            if model.upload == Nothing then
                                []

                            else if project.storage == ProjectStorage.Cloud then
                                [ Ports.getOwners project.id, Ports.confettiPride ]

                            else
                                []
                    in
                    ( { model | seed = newSeed, loaded = True, erd = Just erd } |> mapUploadM (\u -> { u | movingProject = False })
                    , Cmd.batch
                        ([ Ports.observeSize Conf.ids.erd
                         , Ports.observeTablesSize (erd |> Erd.currentLayout |> .tables |> List.map .id)
                         , Ports.setMeta { title = Just (Views.title (Just erd)), description = Nothing, canonical = Nothing, html = Nothing, body = Nothing }
                         ]
                            ++ uploadCmd
                        )
                    )

        GotUser email user ->
            if model.upload == Nothing then
                ( model, Cmd.none )

            else
                ( model, T.send (ProjectUploadDialogMsg (ProjectUploadDialog.ProjectTeamMsg (ProjectTeam.UpdateShareUser (Just ( email, user ))))) )

        GotOwners _ owners ->
            if model.upload == Nothing then
                ( model, Cmd.none )

            else
                ( model, T.send (ProjectUploadDialogMsg (ProjectUploadDialog.ProjectTeamMsg (ProjectTeam.UpdateOwners owners))) )

        ProjectDropped projectId ->
            ( { model | projects = model.projects |> List.filter (\p -> p.id /= projectId) }, Cmd.none )

        GotLocalFile kind file content ->
            let
                ( sourceId, seed ) =
                    model.seed |> Random.step SourceId.generator

                updated : Model
                updated =
                    model |> setSeed seed
            in
            if kind == SqlSource.kind then
                ( updated, T.send (SqlSource.gotLocalFile now sourceId file content |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == JsonSource.kind then
                ( updated, T.send (JsonSource.gotLocalFile now sourceId file content |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else
                ( model, Toasts.error Toast ("Unhandled local file for " ++ kind ++ " source") )

        GotRemoteFile kind url content sample ->
            let
                ( sourceId, seed ) =
                    model.seed |> Random.step SourceId.generator

                updated : Model
                updated =
                    model |> setSeed seed
            in
            if kind == SqlSource.kind then
                if model.erd == Nothing then
                    ( updated, Cmd.batch [ T.send (SqlSource.gotRemoteFile now sourceId url content sample |> EmbedSourceParsing) ] )

                else
                    ( updated, T.send (SqlSource.gotRemoteFile now sourceId url content sample |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == JsonSource.kind then
                ( updated, T.send (JsonSource.gotRemoteFile now sourceId url content sample |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else
                ( model, Toasts.error Toast ("Unhandled remote file for " ++ kind ++ " source") )

        GotHotkey hotkey ->
            handleHotkey now model hotkey

        GotKeyHold key start ->
            if key == "Space" && model.conf.move then
                if start then
                    ( model |> setCursorMode CursorMode.Drag, Cmd.none )

                else
                    ( model |> setCursorMode CursorMode.Select, Cmd.none )

            else
                ( model, Cmd.none )

        GotToast level message ->
            ( model, Toasts.create Toast level message )

        GotTableShow id hint ->
            ( model, T.send (ShowTable id (hint |> Maybe.map PlaceAt)) )

        GotTableHide id ->
            ( model, T.send (HideTable id) )

        GotTableToggleColumns id ->
            ( model, T.send (ToggleColumns id) )

        GotTablePosition id pos ->
            ( model, T.send (TablePosition id pos) )

        GotTableMove id delta ->
            ( model, T.send (TableMove id delta) )

        GotTableSelect id ->
            ( model, T.send (SelectTable id False) )

        GotTableColor id color ->
            ( model, T.send (TableColor id color) )

        GotColumnShow ref ->
            ( model, T.send (ShowColumn ref) )

        GotColumnHide ref ->
            ( model, T.send (HideColumn ref) )

        GotColumnMove ref index ->
            ( model, T.send (MoveColumn ref index) )

        GotFitToScreen ->
            ( model, T.send FitContent )

        Error err ->
            ( model, Cmd.batch [ Toasts.error Toast ("Unable to decode JavaScript message: " ++ Decode.errorToHtml err), Ports.trackJsonError "js-message" err ] )


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    let
        erdChanged : Model
        erdChanged =
            changes |> List.findBy .id "erd" |> Maybe.mapOrElse (\c -> model |> mapScreen (setPosition c.position >> setSize c.size)) model

        tableChanges : Dict TableId SizeChange
        tableChanges =
            changes |> List.filterMap (\c -> TableId.fromHtmlId c.id |> Maybe.map (\id -> ( id, c ))) |> Dict.fromList

        tablesChanged : Model
        tablesChanged =
            erdChanged
                |> mapErdM
                    (\erd ->
                        erd
                            |> Erd.mapCurrentLayout (erd |> Erd.currentLayout |> .updatedAt)
                                (mapTables
                                    (\tables ->
                                        tables
                                            |> List.map
                                                (\table ->
                                                    tableChanges
                                                        |> Dict.get table.id
                                                        |> Maybe.mapOrElse (\change -> updateTable tables (erdChanged.erd |> Erd.viewportM erdChanged.screen) change table) table
                                                )
                                    )
                                )
                    )
    in
    if model.conf.fitOnLoad then
        ( tablesChanged |> mapConf (\c -> { c | fitOnLoad = False }), T.send FitContent )

    else
        ( tablesChanged, Cmd.none )


updateTable : List ErdTableLayout -> Area -> SizeChange -> ErdTableLayout -> ErdTableLayout
updateTable tables viewport change table =
    if table.props.size == Size.zero && table.props.position == Position.zero then
        table |> mapProps (setSize change.size >> setPosition (computeInitialPosition tables viewport change table.props.positionHint))

    else
        table |> mapProps (setSize change.size)


computeInitialPosition : List ErdTableLayout -> Area -> SizeChange -> Maybe PositionHint -> Position
computeInitialPosition tables viewport change hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.sub { left = change.size.width + 50, top = 0 } |> moveDownIfExists tables change.size

                    PlaceRight position size ->
                        position |> Position.add { left = size.width + 50, top = 0 } |> moveDownIfExists tables change.size

                    PlaceAt position ->
                        position
            )
            (if tables |> List.filter (\t -> t.props.size /= Size.zero) |> List.isEmpty then
                viewport |> Area.center |> Position.sub (change |> Area.center) |> mapTop (max viewport.position.top)

             else
                { left = viewport.position.left + change.seeds.left * max 0 (viewport.size.width - change.size.width)
                , top = viewport.position.top + change.seeds.top * max 0 (viewport.size.height - change.size.height)
                }
            )



--insideViewport : Area -> SizeChange -> Position -> Position
--insideViewport viewport change pos =
--    { left = pos.left |> Basics.inside viewport.position.left (viewport.position.left + viewport.size.width - change.size.width)
--    , top = pos.top |> Basics.inside viewport.position.top (viewport.position.top + viewport.size.height - change.size.height)
--    }


moveDownIfExists : List ErdTableLayout -> Size -> Position -> Position
moveDownIfExists tables size position =
    if tables |> List.any (\t -> t.props.position == position || isSameTopRight t.props (Area position size)) then
        position |> Position.add { left = 0, top = Conf.ui.tableHeaderHeight } |> moveDownIfExists tables size

    else
        position


isSameTopRight : AreaLike x -> AreaLike y -> Bool
isSameTopRight a b =
    a.position.top == b.position.top && a.position.left + a.size.width == b.position.left + b.size.width
