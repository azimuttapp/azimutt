module Services.Lenses exposing (mapActive, mapCanvas, mapColumns, mapEachProjectMLayoutTables, mapEachTable, mapEnabled, mapErdM, mapErdMCmd, mapFindPathM, mapHiddenColumns, mapHiddenTables, mapHover, mapLayout, mapLayouts, mapList, mapMobileMenuOpen, mapNavbar, mapNewLayoutM, mapOpened, mapOpenedDialogs, mapOpenedDropdown, mapOpenedPopover, mapParsing, mapParsingCmd, mapPosition, mapProjectM, mapProjectMCmd, mapProjectMLayout, mapProjectMLayoutTable, mapProjectMLayoutTables, mapProps, mapRelatedTables, mapRelations, mapRemoveViews, mapRemovedSchemas, mapResult, mapScreen, mapSearch, mapSelected, mapSelectionBox, mapSettings, mapShowHiddenColumns, mapShowSettings, mapShown, mapShownColumns, mapShownTables, mapSourceUploadM, mapSourceUploadMCmd, mapSources, mapSwitch, mapTableInList, mapTableProps, mapTables, mapTime, mapToasts, mapUsedLayout, mapVirtualRelationM, setActive, setCanvas, setColumn, setColumnOrder, setColumns, setConfirm, setCursorMode, setDragState, setDragging, setEnabled, setErd, setFindPath, setFrom, setHiddenColumns, setHiddenTables, setHighlighted, setHover, setHoverColumn, setIsOpen, setLast, setLayout, setLayouts, setList, setLoading, setMobileMenuOpen, setMouse, setName, setNavbar, setNewLayout, setNow, setOpened, setOpenedDialogs, setOpenedDropdown, setOpenedPopover, setParsing, setPosition, setProject, setProps, setRelatedTables, setRelations, setRemoveViews, setRemovedSchemas, setRemovedTables, setResult, setScreen, setSearch, setSelected, setSelection, setSelectionBox, setSettings, setShowSettings, setShown, setShownColumns, setShownTables, setSize, setSourceUpload, setSources, setSwitch, setTable, setTableProps, setTables, setText, setTime, setTo, setToastIdx, setToasts, setUsedLayout, setVirtualRelation, setZone, setZoom, updatePosition)

import Libs.Bool as B
import Libs.Delta exposing (Delta)
import Libs.Maybe as Maybe
import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)



-- helpers to update deep structures, keeping the reference equality when possible:
--  - `set*` helpers update the value
--  - `map*` helpers provide a transform function
--
-- functions should be ordered by property name


setActive : v -> { item | active : v } -> { item | active : v }
setActive =
    set .active (\value item -> { item | active = value })


mapActive : (v -> v) -> { item | active : v } -> { item | active : v }
mapActive =
    map .active setActive


setCanvas : v -> { item | canvas : v } -> { item | canvas : v }
setCanvas =
    set .canvas (\value item -> { item | canvas = value })


mapCanvas : (v -> v) -> { item | canvas : v } -> { item | canvas : v }
mapCanvas =
    map .canvas setCanvas


setColumn : v -> { item | column : v } -> { item | column : v }
setColumn =
    set .column (\value item -> { item | column = value })


setColumns : v -> { item | columns : v } -> { item | columns : v }
setColumns =
    set .columns (\value item -> { item | columns = value })


mapColumns : (v -> v) -> { item | columns : v } -> { item | columns : v }
mapColumns =
    map .columns setColumns


setColumnOrder : v -> { item | columnOrder : v } -> { item | columnOrder : v }
setColumnOrder =
    set .columnOrder (\value item -> { item | columnOrder = value })


setConfirm : v -> { item | confirm : v } -> { item | confirm : v }
setConfirm =
    set .confirm (\value item -> { item | confirm = value })


setCursorMode : v -> { item | cursorMode : v } -> { item | cursorMode : v }
setCursorMode =
    set .cursorMode (\value item -> { item | cursorMode = value })


setDragging : v -> { item | dragging : v } -> { item | dragging : v }
setDragging =
    set .dragging (\value item -> { item | dragging = value })


setDragState : v -> { item | dragState : v } -> { item | dragState : v }
setDragState =
    set .dragState (\value item -> { item | dragState = value })


setEnabled : v -> { item | enabled : v } -> { item | enabled : v }
setEnabled =
    set .enabled (\value item -> { item | enabled = value })


mapEnabled : (v -> v) -> { item | enabled : v } -> { item | enabled : v }
mapEnabled =
    map .enabled setEnabled


setErd : v -> { item | erd : v } -> { item | erd : v }
setErd =
    set .erd (\value item -> { item | erd = value })


mapErdM : (v -> v) -> { item | erd : Maybe v } -> { item | erd : Maybe v }
mapErdM =
    mapM .erd setErd


mapErdMCmd : (v -> ( v, Cmd msg )) -> { item | erd : Maybe v } -> ( { item | erd : Maybe v }, Cmd msg )
mapErdMCmd =
    mapMCmd .erd setErd


setFindPath : v -> { item | findPath : v } -> { item | findPath : v }
setFindPath =
    set .findPath (\value item -> { item | findPath = value })


mapFindPathM : (v -> v) -> { item | findPath : Maybe v } -> { item | findPath : Maybe v }
mapFindPathM =
    mapM .findPath setFindPath


setFrom : v -> { item | from : v } -> { item | from : v }
setFrom =
    set .from (\value item -> { item | from = value })


setHiddenColumns : v -> { item | hiddenColumns : v } -> { item | hiddenColumns : v }
setHiddenColumns =
    set .hiddenColumns (\value item -> { item | hiddenColumns = value })


mapHiddenColumns : (v -> v) -> { item | hiddenColumns : v } -> { item | hiddenColumns : v }
mapHiddenColumns =
    map .hiddenColumns setHiddenColumns


setHiddenTables : v -> { item | hiddenTables : v } -> { item | hiddenTables : v }
setHiddenTables =
    set .hiddenTables (\value item -> { item | hiddenTables = value })


mapHiddenTables : (v -> v) -> { item | hiddenTables : v } -> { item | hiddenTables : v }
mapHiddenTables =
    map .hiddenTables setHiddenTables


setHighlighted : v -> { item | highlighted : v } -> { item | highlighted : v }
setHighlighted =
    set .highlighted (\value item -> { item | highlighted = value })


setHover : v -> { item | hover : v } -> { item | hover : v }
setHover =
    set .hover (\value item -> { item | hover = value })


mapHover : (v -> v) -> { item | hover : v } -> { item | hover : v }
mapHover =
    map .hover setHover


setHoverColumn : v -> { item | hoverColumn : v } -> { item | hoverColumn : v }
setHoverColumn =
    set .hoverColumn (\value item -> { item | hoverColumn = value })


setIsOpen : v -> { item | isOpen : v } -> { item | isOpen : v }
setIsOpen =
    set .isOpen (\value item -> { item | isOpen = value })


setLast : v -> { item | last : v } -> { item | last : v }
setLast =
    set .last (\value item -> { item | last = value })


setLayout : v -> { item | layout : v } -> { item | layout : v }
setLayout =
    set .layout (\value item -> { item | layout = value })


mapLayout : (v -> v) -> { item | layout : v } -> { item | layout : v }
mapLayout =
    map .layout setLayout


setLayouts : v -> { item | layouts : v } -> { item | layouts : v }
setLayouts =
    set .layouts (\value item -> { item | layouts = value })


mapLayouts : (v -> v) -> { item | layouts : v } -> { item | layouts : v }
mapLayouts =
    map .layouts setLayouts


setList : v -> { item | list : v } -> { item | list : v }
setList =
    set .list (\value item -> { item | list = value })


setLoading : v -> { item | loading : v } -> { item | loading : v }
setLoading =
    set .loading (\value item -> { item | loading = value })


setMobileMenuOpen : v -> { item | mobileMenuOpen : v } -> { item | mobileMenuOpen : v }
setMobileMenuOpen =
    set .mobileMenuOpen (\value item -> { item | mobileMenuOpen = value })


mapMobileMenuOpen : (v -> v) -> { item | mobileMenuOpen : v } -> { item | mobileMenuOpen : v }
mapMobileMenuOpen =
    map .mobileMenuOpen setMobileMenuOpen


setMouse : v -> { item | mouse : v } -> { item | mouse : v }
setMouse =
    set .mouse (\value item -> { item | mouse = value })


setName : v -> { item | name : v } -> { item | name : v }
setName =
    set .name (\value item -> { item | name = value })


setNavbar : v -> { item | navbar : v } -> { item | navbar : v }
setNavbar =
    set .navbar (\value item -> { item | navbar = value })


mapNavbar : (v -> v) -> { item | navbar : v } -> { item | navbar : v }
mapNavbar =
    map .navbar setNavbar


setNewLayout : v -> { item | newLayout : v } -> { item | newLayout : v }
setNewLayout =
    set .newLayout (\value item -> { item | newLayout = value })


mapNewLayoutM : (v -> v) -> { item | newLayout : Maybe v } -> { item | newLayout : Maybe v }
mapNewLayoutM =
    mapM .newLayout setNewLayout


setNow : v -> { item | now : v } -> { item | now : v }
setNow =
    set .now (\value item -> { item | now = value })


setOpened : v -> { item | opened : v } -> { item | opened : v }
setOpened =
    set .opened (\value item -> { item | opened = value })


mapOpened : (v -> v) -> { item | opened : v } -> { item | opened : v }
mapOpened =
    map .opened setOpened


setOpenedDropdown : v -> { item | openedDropdown : v } -> { item | openedDropdown : v }
setOpenedDropdown =
    set .openedDropdown (\value item -> { item | openedDropdown = value })


mapOpenedDropdown : (v -> v) -> { item | openedDropdown : v } -> { item | openedDropdown : v }
mapOpenedDropdown =
    map .openedDropdown setOpenedDropdown


setOpenedPopover : v -> { item | openedPopover : v } -> { item | openedPopover : v }
setOpenedPopover =
    set .openedPopover (\value item -> { item | openedPopover = value })


mapOpenedPopover : (v -> v) -> { item | openedPopover : v } -> { item | openedPopover : v }
mapOpenedPopover =
    map .openedPopover setOpenedPopover


setOpenedDialogs : v -> { item | openedDialogs : v } -> { item | openedDialogs : v }
setOpenedDialogs =
    set .openedDialogs (\value item -> { item | openedDialogs = value })


mapOpenedDialogs : (v -> v) -> { item | openedDialogs : v } -> { item | openedDialogs : v }
mapOpenedDialogs =
    map .openedDialogs setOpenedDialogs


setParsing : v -> { item | parsing : v } -> { item | parsing : v }
setParsing =
    set .parsing (\value item -> { item | parsing = value })


mapParsing : (v -> v) -> { item | parsing : v } -> { item | parsing : v }
mapParsing =
    map .parsing setParsing


mapParsingCmd : (v -> ( v, Cmd msg )) -> { item | parsing : v } -> ( { item | parsing : v }, Cmd msg )
mapParsingCmd =
    mapCmd .parsing setParsing


setPosition : v -> { item | position : v } -> { item | position : v }
setPosition =
    set .position (\value item -> { item | position = value })


mapPosition : (v -> v) -> { item | position : v } -> { item | position : v }
mapPosition =
    map .position setPosition


setProject : v -> { item | project : v } -> { item | project : v }
setProject =
    set .project (\value item -> { item | project = value })


mapProjectM : (v -> v) -> { item | project : Maybe v } -> { item | project : Maybe v }
mapProjectM =
    mapM .project setProject


mapProjectMCmd : (v -> ( v, Cmd msg )) -> { item | project : Maybe v } -> ( { item | project : Maybe v }, Cmd msg )
mapProjectMCmd =
    mapMCmd .project setProject


setProps : v -> { item | props : v } -> { item | props : v }
setProps =
    set .props (\value item -> { item | props = value })


mapProps : (v -> v) -> { item | props : v } -> { item | props : v }
mapProps =
    map .props setProps


setRelatedTables : v -> { item | relatedTables : v } -> { item | relatedTables : v }
setRelatedTables =
    set .relatedTables (\value item -> { item | relatedTables = value })


mapRelatedTables : (v -> v) -> { item | relatedTables : v } -> { item | relatedTables : v }
mapRelatedTables =
    map .relatedTables setRelatedTables


setRelations : v -> { item | relations : v } -> { item | relations : v }
setRelations =
    set .relations (\value item -> { item | relations = value })


mapRelations : (v -> v) -> { item | relations : v } -> { item | relations : v }
mapRelations =
    map .relations setRelations


setRemovedTables : v -> { item | removedTables : v } -> { item | removedTables : v }
setRemovedTables =
    set .removedTables (\value item -> { item | removedTables = value })


setRemovedSchemas : v -> { item | removedSchemas : v } -> { item | removedSchemas : v }
setRemovedSchemas =
    set .removedSchemas (\value item -> { item | removedSchemas = value })


mapRemovedSchemas : (v -> v) -> { item | removedSchemas : v } -> { item | removedSchemas : v }
mapRemovedSchemas =
    map .removedSchemas setRemovedSchemas


setRemoveViews : v -> { item | removeViews : v } -> { item | removeViews : v }
setRemoveViews =
    set .removeViews (\value item -> { item | removeViews = value })


mapRemoveViews : (v -> v) -> { item | removeViews : v } -> { item | removeViews : v }
mapRemoveViews =
    map .removeViews setRemoveViews


setResult : v -> { item | result : v } -> { item | result : v }
setResult =
    set .result (\value item -> { item | result = value })


mapResult : (v -> v) -> { item | result : v } -> { item | result : v }
mapResult =
    map .result setResult


setScreen : v -> { item | screen : v } -> { item | screen : v }
setScreen =
    set .screen (\value item -> { item | screen = value })


mapScreen : (v -> v) -> { item | screen : v } -> { item | screen : v }
mapScreen =
    map .screen setScreen


setSearch : v -> { item | search : v } -> { item | search : v }
setSearch =
    set .search (\value item -> { item | search = value })


mapSearch : (v -> v) -> { item | search : v } -> { item | search : v }
mapSearch =
    map .search setSearch


setSelection : v -> { item | selection : v } -> { item | selection : v }
setSelection =
    set .selection (\value item -> { item | selection = value })


setSettings : v -> { item | settings : v } -> { item | settings : v }
setSettings =
    set .settings (\value item -> { item | settings = value })


mapSettings : (v -> v) -> { item | settings : v } -> { item | settings : v }
mapSettings =
    map .settings setSettings


setSelected : v -> { item | selected : v } -> { item | selected : v }
setSelected =
    set .selected (\value item -> { item | selected = value })


mapSelected : (v -> v) -> { item | selected : v } -> { item | selected : v }
mapSelected =
    map .selected setSelected


setSelectionBox : v -> { item | selectionBox : v } -> { item | selectionBox : v }
setSelectionBox =
    set .selectionBox (\value item -> { item | selectionBox = value })


mapSelectionBox : (v -> v) -> { item | selectionBox : v } -> { item | selectionBox : v }
mapSelectionBox =
    map .selectionBox setSelectionBox


setShown : v -> { item | shown : v } -> { item | shown : v }
setShown =
    set .shown (\value item -> { item | shown = value })


mapShown : (v -> v) -> { item | shown : v } -> { item | shown : v }
mapShown =
    map .shown setShown


setShownColumns : v -> { item | shownColumns : v } -> { item | shownColumns : v }
setShownColumns =
    set .shownColumns (\value item -> { item | shownColumns = value })


mapShownColumns : (v -> v) -> { item | shownColumns : v } -> { item | shownColumns : v }
mapShownColumns =
    map .shownColumns setShownColumns


setShownTables : v -> { item | shownTables : v } -> { item | shownTables : v }
setShownTables =
    set .shownTables (\value item -> { item | shownTables = value })


mapShownTables : (v -> v) -> { item | shownTables : v } -> { item | shownTables : v }
mapShownTables =
    map .shownTables setShownTables


setShowHiddenColumns : v -> { item | showHiddenColumns : v } -> { item | showHiddenColumns : v }
setShowHiddenColumns =
    set .showHiddenColumns (\value item -> { item | showHiddenColumns = value })


mapShowHiddenColumns : (v -> v) -> { item | showHiddenColumns : v } -> { item | showHiddenColumns : v }
mapShowHiddenColumns =
    map .showHiddenColumns setShowHiddenColumns


setShowSettings : v -> { item | showSettings : v } -> { item | showSettings : v }
setShowSettings =
    set .showSettings (\value item -> { item | showSettings = value })


mapShowSettings : (v -> v) -> { item | showSettings : v } -> { item | showSettings : v }
mapShowSettings =
    map .showSettings setShowSettings


setSize : v -> { item | size : v } -> { item | size : v }
setSize =
    set .size (\value item -> { item | size = value })


setSources : v -> { item | sources : v } -> { item | sources : v }
setSources =
    set .sources (\value item -> { item | sources = value })


mapSources : (v -> v) -> { item | sources : v } -> { item | sources : v }
mapSources =
    map .sources setSources


setSourceUpload : v -> { item | sourceUpload : v } -> { item | sourceUpload : v }
setSourceUpload =
    set .sourceUpload (\value item -> { item | sourceUpload = value })


mapSourceUploadM : (v -> v) -> { item | sourceUpload : Maybe v } -> { item | sourceUpload : Maybe v }
mapSourceUploadM =
    mapM .sourceUpload setSourceUpload


mapSourceUploadMCmd : (v -> ( v, Cmd msg )) -> { item | sourceUpload : Maybe v } -> ( { item | sourceUpload : Maybe v }, Cmd msg )
mapSourceUploadMCmd =
    mapMCmd .sourceUpload setSourceUpload


setSwitch : v -> { item | switch : v } -> { item | switch : v }
setSwitch =
    set .switch (\value item -> { item | switch = value })


mapSwitch : (v -> v) -> { item | switch : v } -> { item | switch : v }
mapSwitch =
    map .switch setSwitch


setTable : v -> { item | table : v } -> { item | table : v }
setTable =
    set .table (\value item -> { item | table = value })


setTables : v -> { item | tables : v } -> { item | tables : v }
setTables =
    set .tables (\value item -> { item | tables = value })


mapTables : (v -> v) -> { item | tables : v } -> { item | tables : v }
mapTables =
    map .tables setTables


setTableProps : v -> { item | tableProps : v } -> { item | tableProps : v }
setTableProps =
    set .tableProps (\value item -> { item | tableProps = value })


mapTableProps : (v -> v) -> { item | tableProps : v } -> { item | tableProps : v }
mapTableProps =
    map .tableProps setTableProps


setText : v -> { item | text : v } -> { item | text : v }
setText =
    set .text (\value item -> { item | text = value })


setTime : v -> { item | time : v } -> { item | time : v }
setTime =
    set .time (\value item -> { item | time = value })


mapTime : (v -> v) -> { item | time : v } -> { item | time : v }
mapTime =
    map .time setTime


setTo : v -> { item | to : v } -> { item | to : v }
setTo =
    set .to (\value item -> { item | to = value })


setToasts : v -> { item | toasts : v } -> { item | toasts : v }
setToasts =
    set .toasts (\value item -> { item | toasts = value })


mapToasts : (v -> v) -> { item | toasts : v } -> { item | toasts : v }
mapToasts =
    map .toasts setToasts


setToastIdx : v -> { item | toastIdx : v } -> { item | toastIdx : v }
setToastIdx =
    set .toastIdx (\value item -> { item | toastIdx = value })


setUsedLayout : v -> { item | usedLayout : v } -> { item | usedLayout : v }
setUsedLayout =
    set .usedLayout (\value item -> { item | usedLayout = value })


mapUsedLayout : (v -> v) -> { item | usedLayout : v } -> { item | usedLayout : v }
mapUsedLayout =
    map .usedLayout setUsedLayout


setVirtualRelation : v -> { item | virtualRelation : v } -> { item | virtualRelation : v }
setVirtualRelation =
    set .virtualRelation (\value item -> { item | virtualRelation = value })


mapVirtualRelationM : (v -> v) -> { item | virtualRelation : Maybe v } -> { item | virtualRelation : Maybe v }
mapVirtualRelationM =
    mapM .virtualRelation setVirtualRelation


setZoom : v -> { item | zoom : v } -> { item | zoom : v }
setZoom =
    set .zoom (\value item -> { item | zoom = value })


setZone : v -> { item | zone : v } -> { item | zone : v }
setZone =
    set .zone (\value item -> { item | zone = value })


set : (item -> v) -> (v -> item -> item) -> v -> item -> item
set get update value item =
    if get item == value then
        item

    else
        update value item


map : (item -> v) -> (v -> item -> item) -> (v -> v) -> item -> item
map get update transform item =
    update (item |> get |> transform) item


mapM : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> v) -> item -> item
mapM get update transform item =
    update (item |> get |> Maybe.map transform) item


mapCmd : (item -> v) -> (v -> item -> item) -> (v -> ( v, Cmd msg )) -> item -> ( item, Cmd msg )
mapCmd get update transform item =
    item |> get |> transform |> Tuple.mapFirst (\value -> update value item)


mapMCmd : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> ( v, Cmd msg )) -> item -> ( item, Cmd msg )
mapMCmd get update transform item =
    item |> get |> Maybe.mapOrElse (transform >> Tuple.mapFirst (\value -> update (Just value) item)) ( item, Cmd.none )



-- specific methods


mapList : (item -> k) -> k -> (item -> item) -> List item -> List item
mapList get key transform list =
    list
        |> List.map
            (\item ->
                if get item == key then
                    transform item

                else
                    item
            )


mapProjectMLayout : (l -> l) -> { m | project : Maybe { p | layout : l } } -> { m | project : Maybe { p | layout : l } }
mapProjectMLayout transform item =
    mapProjectM (mapLayout transform) item


mapProjectMLayoutTables : (t -> t) -> { m | project : Maybe { p | layout : { l | tables : t } } } -> { m | project : Maybe { p | layout : { l | tables : t } } }
mapProjectMLayoutTables transform item =
    mapProjectM (mapLayout (mapTables transform)) item


mapEachProjectMLayoutTables : ({ t | id : comparable } -> { t | id : comparable }) -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } } -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } }
mapEachProjectMLayoutTables transform item =
    mapProjectMLayoutTables (List.map transform) item


mapProjectMLayoutTable : comparable -> ({ t | id : comparable } -> { t | id : comparable }) -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } } -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } }
mapProjectMLayoutTable id transform item =
    mapProjectM (mapLayout (mapTableInList .id id transform)) item


mapTableInList : (table -> comparable) -> comparable -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
mapTableInList get id transform item =
    mapEachTable (\t -> get t == id) transform item


mapEachTable : (table -> Bool) -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
mapEachTable predicate transform item =
    mapTables (\tables -> tables |> List.map (\t -> B.cond (predicate t) (transform t) t)) item


updatePosition : Delta -> ZoomLevel -> { item | position : Position } -> { item | position : Position }
updatePosition delta zoom item =
    { item | position = Position (item.position.left + (delta.dx / zoom)) (item.position.top + (delta.dy / zoom)) }



--pure : a -> ( a, Cmd msg )
--pure a =
--    ( a, Cmd.none )
--
--
--map : (a -> b) -> ( a, Cmd msg ) -> ( b, Cmd msg )
--map f ( a, cmd ) =
--    ( f a, cmd )
--
--
--andThen : (a -> ( b, Cmd msg )) -> ( a, Cmd msg ) -> ( b, Cmd msg )
--andThen f ( a, cmd1 ) =
--    f a |> Tuple.mapSecond (\cmd2 -> Cmd.batch [ cmd1, cmd2 ])
