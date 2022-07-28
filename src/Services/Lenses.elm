module Services.Lenses exposing
    ( mapActive
    , mapAmlSidebarM
    , mapCanvas
    , mapChecks
    , mapCollapseTableColumns
    , mapColumnBasicTypes
    , mapColumnProps
    , mapColumns
    , mapColumnsD
    , mapComment
    , mapCommentM
    , mapConf
    , mapContent
    , mapContextMenuM
    , mapDatabaseSource
    , mapDatabaseSourceCmd
    , mapDatabaseSourceM
    , mapDatabaseSourceMCmd
    , mapDefaultSchema
    , mapDetailsSidebar
    , mapDetailsSidebarCmd
    , mapEachProjectMLayoutTables
    , mapEachTable
    , mapEditNotesM
    , mapEmbedSourceParsingMCmd
    , mapEnabled
    , mapErdM
    , mapErdMCmd
    , mapFindPath
    , mapFindPathM
    , mapHiddenColumns
    , mapHiddenTables
    , mapHighlighted
    , mapHover
    , mapHoverColumn
    , mapHoverTable
    , mapImportProjectCmd
    , mapImportProjectM
    , mapImportProjectMCmd
    , mapIndex
    , mapIndexes
    , mapJsonSourceCmd
    , mapJsonSourceM
    , mapJsonSourceMCmd
    , mapLayout
    , mapLayouts
    , mapLayoutsD
    , mapLayoutsDCmd
    , mapList
    , mapM
    , mapMCmd
    , mapMTeamCmd
    , mapMobileMenuOpen
    , mapNavbar
    , mapNewLayoutM
    , mapNotes
    , mapOpened
    , mapOpenedDialogs
    , mapOpenedDropdown
    , mapOpenedPopover
    , mapParsedSchema
    , mapParsedSchemaM
    , mapParsing
    , mapParsingCmd
    , mapPosition
    , mapPrimaryKey
    , mapPrimaryKeyM
    , mapProject
    , mapProjectM
    , mapProjectMCmd
    , mapProjectMLayout
    , mapProjectMLayoutTable
    , mapProjectMLayoutTables
    , mapPrompt
    , mapPromptM
    , mapProps
    , mapRelatedTables
    , mapRelations
    , mapRemoveViews
    , mapRemovedSchemas
    , mapResult
    , mapSampleProjectM
    , mapSampleProjectMCmd
    , mapSchemaAnalysisM
    , mapScreen
    , mapSearch
    , mapSelected
    , mapSelectionBox
    , mapSettings
    , mapSharing
    , mapSharingM
    , mapShow
    , mapShowHiddenColumns
    , mapShowSettings
    , mapShown
    , mapShownColumns
    , mapShownTables
    , mapSourceUpdateCmd
    , mapSources
    , mapSourcesL
    , mapSqlSourceCmd
    , mapSqlSourceM
    , mapSqlSourceMCmd
    , mapSwitch
    , mapTableInList
    , mapTableProps
    , mapTablePropsCmd
    , mapTables
    , mapTablesCmd
    , mapTablesL
    , mapTeamCmd
    , mapTime
    , mapToasts
    , mapToastsCmd
    , mapTop
    , mapUniques
    , mapUpload
    , mapUploadCmd
    , mapUploadM
    , mapUsedLayout
    , mapUser
    , mapUserM
    , mapUsername
    , mapVirtualRelationM
    , setActive
    , setAmlSidebar
    , setBio
    , setCanvas
    , setChecks
    , setCollapseTableColumns
    , setCollapsed
    , setColor
    , setColumn
    , setColumnBasicTypes
    , setColumnOrder
    , setColumnProps
    , setColumns
    , setComment
    , setCompany
    , setConf
    , setConfirm
    , setContent
    , setContextMenu
    , setCurrentLayout
    , setCursorMode
    , setDatabaseSource
    , setDefaultSchema
    , setDetailsSidebar
    , setDragState
    , setDragging
    , setEditNotes
    , setEmbedSourceParsing
    , setEnabled
    , setErd
    , setErrors
    , setFindPath
    , setFrom
    , setGithub
    , setHiddenColumns
    , setHiddenTables
    , setHighlight
    , setHighlighted
    , setHover
    , setHoverColumn
    , setHoverTable
    , setId
    , setIgnoredColumns
    , setIgnoredTables
    , setImportProject
    , setIndex
    , setIndexes
    , setInput
    , setIsOpen
    , setJsonSource
    , setLast
    , setLayout
    , setLayouts
    , setList
    , setLoading
    , setLocation
    , setMax
    , setMobileMenuOpen
    , setMouse
    , setName
    , setNavbar
    , setNewLayout
    , setNotes
    , setNow
    , setOpened
    , setOpenedDialogs
    , setOpenedDropdown
    , setOpenedPopover
    , setOrigins
    , setParsedSchema
    , setParsedSource
    , setParsing
    , setPopover
    , setPosition
    , setPrimaryKey
    , setProject
    , setProjectName
    , setPrompt
    , setProps
    , setRelatedTables
    , setRelationStyle
    , setRelations
    , setRemoveViews
    , setRemovedSchemas
    , setRemovedTables
    , setResult
    , setSampleProject
    , setSchemaAnalysis
    , setScreen
    , setSearch
    , setSelected
    , setSelection
    , setSelectionBox
    , setSettings
    , setSharing
    , setShow
    , setShowHiddenColumns
    , setShowSettings
    , setShown
    , setShownColumns
    , setShownTables
    , setSize
    , setSourceUpdate
    , setSources
    , setSqlSource
    , setStatus
    , setSwitch
    , setTable
    , setTableProps
    , setTables
    , setTeam
    , setText
    , setTime
    , setTo
    , setToastIdx
    , setToasts
    , setTop
    , setTwitter
    , setUniques
    , setUpdatedAt
    , setUpload
    , setUrl
    , setUsedLayout
    , setUser
    , setUsername
    , setValue
    , setVirtualRelation
    , setWebsite
    , setZone
    , setZoom
    , updatePosition
    )

import Dict exposing (Dict)
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


setBio : v -> { item | bio : v } -> { item | bio : v }
setBio =
    set_ .bio (\value item -> { item | bio = value })


setCanvas : v -> { item | canvas : v } -> { item | canvas : v }
setCanvas =
    set_ .canvas (\value item -> { item | canvas = value })


mapCanvas : (v -> v) -> { item | canvas : v } -> { item | canvas : v }
mapCanvas =
    map_ .canvas setCanvas


setChecks : v -> { item | checks : v } -> { item | checks : v }
setChecks =
    set_ .checks (\value item -> { item | checks = value })


mapChecks : (v -> v) -> { item | checks : v } -> { item | checks : v }
mapChecks =
    map_ .checks setChecks


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


setColumn : v -> { item | column : v } -> { item | column : v }
setColumn =
    set_ .column (\value item -> { item | column = value })


setColumns : v -> { item | columns : v } -> { item | columns : v }
setColumns =
    set_ .columns (\value item -> { item | columns = value })


mapColumns : (v -> v) -> { item | columns : v } -> { item | columns : v }
mapColumns =
    map_ .columns setColumns


mapColumnsD : comparable -> (v -> v) -> { item | columns : Dict comparable v } -> { item | columns : Dict comparable v }
mapColumnsD =
    mapD_ .columns setColumns


setColumnBasicTypes : v -> { item | columnBasicTypes : v } -> { item | columnBasicTypes : v }
setColumnBasicTypes =
    set_ .columnBasicTypes (\value item -> { item | columnBasicTypes = value })


mapColumnBasicTypes : (v -> v) -> { item | columnBasicTypes : v } -> { item | columnBasicTypes : v }
mapColumnBasicTypes =
    map_ .columnBasicTypes setColumnBasicTypes


setColumnOrder : v -> { item | columnOrder : v } -> { item | columnOrder : v }
setColumnOrder =
    set_ .columnOrder (\value item -> { item | columnOrder = value })


setColumnProps : v -> { item | columnProps : v } -> { item | columnProps : v }
setColumnProps =
    set_ .columnProps (\value item -> { item | columnProps = value })


mapColumnProps : (v -> v) -> { item | columnProps : v } -> { item | columnProps : v }
mapColumnProps =
    map_ .columnProps setColumnProps


setComment : v -> { item | comment : v } -> { item | comment : v }
setComment =
    set_ .comment (\value item -> { item | comment = value })


mapComment : (v -> v) -> { item | comment : v } -> { item | comment : v }
mapComment =
    map_ .comment setComment


mapCommentM : (v -> v) -> { item | comment : Maybe v } -> { item | comment : Maybe v }
mapCommentM =
    mapM_ .comment setComment


setCompany : v -> { item | company : v } -> { item | company : v }
setCompany =
    set_ .company (\value item -> { item | company = value })


setConf : v -> { item | conf : v } -> { item | conf : v }
setConf =
    set_ .conf (\value item -> { item | conf = value })


mapConf : (v -> v) -> { item | conf : v } -> { item | conf : v }
mapConf =
    map_ .conf setConf


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


mapDatabaseSource : (v -> v) -> { item | databaseSource : v } -> { item | databaseSource : v }
mapDatabaseSource =
    map_ .databaseSource setDatabaseSource


mapDatabaseSourceM : (v -> v) -> { item | databaseSource : Maybe v } -> { item | databaseSource : Maybe v }
mapDatabaseSourceM =
    mapM_ .databaseSource setDatabaseSource


mapDatabaseSourceCmd : (v -> ( v, Cmd msg )) -> { item | databaseSource : v } -> ( { item | databaseSource : v }, Cmd msg )
mapDatabaseSourceCmd =
    mapCmd_ .databaseSource setDatabaseSource


mapDatabaseSourceMCmd : (v -> ( v, Cmd msg )) -> { item | databaseSource : Maybe v } -> ( { item | databaseSource : Maybe v }, Cmd msg )
mapDatabaseSourceMCmd =
    mapMCmd_ .databaseSource setDatabaseSource


setDragging : v -> { item | dragging : v } -> { item | dragging : v }
setDragging =
    set_ .dragging (\value item -> { item | dragging = value })


setDragState : v -> { item | dragState : v } -> { item | dragState : v }
setDragState =
    set_ .dragState (\value item -> { item | dragState = value })


setDefaultSchema : v -> { item | defaultSchema : v } -> { item | defaultSchema : v }
setDefaultSchema =
    set_ .defaultSchema (\value item -> { item | defaultSchema = value })


mapDefaultSchema : (v -> v) -> { item | defaultSchema : v } -> { item | defaultSchema : v }
mapDefaultSchema =
    map_ .defaultSchema setDefaultSchema


setDetailsSidebar : v -> { item | detailsSidebar : v } -> { item | detailsSidebar : v }
setDetailsSidebar =
    set_ .detailsSidebar (\value item -> { item | detailsSidebar = value })


mapDetailsSidebar : (v -> v) -> { item | detailsSidebar : v } -> { item | detailsSidebar : v }
mapDetailsSidebar =
    map_ .detailsSidebar setDetailsSidebar


mapDetailsSidebarCmd : (v -> ( v, Cmd msg )) -> { item | detailsSidebar : v } -> ( { item | detailsSidebar : v }, Cmd msg )
mapDetailsSidebarCmd =
    mapCmd_ .detailsSidebar setDetailsSidebar


setEditNotes : v -> { item | editNotes : v } -> { item | editNotes : v }
setEditNotes =
    set_ .editNotes (\value item -> { item | editNotes = value })


mapEditNotesM : (v -> v) -> { item | editNotes : Maybe v } -> { item | editNotes : Maybe v }
mapEditNotesM =
    mapM_ .editNotes setEditNotes


setEmbedSourceParsing : v -> { item | embedSourceParsing : v } -> { item | embedSourceParsing : v }
setEmbedSourceParsing =
    set_ .embedSourceParsing (\value item -> { item | embedSourceParsing = value })


mapEmbedSourceParsingMCmd : (v -> ( v, Cmd msg )) -> { item | embedSourceParsing : Maybe v } -> ( { item | embedSourceParsing : Maybe v }, Cmd msg )
mapEmbedSourceParsingMCmd =
    mapMCmd_ .embedSourceParsing setEmbedSourceParsing


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


mapErdMCmd : (v -> ( v, Cmd msg )) -> { item | erd : Maybe v } -> ( { item | erd : Maybe v }, Cmd msg )
mapErdMCmd =
    mapMCmd_ .erd setErd


setErrors : v -> { item | errors : v } -> { item | errors : v }
setErrors =
    set_ .errors (\value item -> { item | errors = value })


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


setGithub : v -> { item | github : v } -> { item | github : v }
setGithub =
    set_ .github (\value item -> { item | github = value })


setHiddenColumns : v -> { item | hiddenColumns : v } -> { item | hiddenColumns : v }
setHiddenColumns =
    set_ .hiddenColumns (\value item -> { item | hiddenColumns = value })


mapHiddenColumns : (v -> v) -> { item | hiddenColumns : v } -> { item | hiddenColumns : v }
mapHiddenColumns =
    map_ .hiddenColumns setHiddenColumns


setHiddenTables : v -> { item | hiddenTables : v } -> { item | hiddenTables : v }
setHiddenTables =
    set_ .hiddenTables (\value item -> { item | hiddenTables = value })


mapHiddenTables : (v -> v) -> { item | hiddenTables : v } -> { item | hiddenTables : v }
mapHiddenTables =
    map_ .hiddenTables setHiddenTables


setHighlight : v -> { item | highlight : v } -> { item | highlight : v }
setHighlight =
    set_ .highlight (\value item -> { item | highlight = value })


setHighlighted : v -> { item | highlighted : v } -> { item | highlighted : v }
setHighlighted =
    set_ .highlighted (\value item -> { item | highlighted = value })


mapHighlighted : (v -> v) -> { item | highlighted : v } -> { item | highlighted : v }
mapHighlighted =
    map_ .highlighted setHighlighted


setHover : v -> { item | hover : v } -> { item | hover : v }
setHover =
    set_ .hover (\value item -> { item | hover = value })


mapHover : (v -> v) -> { item | hover : v } -> { item | hover : v }
mapHover =
    map_ .hover setHover


setHoverColumn : v -> { item | hoverColumn : v } -> { item | hoverColumn : v }
setHoverColumn =
    set_ .hoverColumn (\value item -> { item | hoverColumn = value })


mapHoverColumn : (v -> v) -> { item | hoverColumn : v } -> { item | hoverColumn : v }
mapHoverColumn =
    map_ .hoverColumn setHoverColumn


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


setImportProject : v -> { item | importProject : v } -> { item | importProject : v }
setImportProject =
    set_ .importProject (\value item -> { item | importProject = value })


mapImportProjectM : (v -> v) -> { item | importProject : Maybe v } -> { item | importProject : Maybe v }
mapImportProjectM =
    mapM_ .importProject setImportProject


mapImportProjectCmd : (v -> ( v, Cmd msg )) -> { item | importProject : v } -> ( { item | importProject : v }, Cmd msg )
mapImportProjectCmd =
    mapCmd_ .importProject setImportProject


mapImportProjectMCmd : (v -> ( v, Cmd msg )) -> { item | importProject : Maybe v } -> ( { item | importProject : Maybe v }, Cmd msg )
mapImportProjectMCmd =
    mapMCmd_ .importProject setImportProject


setIndex : v -> { item | index : v } -> { item | index : v }
setIndex =
    set_ .index (\value item -> { item | index = value })


mapIndex : (v -> v) -> { item | index : v } -> { item | index : v }
mapIndex =
    map_ .index setIndex


setIndexes : v -> { item | indexes : v } -> { item | indexes : v }
setIndexes =
    set_ .indexes (\value item -> { item | indexes = value })


mapIndexes : (v -> v) -> { item | indexes : v } -> { item | indexes : v }
mapIndexes =
    map_ .indexes setIndexes


setInput : v -> { item | input : v } -> { item | input : v }
setInput =
    set_ .input (\value item -> { item | input = value })


setIsOpen : v -> { item | isOpen : v } -> { item | isOpen : v }
setIsOpen =
    set_ .isOpen (\value item -> { item | isOpen = value })


setJsonSource : v -> { item | jsonSource : v } -> { item | jsonSource : v }
setJsonSource =
    set_ .jsonSource (\value item -> { item | jsonSource = value })


mapJsonSourceM : (v -> v) -> { item | jsonSource : Maybe v } -> { item | jsonSource : Maybe v }
mapJsonSourceM =
    mapM_ .jsonSource setJsonSource


mapJsonSourceCmd : (v -> ( v, Cmd msg )) -> { item | jsonSource : v } -> ( { item | jsonSource : v }, Cmd msg )
mapJsonSourceCmd =
    mapCmd_ .jsonSource setJsonSource


mapJsonSourceMCmd : (v -> ( v, Cmd msg )) -> { item | jsonSource : Maybe v } -> ( { item | jsonSource : Maybe v }, Cmd msg )
mapJsonSourceMCmd =
    mapMCmd_ .jsonSource setJsonSource


setLast : v -> { item | last : v } -> { item | last : v }
setLast =
    set_ .last (\value item -> { item | last = value })


setLayout : v -> { item | layout : v } -> { item | layout : v }
setLayout =
    set_ .layout (\value item -> { item | layout = value })


mapLayout : (v -> v) -> { item | layout : v } -> { item | layout : v }
mapLayout =
    map_ .layout setLayout


setLayouts : v -> { item | layouts : v } -> { item | layouts : v }
setLayouts =
    set_ .layouts (\value item -> { item | layouts = value })


mapLayouts : (v -> v) -> { item | layouts : v } -> { item | layouts : v }
mapLayouts =
    map_ .layouts setLayouts


mapLayoutsD : comparable -> (v -> v) -> { item | layouts : Dict comparable v } -> { item | layouts : Dict comparable v }
mapLayoutsD =
    mapD_ .layouts setLayouts


mapLayoutsDCmd : comparable -> (v -> ( v, Cmd msg )) -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, Cmd msg )
mapLayoutsDCmd =
    mapDCmd_ .layouts setLayouts


setList : v -> { item | list : v } -> { item | list : v }
setList =
    set_ .list (\value item -> { item | list = value })


setLoading : v -> { item | loading : v } -> { item | loading : v }
setLoading =
    set_ .loading (\value item -> { item | loading = value })


setLocation : v -> { item | location : v } -> { item | location : v }
setLocation =
    set_ .location (\value item -> { item | location = value })


setMax : v -> { item | max : v } -> { item | max : v }
setMax =
    set_ .max (\value item -> { item | max = value })


setMobileMenuOpen : v -> { item | mobileMenuOpen : v } -> { item | mobileMenuOpen : v }
setMobileMenuOpen =
    set_ .mobileMenuOpen (\value item -> { item | mobileMenuOpen = value })


mapMobileMenuOpen : (v -> v) -> { item | mobileMenuOpen : v } -> { item | mobileMenuOpen : v }
mapMobileMenuOpen =
    map_ .mobileMenuOpen setMobileMenuOpen


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


mapNewLayoutM : (v -> v) -> { item | newLayout : Maybe v } -> { item | newLayout : Maybe v }
mapNewLayoutM =
    mapM_ .newLayout setNewLayout


setNotes : v -> { item | notes : v } -> { item | notes : v }
setNotes =
    set_ .notes (\value item -> { item | notes = value })


mapNotes : (v -> v) -> { item | notes : v } -> { item | notes : v }
mapNotes =
    map_ .notes setNotes


setNow : v -> { item | now : v } -> { item | now : v }
setNow =
    set_ .now (\value item -> { item | now = value })


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


mapOpenedPopover : (v -> v) -> { item | openedPopover : v } -> { item | openedPopover : v }
mapOpenedPopover =
    map_ .openedPopover setOpenedPopover


setOpenedDialogs : v -> { item | openedDialogs : v } -> { item | openedDialogs : v }
setOpenedDialogs =
    set_ .openedDialogs (\value item -> { item | openedDialogs = value })


mapOpenedDialogs : (v -> v) -> { item | openedDialogs : v } -> { item | openedDialogs : v }
mapOpenedDialogs =
    map_ .openedDialogs setOpenedDialogs


setOrigins : v -> { item | origins : v } -> { item | origins : v }
setOrigins =
    set_ .origins (\value item -> { item | origins = value })


setParsedSchema : v -> { item | parsedSchema : v } -> { item | parsedSchema : v }
setParsedSchema =
    set_ .parsedSchema (\value item -> { item | parsedSchema = value })


mapParsedSchema : (v -> v) -> { item | parsedSchema : v } -> { item | parsedSchema : v }
mapParsedSchema =
    map_ .parsedSchema setParsedSchema


mapParsedSchemaM : (v -> v) -> { item | parsedSchema : Maybe v } -> { item | parsedSchema : Maybe v }
mapParsedSchemaM =
    mapM_ .parsedSchema setParsedSchema


setParsedSource : v -> { item | parsedSource : v } -> { item | parsedSource : v }
setParsedSource =
    set_ .parsedSource (\value item -> { item | parsedSource = value })


setParsing : v -> { item | parsing : v } -> { item | parsing : v }
setParsing =
    set_ .parsing (\value item -> { item | parsing = value })


mapParsing : (v -> v) -> { item | parsing : v } -> { item | parsing : v }
mapParsing =
    map_ .parsing setParsing


mapParsingCmd : (v -> ( v, Cmd msg )) -> { item | parsing : v } -> ( { item | parsing : v }, Cmd msg )
mapParsingCmd =
    mapCmd_ .parsing setParsing


setPopover : v -> { item | popover : v } -> { item | popover : v }
setPopover =
    set_ .popover (\value item -> { item | popover = value })


setPosition : v -> { item | position : v } -> { item | position : v }
setPosition =
    set_ .position (\value item -> { item | position = value })


mapPosition : (v -> v) -> { item | position : v } -> { item | position : v }
mapPosition =
    map_ .position setPosition


setPrimaryKey : v -> { item | primaryKey : v } -> { item | primaryKey : v }
setPrimaryKey =
    set_ .primaryKey (\value item -> { item | primaryKey = value })


mapPrimaryKey : (v -> v) -> { item | primaryKey : v } -> { item | primaryKey : v }
mapPrimaryKey =
    map_ .primaryKey setPrimaryKey


mapPrimaryKeyM : (v -> v) -> { item | primaryKey : Maybe v } -> { item | primaryKey : Maybe v }
mapPrimaryKeyM =
    mapM_ .primaryKey setPrimaryKey


setProject : v -> { item | project : v } -> { item | project : v }
setProject =
    set_ .project (\value item -> { item | project = value })


mapProject : (v -> v) -> { item | project : v } -> { item | project : v }
mapProject =
    map_ .project setProject


mapProjectM : (v -> v) -> { item | project : Maybe v } -> { item | project : Maybe v }
mapProjectM =
    mapM_ .project setProject


mapProjectMCmd : (v -> ( v, Cmd msg )) -> { item | project : Maybe v } -> ( { item | project : Maybe v }, Cmd msg )
mapProjectMCmd =
    mapMCmd_ .project setProject


setProjectName : v -> { item | projectName : v } -> { item | projectName : v }
setProjectName =
    set_ .projectName (\value item -> { item | projectName = value })


setPrompt : v -> { item | prompt : v } -> { item | prompt : v }
setPrompt =
    set_ .prompt (\value item -> { item | prompt = value })


mapPrompt : (v -> v) -> { item | prompt : v } -> { item | prompt : v }
mapPrompt =
    map_ .prompt setPrompt


mapPromptM : (v -> v) -> { item | prompt : Maybe v } -> { item | prompt : Maybe v }
mapPromptM =
    mapM_ .prompt setPrompt


setProps : v -> { item | props : v } -> { item | props : v }
setProps =
    set_ .props (\value item -> { item | props = value })


mapProps : (v -> v) -> { item | props : v } -> { item | props : v }
mapProps =
    map_ .props setProps


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


setSampleProject : v -> { item | sampleProject : v } -> { item | sampleProject : v }
setSampleProject =
    set_ .sampleProject (\value item -> { item | sampleProject = value })


mapSampleProjectM : (v -> v) -> { item | sampleProject : Maybe v } -> { item | sampleProject : Maybe v }
mapSampleProjectM =
    mapM_ .sampleProject setSampleProject


mapSampleProjectMCmd : (v -> ( v, Cmd msg )) -> { item | sampleProject : Maybe v } -> ( { item | sampleProject : Maybe v }, Cmd msg )
mapSampleProjectMCmd =
    mapMCmd_ .sampleProject setSampleProject


setSchemaAnalysis : v -> { item | schemaAnalysis : v } -> { item | schemaAnalysis : v }
setSchemaAnalysis =
    set_ .schemaAnalysis (\value item -> { item | schemaAnalysis = value })


mapSchemaAnalysisM : (v -> v) -> { item | schemaAnalysis : Maybe v } -> { item | schemaAnalysis : Maybe v }
mapSchemaAnalysisM =
    mapM_ .schemaAnalysis setSchemaAnalysis


setScreen : v -> { item | screen : v } -> { item | screen : v }
setScreen =
    set_ .screen (\value item -> { item | screen = value })


mapScreen : (v -> v) -> { item | screen : v } -> { item | screen : v }
mapScreen =
    map_ .screen setScreen


setSearch : v -> { item | search : v } -> { item | search : v }
setSearch =
    set_ .search (\value item -> { item | search = value })


mapSearch : (v -> v) -> { item | search : v } -> { item | search : v }
mapSearch =
    map_ .search setSearch


setSelection : v -> { item | selection : v } -> { item | selection : v }
setSelection =
    set_ .selection (\value item -> { item | selection = value })


setSettings : v -> { item | settings : v } -> { item | settings : v }
setSettings =
    set_ .settings (\value item -> { item | settings = value })


mapSettings : (v -> v) -> { item | settings : v } -> { item | settings : v }
mapSettings =
    map_ .settings setSettings


setSelected : v -> { item | selected : v } -> { item | selected : v }
setSelected =
    set_ .selected (\value item -> { item | selected = value })


mapSelected : (v -> v) -> { item | selected : v } -> { item | selected : v }
mapSelected =
    map_ .selected setSelected


setSelectionBox : v -> { item | selectionBox : v } -> { item | selectionBox : v }
setSelectionBox =
    set_ .selectionBox (\value item -> { item | selectionBox = value })


mapSelectionBox : (v -> v) -> { item | selectionBox : v } -> { item | selectionBox : v }
mapSelectionBox =
    map_ .selectionBox setSelectionBox


setSharing : v -> { item | sharing : v } -> { item | sharing : v }
setSharing =
    set_ .sharing (\value item -> { item | sharing = value })


mapSharing : (v -> v) -> { item | sharing : v } -> { item | sharing : v }
mapSharing =
    map_ .sharing setSharing


mapSharingM : (v -> v) -> { item | sharing : Maybe v } -> { item | sharing : Maybe v }
mapSharingM =
    mapM_ .sharing setSharing


setShow : v -> { item | show : v } -> { item | show : v }
setShow =
    set_ .show (\value item -> { item | show = value })


mapShow : (v -> v) -> { item | show : v } -> { item | show : v }
mapShow =
    map_ .show setShow


setShown : v -> { item | shown : v } -> { item | shown : v }
setShown =
    set_ .shown (\value item -> { item | shown = value })


mapShown : (v -> v) -> { item | shown : v } -> { item | shown : v }
mapShown =
    map_ .shown setShown


setShownColumns : v -> { item | shownColumns : v } -> { item | shownColumns : v }
setShownColumns =
    set_ .shownColumns (\value item -> { item | shownColumns = value })


mapShownColumns : (v -> v) -> { item | shownColumns : v } -> { item | shownColumns : v }
mapShownColumns =
    map_ .shownColumns setShownColumns


setShownTables : v -> { item | shownTables : v } -> { item | shownTables : v }
setShownTables =
    set_ .shownTables (\value item -> { item | shownTables = value })


mapShownTables : (v -> v) -> { item | shownTables : v } -> { item | shownTables : v }
mapShownTables =
    map_ .shownTables setShownTables


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


setSources : v -> { item | sources : v } -> { item | sources : v }
setSources =
    set_ .sources (\value item -> { item | sources = value })


mapSources : (v -> v) -> { item | sources : v } -> { item | sources : v }
mapSources =
    map_ .sources setSources


mapSourcesL : (v -> k) -> k -> (v -> v) -> { item | sources : List v } -> { item | sources : List v }
mapSourcesL =
    mapL_ .sources setSources


setSourceUpdate : v -> { item | sourceUpdate : v } -> { item | sourceUpdate : v }
setSourceUpdate =
    set_ .sourceUpdate (\value item -> { item | sourceUpdate = value })


mapSourceUpdateCmd : (v -> ( v, Cmd msg )) -> { item | sourceUpdate : v } -> ( { item | sourceUpdate : v }, Cmd msg )
mapSourceUpdateCmd =
    mapCmd_ .sourceUpdate setSourceUpdate


setSqlSource : v -> { item | sqlSource : v } -> { item | sqlSource : v }
setSqlSource =
    set_ .sqlSource (\value item -> { item | sqlSource = value })


mapSqlSourceM : (v -> v) -> { item | sqlSource : Maybe v } -> { item | sqlSource : Maybe v }
mapSqlSourceM =
    mapM_ .sqlSource setSqlSource


mapSqlSourceCmd : (v -> ( v, Cmd msg )) -> { item | sqlSource : v } -> ( { item | sqlSource : v }, Cmd msg )
mapSqlSourceCmd =
    mapCmd_ .sqlSource setSqlSource


mapSqlSourceMCmd : (v -> ( v, Cmd msg )) -> { item | sqlSource : Maybe v } -> ( { item | sqlSource : Maybe v }, Cmd msg )
mapSqlSourceMCmd =
    mapMCmd_ .sqlSource setSqlSource


setStatus : v -> { item | status : v } -> { item | status : v }
setStatus =
    set_ .status (\value item -> { item | status = value })


setSwitch : v -> { item | switch : v } -> { item | switch : v }
setSwitch =
    set_ .switch (\value item -> { item | switch = value })


mapSwitch : (v -> v) -> { item | switch : v } -> { item | switch : v }
mapSwitch =
    map_ .switch setSwitch


setTable : v -> { item | table : v } -> { item | table : v }
setTable =
    set_ .table (\value item -> { item | table = value })


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
    mapCmd_ .tables setTables


setTableProps : v -> { item | tableProps : v } -> { item | tableProps : v }
setTableProps =
    set_ .tableProps (\value item -> { item | tableProps = value })


mapTableProps : (v -> v) -> { item | tableProps : v } -> { item | tableProps : v }
mapTableProps =
    map_ .tableProps setTableProps


mapTablePropsCmd : (v -> ( v, Cmd msg )) -> { item | tableProps : v } -> ( { item | tableProps : v }, Cmd msg )
mapTablePropsCmd =
    mapCmd_ .tableProps setTableProps


setTeam : v -> { item | team : v } -> { item | team : v }
setTeam =
    set_ .team (\value item -> { item | team = value })


mapTeamCmd : (v -> ( v, Cmd msg )) -> { item | team : v } -> ( { item | team : v }, Cmd msg )
mapTeamCmd =
    mapCmd_ .team setTeam


mapMTeamCmd : (v -> ( v, Cmd msg )) -> Maybe { item | team : v } -> ( Maybe { item | team : v }, Cmd msg )
mapMTeamCmd f model =
    model |> Maybe.map (mapTeamCmd f >> Tuple.mapFirst Just) |> Maybe.withDefault ( Nothing, Cmd.none )


setText : v -> { item | text : v } -> { item | text : v }
setText =
    set_ .text (\value item -> { item | text = value })


setTime : v -> { item | time : v } -> { item | time : v }
setTime =
    set_ .time (\value item -> { item | time = value })


mapTime : (v -> v) -> { item | time : v } -> { item | time : v }
mapTime =
    map_ .time setTime


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
    mapCmd_ .toasts setToasts


setToastIdx : v -> { item | toastIdx : v } -> { item | toastIdx : v }
setToastIdx =
    set_ .toastIdx (\value item -> { item | toastIdx = value })


setTop : v -> { item | top : v } -> { item | top : v }
setTop =
    set_ .top (\value item -> { item | top = value })


mapTop : (v -> v) -> { item | top : v } -> { item | top : v }
mapTop =
    map_ .top setTop


setTwitter : v -> { item | twitter : v } -> { item | twitter : v }
setTwitter =
    set_ .twitter (\value item -> { item | twitter = value })


setUniques : v -> { item | uniques : v } -> { item | uniques : v }
setUniques =
    set_ .uniques (\value item -> { item | uniques = value })


mapUniques : (v -> v) -> { item | uniques : v } -> { item | uniques : v }
mapUniques =
    map_ .uniques setUniques


setUpdatedAt : v -> { item | updatedAt : v } -> { item | updatedAt : v }
setUpdatedAt =
    set_ .updatedAt (\value item -> { item | updatedAt = value })


setUpload : v -> { item | upload : v } -> { item | upload : v }
setUpload =
    set_ .upload (\value item -> { item | upload = value })


mapUpload : (v -> v) -> { item | upload : v } -> { item | upload : v }
mapUpload =
    map_ .upload setUpload


mapUploadM : (v -> v) -> { item | upload : Maybe v } -> { item | upload : Maybe v }
mapUploadM =
    mapM_ .upload setUpload


mapUploadCmd : (v -> ( v, Cmd msg )) -> { item | upload : v } -> ( { item | upload : v }, Cmd msg )
mapUploadCmd =
    mapCmd_ .upload setUpload


setUrl : v -> { item | url : v } -> { item | url : v }
setUrl =
    set_ .url (\value item -> { item | url = value })


setUsedLayout : v -> { item | usedLayout : v } -> { item | usedLayout : v }
setUsedLayout =
    set_ .usedLayout (\value item -> { item | usedLayout = value })


mapUsedLayout : (v -> v) -> { item | usedLayout : v } -> { item | usedLayout : v }
mapUsedLayout =
    map_ .usedLayout setUsedLayout


setUser : v -> { item | user : v } -> { item | user : v }
setUser =
    set_ .user (\value item -> { item | user = value })


mapUser : (v -> v) -> { item | user : v } -> { item | user : v }
mapUser =
    map_ .user setUser


mapUserM : (v -> v) -> { item | user : Maybe v } -> { item | user : Maybe v }
mapUserM =
    mapM_ .user setUser


setUsername : v -> { item | username : v } -> { item | username : v }
setUsername =
    set_ .username (\value item -> { item | username = value })


mapUsername : (v -> v) -> { item | username : v } -> { item | username : v }
mapUsername =
    map_ .username setUsername


setValue : v -> { item | value : v } -> { item | value : v }
setValue =
    set_ .value (\value item -> { item | value = value })


setVirtualRelation : v -> { item | virtualRelation : v } -> { item | virtualRelation : v }
setVirtualRelation =
    set_ .virtualRelation (\value item -> { item | virtualRelation = value })


mapVirtualRelationM : (v -> v) -> { item | virtualRelation : Maybe v } -> { item | virtualRelation : Maybe v }
mapVirtualRelationM =
    mapM_ .virtualRelation setVirtualRelation


setWebsite : v -> { item | website : v } -> { item | website : v }
setWebsite =
    set_ .website (\value item -> { item | website = value })


setZoom : v -> { item | zoom : v } -> { item | zoom : v }
setZoom =
    set_ .zoom (\value item -> { item | zoom = value })


setZone : v -> { item | zone : v } -> { item | zone : v }
setZone =
    set_ .zone (\value item -> { item | zone = value })


mapM : (v -> v) -> Maybe v -> Maybe v
mapM transform item =
    item |> Maybe.map transform


mapMCmd : (v -> ( v, Cmd msg )) -> Maybe v -> ( Maybe v, Cmd msg )
mapMCmd transform item =
    item |> Maybe.mapOrElse (transform >> Tuple.mapFirst Just) ( Nothing, Cmd.none )


set_ : (item -> v) -> (v -> item -> item) -> v -> item -> item
set_ get update value item =
    if get item == value then
        item

    else
        update value item


map_ : (item -> v) -> (v -> item -> item) -> (v -> v) -> item -> item
map_ get update transform item =
    update (item |> get |> transform) item


mapM_ : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> v) -> item -> item
mapM_ get update transform item =
    update (item |> get |> Maybe.map transform) item


mapL_ : (item -> List v) -> (List v -> item -> item) -> (v -> k) -> k -> (v -> v) -> item -> item
mapL_ get update getKey key transform item =
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


mapD_ : (item -> Dict comparable v) -> (Dict comparable v -> item -> item) -> comparable -> (v -> v) -> item -> item
mapD_ get update key transform item =
    update (item |> get |> Dict.update key (Maybe.map transform)) item


mapCmd_ : (item -> v) -> (v -> item -> item) -> (v -> ( v, Cmd msg )) -> item -> ( item, Cmd msg )
mapCmd_ get update transform item =
    item |> get |> transform |> Tuple.mapFirst (\value -> update value item)


mapMCmd_ : (item -> Maybe v) -> (Maybe v -> item -> item) -> (v -> ( v, Cmd msg )) -> item -> ( item, Cmd msg )
mapMCmd_ get update transform item =
    item |> get |> Maybe.mapOrElse (transform >> Tuple.mapFirst (\value -> item |> update (Just value))) ( item, Cmd.none )


mapDCmd_ : (item -> Dict comparable v) -> (Dict comparable v -> item -> item) -> comparable -> (v -> ( v, Cmd msg )) -> item -> ( item, Cmd msg )
mapDCmd_ get update key transform item =
    item |> get |> Dict.get key |> Maybe.mapOrElse (transform >> Tuple.mapFirst (\n -> mapD_ get update key (\_ -> n) item)) ( item, Cmd.none )



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
