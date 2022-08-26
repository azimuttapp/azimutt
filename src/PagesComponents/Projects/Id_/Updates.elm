module PagesComponents.Projects.Id_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Json.Decode as Decode
import Json.Encode as Encode
import Libs.Bool as B
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Size as Size exposing (Size)
import Libs.Task as T
import Models.Area as Area
import Models.Position as Position
import Models.Project as Project
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.Source as Source
import Models.Project.SourceId as SourceId
import Models.Project.SourceKind as SourceKind
import Models.Project.TableId as TableId exposing (TableId)
import Models.SourceInfo as SourceInfo
import PagesComponents.Projects.Id_.Components.AmlSidebar as AmlSidebar
import PagesComponents.Projects.Id_.Components.DetailsSidebar as DetailsSidebar
import PagesComponents.Projects.Id_.Components.EmbedSourceParsingDialog as EmbedSourceParsingDialog
import PagesComponents.Projects.Id_.Components.ProjectTeam as ProjectTeam
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog
import PagesComponents.Projects.Id_.Components.SourceUpdateDialog as SourceUpdateDialog
import PagesComponents.Projects.Id_.Models exposing (AmlSidebar, Model, Msg(..), ProjectSettingsMsg(..), SchemaAnalysisMsg(..))
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
import Services.Backend as Backend
import Services.JsonSource as JsonSource
import Services.Lenses exposing (mapAmlSidebarM, mapCanvas, mapColumns, mapConf, mapContextMenuM, mapDetailsSidebarCmd, mapEmbedSourceParsingMCmd, mapErdM, mapErdMCmd, mapHoverTable, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapPosition, mapProject, mapPromptM, mapProps, mapSchemaAnalysisM, mapSearch, mapSelected, mapShowHiddenColumns, mapTables, mapTablesCmd, mapToastsCmd, mapUploadCmd, mapUploadM, setActive, setCollapsed, setColor, setConfirm, setContextMenu, setCursorMode, setDragging, setHoverColumn, setHoverTable, setInput, setLast, setName, setOpenedDropdown, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setSelected, setShow, setSize, setText)
import Services.SqlSource as SqlSource
import Services.Toasts as Toasts
import Time
import Track


update : Request.With params -> Maybe LayoutName -> Time.Posix -> Backend.Url -> Msg -> Model -> ( Model, Cmd Msg )
update req currentLayout now backendUrl msg model =
    case msg of
        ToggleMobileMenu ->
            ( model |> mapNavbar (mapMobileMenuOpen not), Cmd.none )

        SearchUpdated search ->
            ( model |> mapNavbar (mapSearch (setText search >> setActive 0)), Cmd.none )

        SaveProject ->
            if model.conf.save then
                ( model, Cmd.batch (model.erd |> Maybe.map Erd.unpack |> Maybe.mapOrElse (\p -> [ Ports.updateProject p, Ports.track (Track.updateProject p) ]) [ "No project to save" |> Toasts.warning |> Toast |> T.send ]) )

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
                            [ "No project to move" |> Toasts.warning |> Toast |> T.send ]
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

        SelectAllTables ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.map (mapProps (setSelected True))))), Cmd.none )

        TableMove id delta ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapTables (List.updateBy .id id (mapProps (mapPosition (Position.moveGrid delta)))))), Cmd.none )

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
            ( model, SourceId.generator |> Random.generate (\sourceId -> Source.aml sourceId name now |> CreateUserSourceWithId) )

        CreateUserSourceWithId source ->
            ( model |> mapErdM (Erd.mapSources (List.add source)) |> (\updated -> updated |> mapAmlSidebarM (AmlSidebar.setSource (updated.erd |> Maybe.andThen (.sources >> List.last)))), Cmd.none )

        CreateRelation src ref ->
            model |> mapErdMCmd (Source.createRelation now src ref)

        LayoutMsg message ->
            model |> handleLayout now message

        NotesMsg message ->
            model |> handleNotes message

        AmlSidebarMsg message ->
            model |> AmlSidebar.update now message

        DetailsSidebarMsg message ->
            model.erd |> Maybe.mapOrElse (\erd -> model |> mapDetailsSidebarCmd (DetailsSidebar.update erd message)) ( model, Cmd.none )

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

        ProjectUploadMsg message ->
            model |> mapUploadCmd (ProjectUploadDialog.update ModalOpen model.erd message)

        ProjectSettingsMsg message ->
            model |> handleProjectSettings now backendUrl message

        EmbedSourceParsingMsg message ->
            model |> mapEmbedSourceParsingMCmd (EmbedSourceParsingDialog.update EmbedSourceParsingMsg backendUrl now message)

        SourceParsed source ->
            ( model, ProjectId.generator |> Random.generate (\projectId -> Project.create projectId source.name source |> Ok |> Just |> GotProject |> JsMessage) )

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitContent ->
            model |> mapErdMCmd (fitCanvas now model.erdElem)

        Fullscreen maybeId ->
            ( model, Ports.fullscreen maybeId )

        OnWheel event ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapCanvas (handleWheel event model.erdElem))), Cmd.none )

        Zoom delta ->
            ( model |> mapErdM (Erd.mapCurrentLayout now (mapCanvas (zoomCanvas delta model.erdElem))), Cmd.none )

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
            ( model |> setContextMenu (Just { content = content, position = event.clientPos, show = False }), T.sendAfter 1 ContextMenuShow )

        ContextMenuShow ->
            ( model |> mapContextMenuM (setShow True), Cmd.none )

        ContextMenuClose ->
            ( model |> setContextMenu Nothing, Cmd.none )

        DragStart id pos ->
            model.dragging
                |> Maybe.mapOrElse (\d -> ( model, "Already dragging " ++ d.id |> Toasts.info |> Toast |> T.send ))
                    ( { id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag now d False), Cmd.none )

        DragMove pos ->
            ( model.dragging
                |> Maybe.map (setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag now d False) model
            , Cmd.none
            )

        DragEnd pos ->
            ( model.dragging
                |> Maybe.map (setLast pos)
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
                            [ "Unable to read project " ++ name ++ ": " ++ Decode.errorToHtml err |> Toasts.error |> Toast |> T.send
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
                    ( { model | loaded = True }, Cmd.batch [ "Unable to read project: " ++ Decode.errorToHtml err |> Toasts.error |> Toast |> T.send, Ports.trackJsonError "decode-project" err ] )

                Just (Ok project) ->
                    let
                        erd : Erd
                        erd =
                            currentLayout |> Maybe.mapOrElse (\l -> { project | usedLayout = l }) project |> Erd.create

                        uploadCmd : List (Cmd msg)
                        uploadCmd =
                            if model.upload == Nothing then
                                []

                            else if project.storage == ProjectStorage.Cloud then
                                [ Ports.getOwners project.id, Ports.confettiPride ]

                            else
                                []

                        amlSidebar : Maybe AmlSidebar
                        amlSidebar =
                            B.maybe (project.sources |> List.all (\s -> s.kind == SourceKind.AmlEditor)) (AmlSidebar.init (Just erd))
                    in
                    ( { model | loaded = True, erd = Just erd, amlSidebar = amlSidebar } |> mapUploadM (\u -> { u | movingProject = False })
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
                ( model, T.send (ProjectUploadMsg (ProjectUploadDialog.ProjectTeamMsg (ProjectTeam.UpdateShareUser (Just ( email, user ))))) )

        GotOwners _ owners ->
            if model.upload == Nothing then
                ( model, Cmd.none )

            else
                ( model, T.send (ProjectUploadMsg (ProjectUploadDialog.ProjectTeamMsg (ProjectTeam.UpdateOwners owners))) )

        ProjectDropped projectId ->
            ( { model | projects = model.projects |> List.filter (\p -> p.id /= projectId) }, Cmd.none )

        GotLocalFile kind file content ->
            if kind == SqlSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> SqlSource.GotFile (SourceInfo.sqlLocal now sourceId file) |> SourceUpdateDialog.SqlSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else if kind == JsonSource.kind then
                ( model, SourceId.generator |> Random.generate (\sourceId -> content |> JsonSource.GotFile (SourceInfo.jsonLocal now sourceId file) |> SourceUpdateDialog.JsonSourceMsg |> PSSourceUpdate |> ProjectSettingsMsg) )

            else
                ( model, "Unhandled local file kind '" ++ kind ++ "'" |> Toasts.error |> Toast |> T.send )

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
            ( model, message |> Toasts.create level |> Toast |> T.send )

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

        Error json err ->
            ( model, Cmd.batch [ "Unable to decode JavaScript message: " ++ Decode.errorToString err ++ " in " ++ Encode.encode 0 json |> Toasts.error |> Toast |> T.send, Ports.trackJsonError "js-message" err ] )


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    let
        erdChanged : Model
        erdChanged =
            changes |> List.findBy .id "erd" |> Maybe.mapOrElse (\c -> { model | erdElem = { position = c.position, size = c.size } }) model

        tableChanges : Dict TableId SizeChange
        tableChanges =
            changes |> List.filterMap (\c -> TableId.fromHtmlId c.id |> Maybe.map (\id -> ( id, c ))) |> Dict.fromList

        erdViewport : Area.InCanvas
        erdViewport =
            erdChanged.erd |> Erd.viewportM erdChanged.erdElem

        tablesChanged : Model
        tablesChanged =
            erdChanged
                |> mapErdM
                    (\erd ->
                        erd
                            |> Erd.mapCurrentLayout (erd |> Erd.currentLayout |> .updatedAt)
                                (mapTables (\tables -> tables |> List.map (\table -> tableChanges |> Dict.get table.id |> Maybe.mapOrElse (\change -> updateTable tables erdViewport change table) table)))
                    )
    in
    if model.conf.fitOnLoad then
        ( tablesChanged |> mapConf (\c -> { c | fitOnLoad = False }), T.send FitContent )

    else
        ( tablesChanged, Cmd.none )


updateTable : List ErdTableLayout -> Area.InCanvas -> SizeChange -> ErdTableLayout -> ErdTableLayout
updateTable tables erdViewport change table =
    if table.props.size == Size.zero && table.props.position == Position.zeroGrid then
        table |> mapProps (setSize change.size >> setPosition (computeInitialPosition tables erdViewport change table.props.positionHint))

    else
        table |> mapProps (setSize change.size)


computeInitialPosition : List ErdTableLayout -> Area.InCanvas -> SizeChange -> Maybe PositionHint -> Position.Grid
computeInitialPosition tables erdViewport change hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.moveGrid { dx = change.size.width + 50 |> negate, dy = 0 } |> moveDownIfExists tables change.size

                    PlaceRight position size ->
                        position |> Position.moveGrid { dx = size.width + 50, dy = 0 } |> moveDownIfExists tables change.size

                    PlaceAt position ->
                        position
            )
            (if tables |> List.filter (\t -> t.props.size /= Size.zero) |> List.isEmpty then
                change |> placeAtCenter erdViewport

             else
                change |> placeAtRandom erdViewport
            )


placeAtCenter : Area.InCanvas -> SizeChange -> Position.Grid
placeAtCenter erdViewport change =
    let
        ( canvasCenter, tableCenter ) =
            ( erdViewport |> Area.centerInCanvas
            , Area.zeroInCanvas |> setSize change.size |> Area.centerInCanvas
            )
    in
    canvasCenter |> Position.subInCanvas tableCenter |> Position.onGrid


placeAtRandom : Area.InCanvas -> SizeChange -> Position.Grid
placeAtRandom erdViewport change =
    erdViewport.position
        |> Position.moveInCanvas
            { dx = change.seeds.left * max 0 (erdViewport.size.width - change.size.width)
            , dy = change.seeds.top * max 0 (erdViewport.size.height - change.size.height)
            }
        |> Position.onGrid


moveDownIfExists : List ErdTableLayout -> Size -> Position.Grid -> Position.Grid
moveDownIfExists tables size position =
    if tables |> List.any (\t -> t.props.position == position || isSameTopRight t.props { position = position, size = size }) then
        position |> Position.moveGrid { dx = 0, dy = Conf.ui.tableHeaderHeight } |> moveDownIfExists tables size

    else
        position


isSameTopRight : { x | position : Position.Grid, size : Size } -> { y | position : Position.Grid, size : Size } -> Bool
isSameTopRight a b =
    let
        ( aPos, bPos ) =
            ( a.position |> Position.extractGrid, b.position |> Position.extractGrid )
    in
    aPos.top == bPos.top && aPos.left + a.size.width == bPos.left + b.size.width
