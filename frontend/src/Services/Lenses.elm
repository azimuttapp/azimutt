module Services.Lenses exposing
    ( mapActive
    , mapAmlSidebarM
    , mapAmlSourceCmd
    , mapCanvas
    , mapChecks
    , mapCollapseTableColumns
    , mapColumnBasicTypes
    , mapColumns
    , mapCommentM
    , mapConf
    , mapContent
    , mapContextMenuM
    , mapDatabaseSourceCmd
    , mapDatabaseSourceMCmd
    , mapDetailsSidebarCmd
    , mapEditNotesM
    , mapEmbedSourceParsingMCmd
    , mapEnabled
    , mapErdM
    , mapErdMCmd
    , mapFindPath
    , mapFindPathM
    , mapHiddenColumns
    , mapHoverTable
    , mapIndex
    , mapIndexes
    , mapJsonSourceCmd
    , mapJsonSourceMCmd
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
    , mapNewLayoutMCmd
    , mapNotes
    , mapOpened
    , mapOpenedDialogs
    , mapOpenedDropdown
    , mapParsedSchemaM
    , mapPosition
    , mapPrimaryKeyM
    , mapProject
    , mapProjectSourceMCmd
    , mapPromptM
    , mapProps
    , mapRelatedTables
    , mapRelations
    , mapRemoveViews
    , mapRemovedSchemas
    , mapResult
    , mapSampleSourceMCmd
    , mapSaveCmd
    , mapSaveM
    , mapSchemaAnalysisM
    , mapSearch
    , mapSelected
    , mapSettings
    , mapSharingM
    , mapShow
    , mapShowHiddenColumns
    , mapShowSettings
    , mapSourceUpdateCmd
    , mapSources
    , mapSqlSourceCmd
    , mapSqlSourceMCmd
    , mapTables
    , mapTablesCmd
    , mapTablesL
    , mapTeamCmd
    , mapToasts
    , mapToastsCmd
    , mapTop
    , mapUniques
    , mapUserM
    , mapVirtualRelationM
    , setActive
    , setAmlSidebar
    , setAmlSource
    , setBio
    , setCanvas
    , setChecks
    , setCollapseTableColumns
    , setCollapsed
    , setColor
    , setColumnBasicTypes
    , setColumnOrder
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
    , setHighlight
    , setHighlighted
    , setHoverColumn
    , setHoverTable
    , setId
    , setIgnoredColumns
    , setIgnoredTables
    , setIndex
    , setIndexes
    , setInput
    , setIsOpen
    , setJsonSource
    , setLast
    , setLayouts
    , setList
    , setLocation
    , setMax
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
    , setOrigins
    , setParsedSchema
    , setParsedSource
    , setPosition
    , setPrimaryKey
    , setProject
    , setProjectName
    , setProjectSource
    , setPrompt
    , setProps
    , setRelatedTables
    , setRelationStyle
    , setRelations
    , setRemoveViews
    , setRemovedSchemas
    , setRemovedTables
    , setResult
    , setSampleSource
    , setSave
    , setSchemaAnalysis
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
    , setSources
    , setSqlSource
    , setTable
    , setTables
    , setTeam
    , setText
    , setTo
    , setToasts
    , setTop
    , setTwitter
    , setUniques
    , setUpdatedAt
    , setUser
    , setUsername
    , setValue
    , setView
    , setVirtualRelation
    , setWebsite
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
    mapCmd_ .amlSource setAmlSource


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


setComment : v -> { item | comment : v } -> { item | comment : v }
setComment =
    set_ .comment (\value item -> { item | comment = value })


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


mapDatabaseSourceCmd : (v -> ( v, Cmd msg )) -> { item | databaseSource : v } -> ( { item | databaseSource : v }, Cmd msg )
mapDatabaseSourceCmd =
    mapCmd_ .databaseSource setDatabaseSource


mapDatabaseSourceMCmd : (v -> ( v, Cmd msg )) -> { item | databaseSource : Maybe v } -> ( { item | databaseSource : Maybe v }, Cmd msg )
mapDatabaseSourceMCmd =
    mapMCmd_ .databaseSource setDatabaseSource


setDefaultSchema : v -> { item | defaultSchema : v } -> { item | defaultSchema : v }
setDefaultSchema =
    set_ .defaultSchema (\value item -> { item | defaultSchema = value })


setDetailsSidebar : v -> { item | detailsSidebar : v } -> { item | detailsSidebar : v }
setDetailsSidebar =
    set_ .detailsSidebar (\value item -> { item | detailsSidebar = value })


mapDetailsSidebarCmd : (v -> ( v, Cmd msg )) -> { item | detailsSidebar : v } -> ( { item | detailsSidebar : v }, Cmd msg )
mapDetailsSidebarCmd =
    mapCmd_ .detailsSidebar setDetailsSidebar


setDragging : v -> { item | dragging : v } -> { item | dragging : v }
setDragging =
    set_ .dragging (\value item -> { item | dragging = value })


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


setHighlight : v -> { item | highlight : v } -> { item | highlight : v }
setHighlight =
    set_ .highlight (\value item -> { item | highlight = value })


setHighlighted : v -> { item | highlighted : v } -> { item | highlighted : v }
setHighlighted =
    set_ .highlighted (\value item -> { item | highlighted = value })


setHoverColumn : v -> { item | hoverColumn : v } -> { item | hoverColumn : v }
setHoverColumn =
    set_ .hoverColumn (\value item -> { item | hoverColumn = value })


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


mapJsonSourceCmd : (v -> ( v, Cmd msg )) -> { item | jsonSource : v } -> ( { item | jsonSource : v }, Cmd msg )
mapJsonSourceCmd =
    mapCmd_ .jsonSource setJsonSource


mapJsonSourceMCmd : (v -> ( v, Cmd msg )) -> { item | jsonSource : Maybe v } -> ( { item | jsonSource : Maybe v }, Cmd msg )
mapJsonSourceMCmd =
    mapMCmd_ .jsonSource setJsonSource


setLast : v -> { item | last : v } -> { item | last : v }
setLast =
    set_ .last (\value item -> { item | last = value })


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


mapNewLayoutM : (v -> v) -> { item | newLayout : Maybe v } -> { item | newLayout : Maybe v }
mapNewLayoutM =
    mapM_ .newLayout setNewLayout


mapNewLayoutMCmd : (v -> ( v, Cmd msg )) -> { item | newLayout : Maybe v } -> ( { item | newLayout : Maybe v }, Cmd msg )
mapNewLayoutMCmd =
    mapMCmd_ .newLayout setNewLayout


setNotes : v -> { item | notes : v } -> { item | notes : v }
setNotes =
    set_ .notes (\value item -> { item | notes = value })


mapNotes : (v -> v) -> { item | notes : v } -> { item | notes : v }
mapNotes =
    map_ .notes setNotes


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


setOrigins : v -> { item | origins : v } -> { item | origins : v }
setOrigins =
    set_ .origins (\value item -> { item | origins = value })


setParsedSchema : v -> { item | parsedSchema : v } -> { item | parsedSchema : v }
setParsedSchema =
    set_ .parsedSchema (\value item -> { item | parsedSchema = value })


mapParsedSchemaM : (v -> v) -> { item | parsedSchema : Maybe v } -> { item | parsedSchema : Maybe v }
mapParsedSchemaM =
    mapM_ .parsedSchema setParsedSchema


setParsedSource : v -> { item | parsedSource : v } -> { item | parsedSource : v }
setParsedSource =
    set_ .parsedSource (\value item -> { item | parsedSource = value })


setPosition : v -> { item | position : v } -> { item | position : v }
setPosition =
    set_ .position (\value item -> { item | position = value })


mapPosition : (v -> v) -> { item | position : v } -> { item | position : v }
mapPosition =
    map_ .position setPosition


setPrimaryKey : v -> { item | primaryKey : v } -> { item | primaryKey : v }
setPrimaryKey =
    set_ .primaryKey (\value item -> { item | primaryKey = value })


mapPrimaryKeyM : (v -> v) -> { item | primaryKey : Maybe v } -> { item | primaryKey : Maybe v }
mapPrimaryKeyM =
    mapM_ .primaryKey setPrimaryKey


setProject : v -> { item | project : v } -> { item | project : v }
setProject =
    set_ .project (\value item -> { item | project = value })


mapProject : (v -> v) -> { item | project : v } -> { item | project : v }
mapProject =
    map_ .project setProject


setProjectName : v -> { item | projectName : v } -> { item | projectName : v }
setProjectName =
    set_ .projectName (\value item -> { item | projectName = value })


setProjectSource : v -> { item | projectSource : v } -> { item | projectSource : v }
setProjectSource =
    set_ .projectSource (\value item -> { item | projectSource = value })


mapProjectSourceMCmd : (v -> ( v, Cmd msg )) -> { item | projectSource : Maybe v } -> ( { item | projectSource : Maybe v }, Cmd msg )
mapProjectSourceMCmd =
    mapMCmd_ .projectSource setProjectSource


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


setSampleSource : v -> { item | sampleSource : v } -> { item | sampleSource : v }
setSampleSource =
    set_ .sampleSource (\value item -> { item | sampleSource = value })


mapSampleSourceMCmd : (v -> ( v, Cmd msg )) -> { item | sampleSource : Maybe v } -> ( { item | sampleSource : Maybe v }, Cmd msg )
mapSampleSourceMCmd =
    mapMCmd_ .sampleSource setSampleSource


setSave : v -> { item | save : v } -> { item | save : v }
setSave =
    set_ .save (\value item -> { item | save = value })


mapSaveM : (v -> v) -> { item | save : Maybe v } -> { item | save : Maybe v }
mapSaveM =
    mapM_ .save setSave


mapSaveCmd : (v -> ( v, Cmd msg )) -> { item | save : v } -> ( { item | save : v }, Cmd msg )
mapSaveCmd =
    mapCmd_ .save setSave


setSchemaAnalysis : v -> { item | schemaAnalysis : v } -> { item | schemaAnalysis : v }
setSchemaAnalysis =
    set_ .schemaAnalysis (\value item -> { item | schemaAnalysis = value })


mapSchemaAnalysisM : (v -> v) -> { item | schemaAnalysis : Maybe v } -> { item | schemaAnalysis : Maybe v }
mapSchemaAnalysisM =
    mapM_ .schemaAnalysis setSchemaAnalysis


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


setSourceUpdate : v -> { item | sourceUpdate : v } -> { item | sourceUpdate : v }
setSourceUpdate =
    set_ .sourceUpdate (\value item -> { item | sourceUpdate = value })


mapSourceUpdateCmd : (v -> ( v, Cmd msg )) -> { item | sourceUpdate : v } -> ( { item | sourceUpdate : v }, Cmd msg )
mapSourceUpdateCmd =
    mapCmd_ .sourceUpdate setSourceUpdate


setSqlSource : v -> { item | sqlSource : v } -> { item | sqlSource : v }
setSqlSource =
    set_ .sqlSource (\value item -> { item | sqlSource = value })


mapSqlSourceCmd : (v -> ( v, Cmd msg )) -> { item | sqlSource : v } -> ( { item | sqlSource : v }, Cmd msg )
mapSqlSourceCmd =
    mapCmd_ .sqlSource setSqlSource


mapSqlSourceMCmd : (v -> ( v, Cmd msg )) -> { item | sqlSource : Maybe v } -> ( { item | sqlSource : Maybe v }, Cmd msg )
mapSqlSourceMCmd =
    mapMCmd_ .sqlSource setSqlSource


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


setUser : v -> { item | user : v } -> { item | user : v }
setUser =
    set_ .user (\value item -> { item | user = value })


mapUserM : (v -> v) -> { item | user : Maybe v } -> { item | user : Maybe v }
mapUserM =
    mapM_ .user setUser


setUsername : v -> { item | username : v } -> { item | username : v }
setUsername =
    set_ .username (\value item -> { item | username = value })


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


setWebsite : v -> { item | website : v } -> { item | website : v }
setWebsite =
    set_ .website (\value item -> { item | website = value })


setZoom : v -> { item | zoom : v } -> { item | zoom : v }
setZoom =
    set_ .zoom (\value item -> { item | zoom = value })



-- specific methods


mapM : (v -> v) -> Maybe v -> Maybe v
mapM transform item =
    item |> Maybe.map transform


mapMCmd : (v -> ( v, Cmd msg )) -> Maybe v -> ( Maybe v, Cmd msg )
mapMCmd transform item =
    item |> Maybe.mapOrElse (transform >> Tuple.mapFirst Just) ( Nothing, Cmd.none )


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



-- HELPERS


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
