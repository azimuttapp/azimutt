module PagesComponents.Projects.Id_.Updates exposing (update)

import Components.Molecules.Dropdown as Dropdown
import Conf
import Dict exposing (Dict)
import Gen.Route as Route
import Libs.Area as Area exposing (Area, AreaLike)
import Libs.Bool as B
import Libs.Delta as Delta
import Libs.Dict as Dict
import Libs.Json.Decode as Decode
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models exposing (SizeChange)
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size exposing (Size)
import Libs.Task as T
import Models.Project as Project
import Models.Project.CanvasProps as CanvasProps
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Components.ProjectUploadDialog as ProjectUploadDialog
import PagesComponents.Projects.Id_.Models exposing (CursorMode(..), Model, Msg(..), ProjectSettingsMsg(..), ProjectUploadDialogMsg, SchemaAnalysisMsg(..))
import PagesComponents.Projects.Id_.Models.DragState as DragState
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdTableProps as ErdTableProps exposing (ErdTableProps)
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
import PagesComponents.Projects.Id_.Updates.Table exposing (hideColumn, hideColumns, hideTable, hoverColumn, hoverNextColumn, hoverTable, mapTablePropOrSelected, showAllTables, showColumn, showColumns, showTable, showTables, sortColumns)
import PagesComponents.Projects.Id_.Updates.VirtualRelation exposing (handleVirtualRelation)
import PagesComponents.Projects.Id_.Views as Views
import Ports exposing (JsMsg(..))
import Random
import Request
import Services.Lenses exposing (mapCanvas, mapConf, mapContextMenuM, mapErdM, mapErdMCmd, mapMobileMenuOpen, mapNavbar, mapOpened, mapOpenedDialogs, mapParsingCmd, mapProject, mapPromptM, mapSchemaAnalysisM, mapScreen, mapSearch, mapShownTables, mapSourceParsingMCmd, mapTableProps, mapTablePropsCmd, mapToastsCmd, mapTop, mapUploadCmd, mapUploadM, setActive, setCanvas, setConfirm, setContextMenu, setCursorMode, setDragging, setInput, setName, setOpenedPopover, setPosition, setPrompt, setSchemaAnalysis, setShow, setShownTables, setSize, setTableProps, setText, setUsedLayout)
import Services.SqlSourceUpload as SqlSourceUpload
import Services.Toasts as Toasts
import Time
import Track


update : Request.With params -> Maybe LayoutName -> Time.Posix -> Msg -> Model -> ( Model, Cmd Msg )
update req currentLayout now msg model =
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
                ( model
                , Cmd.batch
                    (model.erd
                        |> Maybe.map Erd.unpack
                        |> Maybe.mapOrElse
                            (\p -> [ Ports.moveProjectTo p storage, T.send ProjectUploadDialog.close ])
                            [ Toasts.warning Toast "No project to move" ]
                    )
                )

            else
                ( model, Cmd.none )

        RenameProject name ->
            ( model |> mapErdM (mapProject (setName name)), Cmd.none )

        ShowTable id hint ->
            model |> mapErdMCmd (showTable id hint)

        ShowTables ids hint ->
            model |> mapErdMCmd (showTables ids hint)

        ShowAllTables ->
            model |> mapErdMCmd showAllTables

        HideTable id ->
            ( model |> mapErdM (hideTable id), Cmd.none )

        ToggleColumns id ->
            let
                collapsed : Bool
                collapsed =
                    model.erd |> Maybe.andThen (\e -> e.tableProps |> Dict.get id) |> Maybe.mapOrElse .collapsed False
            in
            model |> mapErdMCmd (mapTablePropsCmd (mapTablePropOrSelected id (ErdTableProps.setCollapsed (not collapsed))))

        ShowColumn { table, column } ->
            ( model |> mapErdM (showColumn table column), Cmd.none )

        HideColumn { table, column } ->
            ( model |> mapErdM (hideColumn table column) |> hoverNextColumn table column, Cmd.none )

        ShowColumns id kind ->
            model |> mapErdMCmd (showColumns id kind)

        HideColumns id kind ->
            model |> mapErdMCmd (hideColumns id kind)

        SortColumns id kind ->
            model |> mapErdMCmd (sortColumns id kind)

        ToggleHiddenColumns id ->
            ( model |> mapErdM (mapTableProps (Dict.alter id (ErdTableProps.mapShowHiddenColumns not))), Cmd.none )

        SelectTable tableId ctrl ->
            if model.dragging |> Maybe.any DragState.hasMoved then
                ( model, Cmd.none )

            else
                ( model |> mapErdM (mapTableProps (Dict.map (\id -> ErdTableProps.mapSelected (\s -> B.cond (id == tableId) (not s) (B.cond ctrl s False))))), Cmd.none )

        TableMove id delta ->
            ( model |> mapErdM (mapTableProps (Dict.alter id (ErdTableProps.mapPosition (\p -> delta |> Delta.move p)))), Cmd.none )

        TablePosition id position ->
            ( model |> mapErdM (mapTableProps (Dict.alter id (ErdTableProps.setPosition position))), Cmd.none )

        TableOrder id index ->
            ( model |> mapErdM (mapShownTables (\tables -> tables |> List.move id (List.length tables - 1 - index))), Cmd.none )

        TableColor id color ->
            model |> mapErdMCmd (mapTablePropsCmd (mapTablePropOrSelected id (ErdTableProps.setColor color)))

        MoveColumn column position ->
            ( model |> mapErdM (\erd -> erd |> mapTableProps (Dict.alter column.table (ErdTableProps.mapShownColumns (List.moveBy identity column.column position) erd.notes))), Cmd.none )

        ToggleHoverTable table on ->
            ( { model | hoverTable = B.cond on (Just table) Nothing } |> mapErdM (mapTableProps (hoverTable table on)), Cmd.none )

        ToggleHoverColumn column on ->
            ( { model | hoverColumn = B.cond on (Just column) Nothing } |> mapErdM (\e -> e |> mapTableProps (hoverColumn column on e)), Cmd.none )

        CreateRelation src ref ->
            model |> mapErdMCmd (Source.addRelation now src ref)

        ResetCanvas ->
            ( model |> mapErdM (setCanvas CanvasProps.zero >> setShownTables [] >> setTableProps Dict.empty >> setUsedLayout Nothing), Cmd.none )

        LayoutMsg message ->
            model |> handleLayout now message

        NotesMsg message ->
            model |> handleNotes message

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
            model |> mapUploadCmd (ProjectUploadDialog.update model.erd message)

        ProjectSettingsMsg message ->
            model |> handleProjectSettings message

        SourceParsing message ->
            model |> mapSourceParsingMCmd (mapParsingCmd (SqlSourceUpload.update message SourceParsing))

        SourceParsed projectId source ->
            ( model, T.send (JsMessage (GotProject (Just (Ok (Project.create projectId source.name source))))) )

        HelpMsg message ->
            model |> handleHelp message

        CursorMode mode ->
            ( model |> setCursorMode mode, Cmd.none )

        FitContent ->
            ( model |> mapErdM (fitCanvas model.screen), Cmd.none )

        Fullscreen maybeId ->
            ( model, Ports.fullscreen maybeId )

        OnWheel event ->
            ( model |> mapErdM (mapCanvas (handleWheel event)), Cmd.none )

        Zoom delta ->
            ( model |> mapErdM (mapCanvas (zoomCanvas delta model.screen)), Cmd.none )

        Logout ->
            B.cond (model.erd |> Maybe.mapOrElse (\e -> e.project.storage /= ProjectStorage.Browser) False) (Cmd.batch [ Ports.logout, Request.pushRoute Route.Projects req ]) Ports.logout
                |> (\cmd -> ( { model | projects = model.projects |> List.filter (\p -> p.storage == ProjectStorage.Browser) }, cmd ))

        Focus id ->
            ( model, Ports.focus id )

        DropdownToggle id ->
            ( model |> Dropdown.update id, Cmd.none )

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
                    ( { id = id, init = pos, last = pos } |> (\d -> model |> setDragging (Just d) |> handleDrag d False), Cmd.none )

        DragMove pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging (Just d) |> handleDrag d False) model
            , Cmd.none
            )

        DragEnd pos ->
            ( model.dragging
                |> Maybe.map (DragState.setLast pos)
                |> Maybe.mapOrElse (\d -> model |> setDragging Nothing |> handleDrag d True) model
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
            model |> handleJsMessage currentLayout message

        Send cmd ->
            ( model, cmd )

        Noop _ ->
            ( model, Cmd.none )


handleJsMessage : Maybe LayoutName -> JsMsg -> Model -> ( Model, Cmd Msg )
handleJsMessage currentLayout msg model =
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
                                |> (\p -> currentLayout |> Maybe.mapOrElse (\l -> { p | usedLayout = Just l, layout = p.layouts |> Dict.getOrElse l p.layout }) p)
                                |> Erd.create (Random.initialSeed childSeed)
                    in
                    ( { model | seed = newSeed, loaded = True, erd = Just erd }
                    , Cmd.batch
                        [ Ports.observeSize Conf.ids.erd
                        , Ports.observeTablesSize erd.shownTables
                        , Ports.setMeta { title = Just (Views.title (Just erd)), description = Nothing, canonical = Nothing, html = Nothing, body = Nothing }
                        ]
                    )

        GotUser email user ->
            ( model |> mapUploadM (\u -> { u | shareUser = Just ( email, user ) }), Cmd.none )

        GotOwners _ owners ->
            ( model |> mapUploadM (\u -> { u | owners = owners }), Cmd.none )

        ProjectDropped projectId ->
            ( { model | projects = model.projects |> List.filter (\p -> p.id /= projectId) }, Cmd.none )

        GotLocalFile now projectId sourceId file content ->
            ( model, T.send (SqlSourceUpload.gotLocalFile now projectId sourceId file content |> PSSqlSourceMsg |> ProjectSettingsMsg) )

        GotRemoteFile now projectId sourceId url content sample ->
            if model.erd == Nothing then
                ( model, Cmd.batch [ T.send (SqlSourceUpload.gotRemoteFile now projectId sourceId url content sample |> SourceParsing) ] )

            else
                ( model, T.send (SqlSourceUpload.gotRemoteFile now projectId sourceId url content sample |> PSSqlSourceMsg |> ProjectSettingsMsg) )

        GotHotkey hotkey ->
            handleHotkey model hotkey

        GotKeyHold key start ->
            if key == "Space" && model.conf.move then
                if start then
                    ( model |> setCursorMode CursorDrag, Cmd.none )

                else
                    ( model |> setCursorMode CursorSelect, Cmd.none )

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

        GotResetCanvas ->
            ( model, T.send ResetCanvas )

        Error err ->
            ( model, Cmd.batch [ Toasts.error Toast ("Unable to decode JavaScript message: " ++ Decode.errorToHtml err), Ports.trackJsonError "js-message" err ] )


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes changes model =
    let
        modelWithSizes : Model
        modelWithSizes =
            changes |> List.sortBy (\c -> B.cond (c.id == Conf.ids.erd) 0 1) |> List.foldl updateSize model
    in
    if model.conf.fitOnLoad then
        ( modelWithSizes |> mapConf (\c -> { c | fitOnLoad = False }), T.send FitContent )

    else
        ( modelWithSizes, Cmd.none )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    if change.id == Conf.ids.erd then
        model |> mapScreen (setPosition change.position >> setSize change.size)

    else
        ( TableId.fromHtmlId change.id, model.erd |> Maybe.mapOrElse (.canvas >> CanvasProps.viewport model.screen) Area.zero )
            |> (\( tableId, viewport ) -> model |> mapErdM (mapTableProps (\props -> props |> Dict.alter tableId (updateTable props viewport change))))


updateTable : Dict TableId ErdTableProps -> Area -> SizeChange -> ErdTableProps -> ErdTableProps
updateTable allProps viewport change props =
    if props.size == Size.zero && props.position == Position.zero then
        props
            |> ErdTableProps.setSize change.size
            |> ErdTableProps.setPosition (computeInitialPosition allProps viewport change props.positionHint)

    else
        props |> ErdTableProps.setSize change.size


computeInitialPosition : Dict TableId ErdTableProps -> Area -> SizeChange -> Maybe PositionHint -> Position
computeInitialPosition allProps viewport change hint =
    hint
        |> Maybe.mapOrElse
            (\h ->
                case h of
                    PlaceLeft position ->
                        position |> Position.sub { left = change.size.width + 50, top = 0 } |> moveDownIfExists (allProps |> Dict.values) change.size

                    PlaceRight position size ->
                        position |> Position.add { left = size.width + 50, top = 0 } |> moveDownIfExists (allProps |> Dict.values) change.size

                    PlaceAt position ->
                        position
            )
            (if allProps |> Dict.filter (\_ p -> p.size /= Size.zero) |> Dict.isEmpty then
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


moveDownIfExists : List ErdTableProps -> Size -> Position -> Position
moveDownIfExists allProps size position =
    if allProps |> List.any (\p -> p.position == position || isSameTopRight p (Area position size)) then
        position |> Position.add { left = 0, top = Conf.ui.tableHeaderHeight } |> moveDownIfExists allProps size

    else
        position


isSameTopRight : AreaLike x -> AreaLike y -> Bool
isSameTopRight a b =
    a.position.top == b.position.top && a.position.left + a.size.width == b.position.left + b.size.width
