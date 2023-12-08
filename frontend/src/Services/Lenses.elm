module Services.Lenses exposing
    ( mapActive
    , mapAmlSidebarM
    , mapAmlSourceCmd
    , mapBodyCmd
    , mapCanvas
    , mapCanvasT
    , mapCollapseTableColumns
    , mapColumnBasicTypes
    , mapColumns
    , mapContent
    , mapContextMenuM
    , mapDataExplorerCmd
    , mapDatabaseSourceCmd
    , mapDatabaseSourceMCmd
    , mapDetailsCmd
    , mapDetailsSidebarCmd
    , mapEditGroupM
    , mapEditMemoM
    , mapEditNotesM
    , mapEditTagsM
    , mapEmbedSourceParsingMCmd
    , mapEnabled
    , mapErdM
    , mapErdMCmd
    , mapErdMT
    , mapErdMTM
    , mapExportDialogCmd
    , mapFilters
    , mapFindPath
    , mapFindPathM
    , mapGroups
    , mapHidden
    , mapHiddenColumns
    , mapHoverTable
    , mapIndex
    , mapJsonSourceCmd
    , mapJsonSourceMCmd
    , mapLayouts
    , mapLayoutsD
    , mapLayoutsDCmd
    , mapLayoutsDTM
    , mapList
    , mapMCmd
    , mapMemos
    , mapMemosL
    , mapMetadata
    , mapMobileMenuOpen
    , mapNavbar
    , mapNewLayoutMCmd
    , mapOpened
    , mapOpenedDialogs
    , mapOpenedDropdown
    , mapOrganization
    , mapOrganizationM
    , mapParsedSchemaM
    , mapPlan
    , mapPosition
    , mapPrismaSourceCmd
    , mapPrismaSourceMCmd
    , mapProject
    , mapProjectSourceMCmd
    , mapPromptM
    , mapProps
    , mapRelatedTables
    , mapRelations
    , mapRemoveViews
    , mapRemovedSchemas
    , mapResult
    , mapResultsCmd
    , mapSampleSourceMCmd
    , mapSaveCmd
    , mapSchemaAnalysisM
    , mapSearch
    , mapSelected
    , mapSettings
    , mapSettingsM
    , mapSharingCmd
    , mapShow
    , mapShowHiddenColumns
    , mapShowSettings
    , mapSourceUpdateCmd
    , mapSqlSourceCmd
    , mapSqlSourceMCmd
    , mapState
    , mapTableRows
    , mapTableRowsCmd
    , mapTableRowsSeq
    , mapTables
    , mapTablesCmd
    , mapTablesL
    , mapToasts
    , mapToastsCmd
    , mapTokenFormM
    , mapVirtualRelationM
    , mapVisualEditor
    , setActive
    , setAmlSidebar
    , setAmlSource
    , setBody
    , setCanvas
    , setCollapseTableColumns
    , setCollapsed
    , setColor
    , setColors
    , setColumnBasicTypes
    , setColumnOrder
    , setColumns
    , setConfirm
    , setContent
    , setContextMenu
    , setCurrentLayout
    , setCursorMode
    , setDataExplorer
    , setDatabaseSource
    , setDefaultSchema
    , setDetails
    , setDetailsSidebar
    , setDragging
    , setEditGroup
    , setEditMemo
    , setEditNotes
    , setEditTags
    , setEmbedSourceParsing
    , setEnabled
    , setErd
    , setErrors
    , setExpire
    , setExportDialog
    , setFilters
    , setFindPath
    , setFrom
    , setGroups
    , setHidden
    , setHiddenColumns
    , setHighlight
    , setHighlighted
    , setHoverColumn
    , setHoverTable
    , setHoverTableRow
    , setId
    , setIgnoredColumns
    , setIgnoredTables
    , setIndex
    , setInput
    , setIsOpen
    , setJsonSource
    , setLast
    , setLayoutOnLoad
    , setLayouts
    , setList
    , setMax
    , setMemos
    , setMetadata
    , setMobileMenuOpen
    , setModal
    , setMouse
    , setName
    , setNavbar
    , setNewLayout
    , setNotes
    , setOpened
    , setOpenedDialogs
    , setOpenedDropdown
    , setOpenedPopover
    , setOperation
    , setOperator
    , setOrganization
    , setParsedSchema
    , setParsedSource
    , setPlan
    , setPosition
    , setPrevious
    , setPrismaSource
    , setProject
    , setProjectSource
    , setPrompt
    , setProps
    , setQuery
    , setRelatedTables
    , setRelationStyle
    , setRelations
    , setRemoveViews
    , setRemovedSchemas
    , setRemovedTables
    , setResult
    , setResults
    , setSampleSource
    , setSave
    , setSchemaAnalysis
    , setScroll
    , setSearch
    , setSelected
    , setSelectionBox
    , setSettings
    , setSharing
    , setShow
    , setShowHiddenColumns
    , setShowSettings
    , setShown
    , setSize
    , setSourceUpdate
    , setSqlSource
    , setState
    , setTableRows
    , setTableRowsSeq
    , setTables
    , setTags
    , setText
    , setTo
    , setToasts
    , setToken
    , setTokenForm
    , setTokens
    , setUpdatedAt
    , setValue
    , setView
    , setVirtualRelation
    , setVisualEditor
    , setZoom
    )

import Dict exposing (Dict)
import Libs.Maybe as Maybe



-- helpers to update deep structures, keeping the reference equality when possible:
--  - `set*` helpers update the value
--  - `map*` helpers provide a transform function
--
-- functions should be ordered by property name


setActive : v -> { item | active : v } -> { item | active : v }
setActive =
    set_ .active (\value item -> { item | active = value })


mapActive : (v -> v) -> { item | active : v } -> { item | active : v }
mapActive =
    map_ .active setActive


setAmlSidebar : v -> { item | amlSidebar : v } -> { item | amlSidebar : v }
setAmlSidebar =
    set_ .amlSidebar (\value item -> { item | amlSidebar = value })


mapAmlSidebarM : (v -> v) -> { item | amlSidebar : Maybe v } -> { item | amlSidebar : Maybe v }
mapAmlSidebarM =
    mapM_ .amlSidebar setAmlSidebar


setAmlSource : v -> { item | amlSource : v } -> { item | amlSource : v }
setAmlSource =
    set_ .amlSource (\value item -> { item | amlSource = value })


mapAmlSourceCmd : (v -> ( v, Cmd msg )) -> { item | amlSource : v } -> ( { item | amlSource : v }, Cmd msg )
mapAmlSourceCmd =
    mapT_ .amlSource setAmlSource


setBody : v -> { item | body : v } -> { item | body : v }
setBody =
    set_ .body (\value item -> { item | body = value })


mapBodyCmd : (v -> ( v, Cmd msg )) -> { item | body : v } -> ( { item | body : v }, Cmd msg )
mapBodyCmd =
    mapT_ .body setBody


setCanvas : v -> { item | canvas : v } -> { item | canvas : v }
setCanvas =
    set_ .canvas (\value item -> { item | canvas = value })


mapCanvas : (v -> v) -> { item | canvas : v } -> { item | canvas : v }
mapCanvas =
    map_ .canvas setCanvas


mapCanvasT : (v -> ( v, a )) -> { item | canvas : v } -> ( { item | canvas : v }, a )
mapCanvasT =
    mapT_ .canvas setCanvas


setCollapsed : v -> { item | collapsed : v } -> { item | collapsed : v }
setCollapsed =
    set_ .collapsed (\value item -> { item | collapsed = value })


setCollapseTableColumns : v -> { item | collapseTableColumns : v } -> { item | collapseTableColumns : v }
setCollapseTableColumns =
    set_ .collapseTableColumns (\value item -> { item | collapseTableColumns = value })


mapCollapseTableColumns : (v -> v) -> { item | collapseTableColumns : v } -> { item | collapseTableColumns : v }
mapCollapseTableColumns =
    map_ .collapseTableColumns setCollapseTableColumns


setColor : v -> { item | color : v } -> { item | color : v }
setColor =
    set_ .color (\value item -> { item | color = value })


setColors : v -> { item | colors : v } -> { item | colors : v }
setColors =
    set_ .colors (\value item -> { item | colors = value })


setColumns : v -> { item | columns : v } -> { item | columns : v }
setColumns =
    set_ .columns (\value item -> { item | columns = value })


mapColumns : (v -> v) -> { item | columns : v } -> { item | columns : v }
mapColumns =
    map_ .columns setColumns


setColumnBasicTypes : v -> { item | columnBasicTypes : v } -> { item | columnBasicTypes : v }
setColumnBasicTypes =
    set_ .columnBasicTypes (\value item -> { item | columnBasicTypes = value })


mapColumnBasicTypes : (v -> v) -> { item | columnBasicTypes : v } -> { item | columnBasicTypes : v }
mapColumnBasicTypes =
    map_ .columnBasicTypes setColumnBasicTypes


setColumnOrder : v -> { item | columnOrder : v } -> { item | columnOrder : v }
setColumnOrder =
    set_ .columnOrder (\value item -> { item | columnOrder = value })


setConfirm : v -> { item | confirm : v } -> { item | confirm : v }
setConfirm =
    set_ .confirm (\value item -> { item | confirm = value })


setContent : v -> { item | content : v } -> { item | content : v }
setContent =
    set_ .content (\value item -> { item | content = value })


mapContent : (v -> v) -> { item | content : v } -> { item | content : v }
mapContent =
    map_ .content setContent


setContextMenu : v -> { item | contextMenu : v } -> { item | contextMenu : v }
setContextMenu =
    set_ .contextMenu (\value item -> { item | contextMenu = value })


mapContextMenuM : (v -> v) -> { item | contextMenu : Maybe v } -> { item | contextMenu : Maybe v }
mapContextMenuM =
    mapM_ .contextMenu setContextMenu


setCurrentLayout : v -> { item | currentLayout : v } -> { item | currentLayout : v }
setCurrentLayout =
    set_ .currentLayout (\value item -> { item | currentLayout = value })


setCursorMode : v -> { item | cursorMode : v } -> { item | cursorMode : v }
setCursorMode =
    set_ .cursorMode (\value item -> { item | cursorMode = value })


setDatabaseSource : v -> { item | databaseSource : v } -> { item | databaseSource : v }
setDatabaseSource =
    set_ .databaseSource (\value item -> { item | databaseSource = value })


mapDatabaseSourceCmd : (v -> ( v, Cmd msg )) -> { item | databaseSource : v } -> ( { item | databaseSource : v }, Cmd msg )
mapDatabaseSourceCmd =
    mapT_ .databaseSource setDatabaseSource


mapDatabaseSourceMCmd : (v -> ( v, Cmd msg )) -> { item | databaseSource : Maybe v } -> ( { item | databaseSource : Maybe v }, Cmd msg )
mapDatabaseSourceMCmd transform item =
    mapMT_ .databaseSource setDatabaseSource transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setDataExplorer : v -> { item | dataExplorer : v } -> { item | dataExplorer : v }
setDataExplorer =
    set_ .dataExplorer (\value item -> { item | dataExplorer = value })


mapDataExplorerCmd : (v -> ( v, Cmd msg )) -> { item | dataExplorer : v } -> ( { item | dataExplorer : v }, Cmd msg )
mapDataExplorerCmd =
    mapT_ .dataExplorer setDataExplorer


setDefaultSchema : v -> { item | defaultSchema : v } -> { item | defaultSchema : v }
setDefaultSchema =
    set_ .defaultSchema (\value item -> { item | defaultSchema = value })


setDetails : v -> { item | details : v } -> { item | details : v }
setDetails =
    set_ .details (\value item -> { item | details = value })


mapDetailsCmd : (v -> ( v, Cmd msg )) -> { item | details : v } -> ( { item | details : v }, Cmd msg )
mapDetailsCmd =
    mapT_ .details setDetails


setDetailsSidebar : v -> { item | detailsSidebar : v } -> { item | detailsSidebar : v }
setDetailsSidebar =
    set_ .detailsSidebar (\value item -> { item | detailsSidebar = value })


mapDetailsSidebarCmd : (v -> ( v, Cmd msg )) -> { item | detailsSidebar : v } -> ( { item | detailsSidebar : v }, Cmd msg )
mapDetailsSidebarCmd =
    mapT_ .detailsSidebar setDetailsSidebar


setDragging : v -> { item | dragging : v } -> { item | dragging : v }
setDragging =
    set_ .dragging (\value item -> { item | dragging = value })


setEditGroup : v -> { item | editGroup : v } -> { item | editGroup : v }
setEditGroup =
    set_ .editGroup (\value item -> { item | editGroup = value })


mapEditGroupM : (v -> v) -> { item | editGroup : Maybe v } -> { item | editGroup : Maybe v }
mapEditGroupM =
    mapM_ .editGroup setEditGroup


setEditMemo : v -> { item | editMemo : v } -> { item | editMemo : v }
setEditMemo =
    set_ .editMemo (\value item -> { item | editMemo = value })


mapEditMemoM : (v -> v) -> { item | editMemo : Maybe v } -> { item | editMemo : Maybe v }
mapEditMemoM =
    mapM_ .editMemo setEditMemo


setEditNotes : v -> { item | editNotes : v } -> { item | editNotes : v }
setEditNotes =
    set_ .editNotes (\value item -> { item | editNotes = value })


mapEditNotesM : (v -> v) -> { item | editNotes : Maybe v } -> { item | editNotes : Maybe v }
mapEditNotesM =
    mapM_ .editNotes setEditNotes


setEditTags : v -> { item | editTags : v } -> { item | editTags : v }
setEditTags =
    set_ .editTags (\value item -> { item | editTags = value })


mapEditTagsM : (v -> v) -> { item | editTags : Maybe v } -> { item | editTags : Maybe v }
mapEditTagsM =
    mapM_ .editTags setEditTags


setEmbedSourceParsing : v -> { item | embedSourceParsing : v } -> { item | embedSourceParsing : v }
setEmbedSourceParsing =
    set_ .embedSourceParsing (\value item -> { item | embedSourceParsing = value })


mapEmbedSourceParsingMCmd : (v -> ( v, Cmd msg )) -> { item | embedSourceParsing : Maybe v } -> ( { item | embedSourceParsing : Maybe v }, Cmd msg )
mapEmbedSourceParsingMCmd transform item =
    mapMT_ .embedSourceParsing setEmbedSourceParsing transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setEnabled : v -> { item | enabled : v } -> { item | enabled : v }
setEnabled =
    set_ .enabled (\value item -> { item | enabled = value })


mapEnabled : (v -> v) -> { item | enabled : v } -> { item | enabled : v }
mapEnabled =
    map_ .enabled setEnabled


setErd : v -> { item | erd : v } -> { item | erd : v }
setErd =
    set_ .erd (\value item -> { item | erd = value })


mapErdM : (v -> v) -> { item | erd : Maybe v } -> { item | erd : Maybe v }
mapErdM =
    mapM_ .erd setErd


mapErdMT : (v -> ( v, a )) -> { item | erd : Maybe v } -> ( { item | erd : Maybe v }, Maybe a )
mapErdMT =
    mapMT_ .erd setErd


mapErdMCmd : (v -> ( v, Cmd msg )) -> { item | erd : Maybe v } -> ( { item | erd : Maybe v }, Cmd msg )
mapErdMCmd transform item =
    mapMT_ .erd setErd transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


mapErdMTM : (v -> ( v, Maybe a )) -> { item | erd : Maybe v } -> ( { item | erd : Maybe v }, Maybe a )
mapErdMTM =
    mapMTM_ .erd setErd


setErrors : v -> { item | errors : v } -> { item | errors : v }
setErrors =
    set_ .errors (\value item -> { item | errors = value })


setExpire : v -> { item | expire : v } -> { item | expire : v }
setExpire =
    set_ .expire (\value item -> { item | expire = value })


setExportDialog : v -> { item | exportDialog : v } -> { item | exportDialog : v }
setExportDialog =
    set_ .exportDialog (\value item -> { item | exportDialog = value })


mapExportDialogCmd : (v -> ( v, Cmd msg )) -> { item | exportDialog : v } -> ( { item | exportDialog : v }, Cmd msg )
mapExportDialogCmd =
    mapT_ .exportDialog setExportDialog


setFilters : v -> { item | filters : v } -> { item | filters : v }
setFilters =
    set_ .filters (\value item -> { item | filters = value })


mapFilters : (v -> v) -> { item | filters : v } -> { item | filters : v }
mapFilters =
    map_ .filters setFilters


setFindPath : v -> { item | findPath : v } -> { item | findPath : v }
setFindPath =
    set_ .findPath (\value item -> { item | findPath = value })


mapFindPath : (v -> v) -> { item | findPath : v } -> { item | findPath : v }
mapFindPath =
    map_ .findPath setFindPath


mapFindPathM : (v -> v) -> { item | findPath : Maybe v } -> { item | findPath : Maybe v }
mapFindPathM =
    mapM_ .findPath setFindPath


setFrom : v -> { item | from : v } -> { item | from : v }
setFrom =
    set_ .from (\value item -> { item | from = value })


setGroups : v -> { item | groups : v } -> { item | groups : v }
setGroups =
    set_ .groups (\value item -> { item | groups = value })


mapGroups : (v -> v) -> { item | groups : v } -> { item | groups : v }
mapGroups =
    map_ .groups setGroups


setHidden : v -> { item | hidden : v } -> { item | hidden : v }
setHidden =
    set_ .hidden (\value item -> { item | hidden = value })


mapHidden : (v -> v) -> { item | hidden : v } -> { item | hidden : v }
mapHidden =
    map_ .hidden setHidden


setHiddenColumns : v -> { item | hiddenColumns : v } -> { item | hiddenColumns : v }
setHiddenColumns =
    set_ .hiddenColumns (\value item -> { item | hiddenColumns = value })


mapHiddenColumns : (v -> v) -> { item | hiddenColumns : v } -> { item | hiddenColumns : v }
mapHiddenColumns =
    map_ .hiddenColumns setHiddenColumns


setHighlight : v -> { item | highlight : v } -> { item | highlight : v }
setHighlight =
    set_ .highlight (\value item -> { item | highlight = value })


setHighlighted : v -> { item | highlighted : v } -> { item | highlighted : v }
setHighlighted =
    set_ .highlighted (\value item -> { item | highlighted = value })


setHoverColumn : v -> { item | hoverColumn : v } -> { item | hoverColumn : v }
setHoverColumn =
    set_ .hoverColumn (\value item -> { item | hoverColumn = value })


setHoverTableRow : v -> { item | hoverTableRow : v } -> { item | hoverTableRow : v }
setHoverTableRow =
    set_ .hoverTableRow (\value item -> { item | hoverTableRow = value })


setHoverTable : v -> { item | hoverTable : v } -> { item | hoverTable : v }
setHoverTable =
    set_ .hoverTable (\value item -> { item | hoverTable = value })


mapHoverTable : (v -> v) -> { item | hoverTable : v } -> { item | hoverTable : v }
mapHoverTable =
    map_ .hoverTable setHoverTable


setId : v -> { item | id : v } -> { item | id : v }
setId =
    set_ .id (\value item -> { item | id = value })


setIgnoredColumns : v -> { item | ignoredColumns : v } -> { item | ignoredColumns : v }
setIgnoredColumns =
    set_ .ignoredColumns (\value item -> { item | ignoredColumns = value })


setIgnoredTables : v -> { item | ignoredTables : v } -> { item | ignoredTables : v }
setIgnoredTables =
    set_ .ignoredTables (\value item -> { item | ignoredTables = value })


setIndex : v -> { item | index : v } -> { item | index : v }
setIndex =
    set_ .index (\value item -> { item | index = value })


mapIndex : (v -> v) -> { item | index : v } -> { item | index : v }
mapIndex =
    map_ .index setIndex


setInput : v -> { item | input : v } -> { item | input : v }
setInput =
    set_ .input (\value item -> { item | input = value })


setIsOpen : v -> { item | isOpen : v } -> { item | isOpen : v }
setIsOpen =
    set_ .isOpen (\value item -> { item | isOpen = value })


setJsonSource : v -> { item | jsonSource : v } -> { item | jsonSource : v }
setJsonSource =
    set_ .jsonSource (\value item -> { item | jsonSource = value })


mapJsonSourceCmd : (v -> ( v, Cmd msg )) -> { item | jsonSource : v } -> ( { item | jsonSource : v }, Cmd msg )
mapJsonSourceCmd =
    mapT_ .jsonSource setJsonSource


mapJsonSourceMCmd : (v -> ( v, Cmd msg )) -> { item | jsonSource : Maybe v } -> ( { item | jsonSource : Maybe v }, Cmd msg )
mapJsonSourceMCmd transform item =
    mapMT_ .jsonSource setJsonSource transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setLast : v -> { item | last : v } -> { item | last : v }
setLast =
    set_ .last (\value item -> { item | last = value })


setLayoutOnLoad : v -> { item | layoutOnLoad : v } -> { item | layoutOnLoad : v }
setLayoutOnLoad =
    set_ .layoutOnLoad (\value item -> { item | layoutOnLoad = value })


setLayouts : v -> { item | layouts : v } -> { item | layouts : v }
setLayouts =
    set_ .layouts (\value item -> { item | layouts = value })


mapLayouts : (v -> v) -> { item | layouts : v } -> { item | layouts : v }
mapLayouts =
    map_ .layouts setLayouts


mapLayoutsD : comparable -> (v -> v) -> { item | layouts : Dict comparable v } -> { item | layouts : Dict comparable v }
mapLayoutsD =
    mapD_ .layouts setLayouts


mapLayoutsDTM : comparable -> (v -> ( v, Maybe a )) -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, Maybe a )
mapLayoutsDTM =
    mapDTM_ .layouts setLayouts


mapLayoutsDCmd : comparable -> (v -> ( v, Cmd msg )) -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, Cmd msg )
mapLayoutsDCmd key transform item =
    mapDT_ .layouts setLayouts key transform item |> Tuple.mapSecond (\a -> a |> Maybe.withDefault Cmd.none)


setList : v -> { item | list : v } -> { item | list : v }
setList =
    set_ .list (\value item -> { item | list = value })


setMax : v -> { item | max : v } -> { item | max : v }
setMax =
    set_ .max (\value item -> { item | max = value })


setMemos : v -> { item | memos : v } -> { item | memos : v }
setMemos =
    set_ .memos (\value item -> { item | memos = value })


mapMemos : (v -> v) -> { item | memos : v } -> { item | memos : v }
mapMemos =
    map_ .memos setMemos


mapMemosL : (v -> k) -> k -> (v -> v) -> { item | memos : List v } -> { item | memos : List v }
mapMemosL =
    mapL_ .memos setMemos


setMetadata : v -> { item | metadata : v } -> { item | metadata : v }
setMetadata =
    set_ .metadata (\value item -> { item | metadata = value })


mapMetadata : (v -> v) -> { item | metadata : v } -> { item | metadata : v }
mapMetadata =
    map_ .metadata setMetadata


setMobileMenuOpen : v -> { item | mobileMenuOpen : v } -> { item | mobileMenuOpen : v }
setMobileMenuOpen =
    set_ .mobileMenuOpen (\value item -> { item | mobileMenuOpen = value })


mapMobileMenuOpen : (v -> v) -> { item | mobileMenuOpen : v } -> { item | mobileMenuOpen : v }
mapMobileMenuOpen =
    map_ .mobileMenuOpen setMobileMenuOpen


setModal : v -> { item | modal : v } -> { item | modal : v }
setModal =
    set_ .modal (\value item -> { item | modal = value })


setMouse : v -> { item | mouse : v } -> { item | mouse : v }
setMouse =
    set_ .mouse (\value item -> { item | mouse = value })


setName : v -> { item | name : v } -> { item | name : v }
setName =
    set_ .name (\value item -> { item | name = value })


setNavbar : v -> { item | navbar : v } -> { item | navbar : v }
setNavbar =
    set_ .navbar (\value item -> { item | navbar = value })


mapNavbar : (v -> v) -> { item | navbar : v } -> { item | navbar : v }
mapNavbar =
    map_ .navbar setNavbar


setNewLayout : v -> { item | newLayout : v } -> { item | newLayout : v }
setNewLayout =
    set_ .newLayout (\value item -> { item | newLayout = value })


mapNewLayoutMCmd : (v -> ( v, Cmd msg )) -> { item | newLayout : Maybe v } -> ( { item | newLayout : Maybe v }, Cmd msg )
mapNewLayoutMCmd transform item =
    mapMT_ .newLayout setNewLayout transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setNotes : v -> { item | notes : v } -> { item | notes : v }
setNotes =
    set_ .notes (\value item -> { item | notes = value })


setOpened : v -> { item | opened : v } -> { item | opened : v }
setOpened =
    set_ .opened (\value item -> { item | opened = value })


mapOpened : (v -> v) -> { item | opened : v } -> { item | opened : v }
mapOpened =
    map_ .opened setOpened


setOpenedDropdown : v -> { item | openedDropdown : v } -> { item | openedDropdown : v }
setOpenedDropdown =
    set_ .openedDropdown (\value item -> { item | openedDropdown = value })


mapOpenedDropdown : (v -> v) -> { item | openedDropdown : v } -> { item | openedDropdown : v }
mapOpenedDropdown =
    map_ .openedDropdown setOpenedDropdown


setOpenedPopover : v -> { item | openedPopover : v } -> { item | openedPopover : v }
setOpenedPopover =
    set_ .openedPopover (\value item -> { item | openedPopover = value })


setOpenedDialogs : v -> { item | openedDialogs : v } -> { item | openedDialogs : v }
setOpenedDialogs =
    set_ .openedDialogs (\value item -> { item | openedDialogs = value })


mapOpenedDialogs : (v -> v) -> { item | openedDialogs : v } -> { item | openedDialogs : v }
mapOpenedDialogs =
    map_ .openedDialogs setOpenedDialogs


setOperation : v -> { item | operation : v } -> { item | operation : v }
setOperation =
    set_ .operation (\value item -> { item | operation = value })


setOperator : v -> { item | operator : v } -> { item | operator : v }
setOperator =
    set_ .operator (\value item -> { item | operator = value })


setOrganization : v -> { item | organization : v } -> { item | organization : v }
setOrganization =
    set_ .organization (\value item -> { item | organization = value })


mapOrganization : (v -> v) -> { item | organization : v } -> { item | organization : v }
mapOrganization =
    map_ .organization setOrganization


mapOrganizationM : (v -> v) -> { item | organization : Maybe v } -> { item | organization : Maybe v }
mapOrganizationM =
    mapM_ .organization setOrganization


setParsedSchema : v -> { item | parsedSchema : v } -> { item | parsedSchema : v }
setParsedSchema =
    set_ .parsedSchema (\value item -> { item | parsedSchema = value })


mapParsedSchemaM : (v -> v) -> { item | parsedSchema : Maybe v } -> { item | parsedSchema : Maybe v }
mapParsedSchemaM =
    mapM_ .parsedSchema setParsedSchema


setParsedSource : v -> { item | parsedSource : v } -> { item | parsedSource : v }
setParsedSource =
    set_ .parsedSource (\value item -> { item | parsedSource = value })


setPlan : v -> { item | plan : v } -> { item | plan : v }
setPlan =
    set_ .plan (\value item -> { item | plan = value })


mapPlan : (v -> v) -> { item | plan : v } -> { item | plan : v }
mapPlan =
    map_ .plan setPlan


setPosition : v -> { item | position : v } -> { item | position : v }
setPosition =
    set_ .position (\value item -> { item | position = value })


mapPosition : (v -> v) -> { item | position : v } -> { item | position : v }
mapPosition =
    map_ .position setPosition


setPrevious : v -> { item | previous : v } -> { item | previous : v }
setPrevious =
    set_ .previous (\value item -> { item | previous = value })


setPrismaSource : v -> { item | prismaSource : v } -> { item | prismaSource : v }
setPrismaSource =
    set_ .prismaSource (\value item -> { item | prismaSource = value })


mapPrismaSourceCmd : (v -> ( v, Cmd msg )) -> { item | prismaSource : v } -> ( { item | prismaSource : v }, Cmd msg )
mapPrismaSourceCmd =
    mapT_ .prismaSource setPrismaSource


mapPrismaSourceMCmd : (v -> ( v, Cmd msg )) -> { item | prismaSource : Maybe v } -> ( { item | prismaSource : Maybe v }, Cmd msg )
mapPrismaSourceMCmd transform item =
    mapMT_ .prismaSource setPrismaSource transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setProject : v -> { item | project : v } -> { item | project : v }
setProject =
    set_ .project (\value item -> { item | project = value })


mapProject : (v -> v) -> { item | project : v } -> { item | project : v }
mapProject =
    map_ .project setProject


setProjectSource : v -> { item | projectSource : v } -> { item | projectSource : v }
setProjectSource =
    set_ .projectSource (\value item -> { item | projectSource = value })


mapProjectSourceMCmd : (v -> ( v, Cmd msg )) -> { item | projectSource : Maybe v } -> ( { item | projectSource : Maybe v }, Cmd msg )
mapProjectSourceMCmd transform item =
    mapMT_ .projectSource setProjectSource transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setPrompt : v -> { item | prompt : v } -> { item | prompt : v }
setPrompt =
    set_ .prompt (\value item -> { item | prompt = value })


mapPromptM : (v -> v) -> { item | prompt : Maybe v } -> { item | prompt : Maybe v }
mapPromptM =
    mapM_ .prompt setPrompt


setProps : v -> { item | props : v } -> { item | props : v }
setProps =
    set_ .props (\value item -> { item | props = value })


mapProps : (v -> v) -> { item | props : v } -> { item | props : v }
mapProps =
    map_ .props setProps


setQuery : v -> { item | query : v } -> { item | query : v }
setQuery =
    set_ .query (\value item -> { item | query = value })


setRelatedTables : v -> { item | relatedTables : v } -> { item | relatedTables : v }
setRelatedTables =
    set_ .relatedTables (\value item -> { item | relatedTables = value })


mapRelatedTables : (v -> v) -> { item | relatedTables : v } -> { item | relatedTables : v }
mapRelatedTables =
    map_ .relatedTables setRelatedTables


setRelations : v -> { item | relations : v } -> { item | relations : v }
setRelations =
    set_ .relations (\value item -> { item | relations = value })


mapRelations : (v -> v) -> { item | relations : v } -> { item | relations : v }
mapRelations =
    map_ .relations setRelations


setRelationStyle : v -> { item | relationStyle : v } -> { item | relationStyle : v }
setRelationStyle =
    set_ .relationStyle (\value item -> { item | relationStyle = value })


setRemovedTables : v -> { item | removedTables : v } -> { item | removedTables : v }
setRemovedTables =
    set_ .removedTables (\value item -> { item | removedTables = value })


setRemovedSchemas : v -> { item | removedSchemas : v } -> { item | removedSchemas : v }
setRemovedSchemas =
    set_ .removedSchemas (\value item -> { item | removedSchemas = value })


mapRemovedSchemas : (v -> v) -> { item | removedSchemas : v } -> { item | removedSchemas : v }
mapRemovedSchemas =
    map_ .removedSchemas setRemovedSchemas


setRemoveViews : v -> { item | removeViews : v } -> { item | removeViews : v }
setRemoveViews =
    set_ .removeViews (\value item -> { item | removeViews = value })


mapRemoveViews : (v -> v) -> { item | removeViews : v } -> { item | removeViews : v }
mapRemoveViews =
    map_ .removeViews setRemoveViews


setResult : v -> { item | result : v } -> { item | result : v }
setResult =
    set_ .result (\value item -> { item | result = value })


mapResult : (v -> v) -> { item | result : v } -> { item | result : v }
mapResult =
    map_ .result setResult


setResults : v -> { item | results : v } -> { item | results : v }
setResults =
    set_ .results (\value item -> { item | results = value })


mapResultsCmd : (v -> ( v, Cmd msg )) -> { item | results : v } -> ( { item | results : v }, Cmd msg )
mapResultsCmd =
    mapT_ .results setResults


setSampleSource : v -> { item | sampleSource : v } -> { item | sampleSource : v }
setSampleSource =
    set_ .sampleSource (\value item -> { item | sampleSource = value })


mapSampleSourceMCmd : (v -> ( v, Cmd msg )) -> { item | sampleSource : Maybe v } -> ( { item | sampleSource : Maybe v }, Cmd msg )
mapSampleSourceMCmd transform item =
    mapMT_ .sampleSource setSampleSource transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setSave : v -> { item | save : v } -> { item | save : v }
setSave =
    set_ .save (\value item -> { item | save = value })


mapSaveCmd : (v -> ( v, Cmd msg )) -> { item | save : v } -> ( { item | save : v }, Cmd msg )
mapSaveCmd =
    mapT_ .save setSave


setSchemaAnalysis : v -> { item | schemaAnalysis : v } -> { item | schemaAnalysis : v }
setSchemaAnalysis =
    set_ .schemaAnalysis (\value item -> { item | schemaAnalysis = value })


mapSchemaAnalysisM : (v -> v) -> { item | schemaAnalysis : Maybe v } -> { item | schemaAnalysis : Maybe v }
mapSchemaAnalysisM =
    mapM_ .schemaAnalysis setSchemaAnalysis


setScroll : v -> { item | scroll : v } -> { item | scroll : v }
setScroll =
    set_ .scroll (\value item -> { item | scroll = value })


setSearch : v -> { item | search : v } -> { item | search : v }
setSearch =
    set_ .search (\value item -> { item | search = value })


mapSearch : (v -> v) -> { item | search : v } -> { item | search : v }
mapSearch =
    map_ .search setSearch


setSettings : v -> { item | settings : v } -> { item | settings : v }
setSettings =
    set_ .settings (\value item -> { item | settings = value })


mapSettings : (v -> v) -> { item | settings : v } -> { item | settings : v }
mapSettings =
    map_ .settings setSettings


mapSettingsM : (v -> v) -> { item | settings : Maybe v } -> { item | settings : Maybe v }
mapSettingsM =
    mapM_ .settings setSettings


setSelected : v -> { item | selected : v } -> { item | selected : v }
setSelected =
    set_ .selected (\value item -> { item | selected = value })


mapSelected : (v -> v) -> { item | selected : v } -> { item | selected : v }
mapSelected =
    map_ .selected setSelected


setSelectionBox : v -> { item | selectionBox : v } -> { item | selectionBox : v }
setSelectionBox =
    set_ .selectionBox (\value item -> { item | selectionBox = value })


setSharing : v -> { item | sharing : v } -> { item | sharing : v }
setSharing =
    set_ .sharing (\value item -> { item | sharing = value })


mapSharingCmd : (v -> ( v, Cmd msg )) -> { item | sharing : v } -> ( { item | sharing : v }, Cmd msg )
mapSharingCmd =
    mapT_ .sharing setSharing


setShow : v -> { item | show : v } -> { item | show : v }
setShow =
    set_ .show (\value item -> { item | show = value })


mapShow : (v -> v) -> { item | show : v } -> { item | show : v }
mapShow =
    map_ .show setShow


setShown : v -> { item | shown : v } -> { item | shown : v }
setShown =
    set_ .shown (\value item -> { item | shown = value })


setShowHiddenColumns : v -> { item | showHiddenColumns : v } -> { item | showHiddenColumns : v }
setShowHiddenColumns =
    set_ .showHiddenColumns (\value item -> { item | showHiddenColumns = value })


mapShowHiddenColumns : (v -> v) -> { item | showHiddenColumns : v } -> { item | showHiddenColumns : v }
mapShowHiddenColumns =
    map_ .showHiddenColumns setShowHiddenColumns


setShowSettings : v -> { item | showSettings : v } -> { item | showSettings : v }
setShowSettings =
    set_ .showSettings (\value item -> { item | showSettings = value })


mapShowSettings : (v -> v) -> { item | showSettings : v } -> { item | showSettings : v }
mapShowSettings =
    map_ .showSettings setShowSettings


setSize : v -> { item | size : v } -> { item | size : v }
setSize =
    set_ .size (\value item -> { item | size = value })


setSourceUpdate : v -> { item | sourceUpdate : v } -> { item | sourceUpdate : v }
setSourceUpdate =
    set_ .sourceUpdate (\value item -> { item | sourceUpdate = value })


mapSourceUpdateCmd : (v -> ( v, Cmd msg )) -> { item | sourceUpdate : v } -> ( { item | sourceUpdate : v }, Cmd msg )
mapSourceUpdateCmd =
    mapT_ .sourceUpdate setSourceUpdate


setSqlSource : v -> { item | sqlSource : v } -> { item | sqlSource : v }
setSqlSource =
    set_ .sqlSource (\value item -> { item | sqlSource = value })


mapSqlSourceCmd : (v -> ( v, Cmd msg )) -> { item | sqlSource : v } -> ( { item | sqlSource : v }, Cmd msg )
mapSqlSourceCmd =
    mapT_ .sqlSource setSqlSource


mapSqlSourceMCmd : (v -> ( v, Cmd msg )) -> { item | sqlSource : Maybe v } -> ( { item | sqlSource : Maybe v }, Cmd msg )
mapSqlSourceMCmd transform item =
    mapMT_ .sqlSource setSqlSource transform item |> Tuple.mapSecond (Maybe.withDefault Cmd.none)


setState : v -> { item | state : v } -> { item | state : v }
setState =
    set_ .state (\value item -> { item | state = value })


mapState : (v -> v) -> { item | state : v } -> { item | state : v }
mapState =
    map_ .state setState


setTables : v -> { item | tables : v } -> { item | tables : v }
setTables =
    set_ .tables (\value item -> { item | tables = value })


mapTables : (v -> v) -> { item | tables : v } -> { item | tables : v }
mapTables =
    map_ .tables setTables


mapTablesL : (v -> k) -> k -> (v -> v) -> { item | tables : List v } -> { item | tables : List v }
mapTablesL =
    mapL_ .tables setTables


mapTablesCmd : (v -> ( v, Cmd msg )) -> { item | tables : v } -> ( { item | tables : v }, Cmd msg )
mapTablesCmd =
    mapT_ .tables setTables


setTableRows : v -> { item | tableRows : v } -> { item | tableRows : v }
setTableRows =
    set_ .tableRows (\value item -> { item | tableRows = value })


mapTableRows : (v -> v) -> { item | tableRows : v } -> { item | tableRows : v }
mapTableRows =
    map_ .tableRows setTableRows


mapTableRowsCmd : (v -> ( v, Cmd msg )) -> { item | tableRows : v } -> ( { item | tableRows : v }, Cmd msg )
mapTableRowsCmd =
    mapT_ .tableRows setTableRows


setTableRowsSeq : v -> { item | tableRowsSeq : v } -> { item | tableRowsSeq : v }
setTableRowsSeq =
    set_ .tableRowsSeq (\value item -> { item | tableRowsSeq = value })


mapTableRowsSeq : (v -> v) -> { item | tableRowsSeq : v } -> { item | tableRowsSeq : v }
mapTableRowsSeq =
    map_ .tableRowsSeq setTableRowsSeq


setTags : v -> { item | tags : v } -> { item | tags : v }
setTags =
    set_ .tags (\value item -> { item | tags = value })


setText : v -> { item | text : v } -> { item | text : v }
setText =
    set_ .text (\value item -> { item | text = value })


setTo : v -> { item | to : v } -> { item | to : v }
setTo =
    set_ .to (\value item -> { item | to = value })


setToasts : v -> { item | toasts : v } -> { item | toasts : v }
setToasts =
    set_ .toasts (\value item -> { item | toasts = value })


mapToasts : (v -> v) -> { item | toasts : v } -> { item | toasts : v }
mapToasts =
    map_ .toasts setToasts


mapToastsCmd : (v -> ( v, Cmd msg )) -> { item | toasts : v } -> ( { item | toasts : v }, Cmd msg )
mapToastsCmd =
    mapT_ .toasts setToasts


setToken : v -> { item | token : v } -> { item | token : v }
setToken =
    set_ .token (\value item -> { item | token = value })


setTokens : v -> { item | tokens : v } -> { item | tokens : v }
setTokens =
    set_ .tokens (\value item -> { item | tokens = value })


setTokenForm : v -> { item | tokenForm : v } -> { item | tokenForm : v }
setTokenForm =
    set_ .tokenForm (\value item -> { item | tokenForm = value })


mapTokenFormM : (v -> v) -> { item | tokenForm : Maybe v } -> { item | tokenForm : Maybe v }
mapTokenFormM =
    mapM_ .tokenForm setTokenForm


setUpdatedAt : v -> { item | updatedAt : v } -> { item | updatedAt : v }
setUpdatedAt =
    set_ .updatedAt (\value item -> { item | updatedAt = value })


setValue : v -> { item | value : v } -> { item | value : v }
setValue =
    set_ .value (\value item -> { item | value = value })


setView : v -> { item | view : v } -> { item | view : v }
setView =
    set_ .view (\view item -> { item | view = view })


setVirtualRelation : v -> { item | virtualRelation : v } -> { item | virtualRelation : v }
setVirtualRelation =
    set_ .virtualRelation (\value item -> { item | virtualRelation = value })


mapVirtualRelationM : (v -> v) -> { item | virtualRelation : Maybe v } -> { item | virtualRelation : Maybe v }
mapVirtualRelationM =
    mapM_ .virtualRelation setVirtualRelation


setVisualEditor : v -> { item | visualEditor : v } -> { item | visualEditor : v }
setVisualEditor =
    set_ .visualEditor (\value item -> { item | visualEditor = value })


mapVisualEditor : (v -> v) -> { item | visualEditor : v } -> { item | visualEditor : v }
mapVisualEditor =
    map_ .visualEditor setVisualEditor


setZoom : v -> { item | zoom : v } -> { item | zoom : v }
setZoom =
    set_ .zoom (\value item -> { item | zoom = value })



-- specific methods


mapM : (v -> v) -> Maybe v -> Maybe v
mapM transform item =
    -- map Maybe
    item |> Maybe.map transform


mapMCmd : (v -> ( v, Cmd msg )) -> Maybe v -> ( Maybe v, Cmd msg )
mapMCmd transform item =
    -- map Maybe with Command
    item |> Maybe.mapOrElse (transform >> Tuple.mapFirst Just) ( Nothing, Cmd.none )


mapList : (item -> k) -> k -> (item -> item) -> List item -> List item
mapList get key transform list =
    -- map list given a condition
    list
        |> List.map
            (\item ->
                if get item == key then
                    transform item

                else
                    item
            )



-- HELPERS


set_ : (item -> v) -> (v -> item -> item) -> v -> item -> item
set_ get update value item =
    -- set a value in a record if different
    if get item == value then
        item

    else
        update value item


map_ : (item -> v) -> (v -> item -> item) -> (v -> v) -> item -> item
map_ get update transform item =
    -- update a value in a record
    update (item |> get |> transform) item


mapT_ : (item -> v) -> (v -> item -> item) -> (v -> ( v, a )) -> item -> ( item, a )
mapT_ get update transform item =
    -- update a value in a record keeping tuple
    item |> get |> transform |> Tuple.mapFirst (\value -> update value item)


mapM_ : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> v) -> item -> item
mapM_ get update transform item =
    -- update an optional value in a record if present
    update (item |> get |> Maybe.map transform) item


mapMT_ : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> ( v, a )) -> item -> ( item, Maybe a )
mapMT_ get update transform item =
    -- update optional value in a record keeping tuple
    item |> get |> Maybe.mapOrElse (transform >> Tuple.mapBoth (\value -> item |> update (Just value)) Just) ( item, Nothing )


mapMTM_ : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> ( v, Maybe a )) -> item -> ( item, Maybe a )
mapMTM_ get update transform item =
    -- update optional value in a record keeping tuple
    item |> get |> Maybe.mapOrElse (transform >> Tuple.mapFirst (\value -> item |> update (Just value))) ( item, Nothing )


mapD_ : (item -> Dict comparable v) -> (Dict comparable v -> item -> item) -> comparable -> (v -> v) -> item -> item
mapD_ get update key transform item =
    -- update dict values in a record if match condition
    update (item |> get |> Dict.update key (Maybe.map transform)) item


mapDT_ : (item -> Dict comparable v) -> (Dict comparable v -> item -> item) -> comparable -> (v -> ( v, a )) -> item -> ( item, Maybe a )
mapDT_ get update key transform item =
    item |> get |> Dict.get key |> Maybe.mapOrElse (transform >> Tuple.mapBoth (\n -> mapD_ get update key (\_ -> n) item) Just) ( item, Nothing )


mapDTM_ : (item -> Dict comparable v) -> (Dict comparable v -> item -> item) -> comparable -> (v -> ( v, Maybe a )) -> item -> ( item, Maybe a )
mapDTM_ get update key transform item =
    item |> get |> Dict.get key |> Maybe.mapOrElse (transform >> Tuple.mapFirst (\n -> mapD_ get update key (\_ -> n) item)) ( item, Nothing )


mapL_ : (item -> List v) -> (List v -> item -> item) -> (v -> k) -> k -> (v -> v) -> item -> item
mapL_ get update getKey key transform item =
    -- update list values in a record if match condition
    update
        (item
            |> get
            |> List.map
                (\v ->
                    if getKey v == key then
                        transform v

                    else
                        v
                )
        )
        item



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
