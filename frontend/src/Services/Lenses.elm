module Services.Lenses exposing
    ( mapActive
    , mapAmlSidebarM
    , mapAmlSidebarMTM
    , mapAmlSourceT
    , mapBodyT
    , mapCanvas
    , mapCanvasT
    , mapCollapseTableColumns
    , mapCollapsedT
    , mapColorT
    , mapColumnBasicTypes
    , mapColumns
    , mapColumnsT
    , mapContent
    , mapContentT
    , mapContextMenuM
    , mapDataExplorerT
    , mapDatabaseSourceMTW
    , mapDatabaseSourceT
    , mapDetailsSidebarT
    , mapDetailsT
    , mapEditGroupM
    , mapEditMemoM
    , mapEditNotesM
    , mapEditTagsM
    , mapEmbedSourceParsingMTW
    , mapEnabled
    , mapErdM
    , mapErdMT
    , mapErdMTM
    , mapErdMTW
    , mapExportDialogT
    , mapFilters
    , mapFindPath
    , mapFindPathM
    , mapGroups
    , mapGroupsT
    , mapHidden
    , mapHiddenColumns
    , mapHoverTable
    , mapIndex
    , mapJsonSourceMTW
    , mapJsonSourceT
    , mapLayouts
    , mapLayoutsD
    , mapLayoutsDT
    , mapLayoutsDTL
    , mapLayoutsDTM
    , mapLayoutsDTW
    , mapList
    , mapMTW
    , mapMemos
    , mapMemosLT
    , mapMemosLTL
    , mapMemosT
    , mapMetadata
    , mapMobileMenuOpen
    , mapNavbar
    , mapNewLayoutMT
    , mapOpened
    , mapOpenedDialogs
    , mapOpenedDropdown
    , mapOrganization
    , mapOrganizationM
    , mapParsedSchemaM
    , mapPlan
    , mapPosition
    , mapPositionT
    , mapPrismaSourceMTW
    , mapPrismaSourceT
    , mapProject
    , mapProjectSourceMTW
    , mapProjectT
    , mapPromptM
    , mapProps
    , mapPropsT
    , mapRelatedTables
    , mapRelations
    , mapRemoveViews
    , mapRemovedSchemas
    , mapResult
    , mapResultsT
    , mapSampleSourceMTW
    , mapSaveT
    , mapSchemaAnalysisM
    , mapSearch
    , mapSelected
    , mapSelectedMT
    , mapSelectionBox
    , mapSettings
    , mapSettingsM
    , mapSharingT
    , mapShow
    , mapShowHiddenColumns
    , mapShowSettings
    , mapSourceUpdateT
    , mapSqlSourceMTW
    , mapSqlSourceT
    , mapState
    , mapStateT
    , mapTableRows
    , mapTableRowsSeq
    , mapTableRowsT
    , mapTables
    , mapTablesL
    , mapTablesLTM
    , mapTablesT
    , mapToasts
    , mapToastsT
    , mapTokenFormM
    , mapVirtualRelationM
    , mapVisualEditor
    , setActive
    , setAmlSidebar
    , setAmlSource
    , setArea
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
-- Here are same examples with name explanations:
--  - `setName "Loïc"`: set `name` property value in the record if different
--  - `mapName (\n -> n ++ "!")`: transform `name` property value with lambda function if different
--  - `mapNameM (\n -> n ++ "!")`: transform `name` optional property value with lambda function if present and different (M means Maybe)
--  - `mapNameT (\n -> (n, 1))`: transform `name` property value with lambda function returning a Tuple if different (T means Tuple)
--  - `mapNameMT (\n -> (n, 1))`: transform `name` optional property value with lambda function returning a Tuple if different (M means Maybe & T means Tuple)
--  - `mapNameMTW (\n -> (n, 1)) 0`: transform `name` optional property value with lambda function returning a Tuple using default value if different (M means Maybe, T means Tuple, W means With for default value)
--  - `mapNameMTM (\n -> (n, Just 1))`: transform `name` optional property value with lambda function returning a Tuple with Maybe if different (M means Maybe & T means Tuple)
--  - `mapColumnsD "name" (\c -> { c | active = True })`: transform Dict value at given key in `columns` property value with lambda function if different (D means Dict)
--  - `mapColumnsDT "name" (\c -> ({ c | active = True }, 1))`: transform Dict value at given key in `columns` property value with lambda function returning a Tuple if different (D means Dict, T means Tuple)
--  - `mapColumnsDTM "name" (\c -> ({ c | active = True }, Just 1))`: transform Dict value at given key in `columns` property value with lambda function returning a Tuple with Maybe if different (D means Dict, T means Tuple, M means Maybe)
--  - `mapColumnsL .name "name" (\c -> { c | active = True })`: transform List values having `name` property equal to "name" in `columns` property value with lambda function if different (L means List)
--  - `mapColumnsLT .name "name" (\c -> ({ c | active = True }, 1))`: transform List values having `name` property equal to "name" in `columns` property value with lambda function returning a Tuple if different (L means List, T means Tuple)
--  - `mapColumnsLTM .name "name" (\c -> ({ c | active = True }, Just 1))`: transform List values having `name` property equal to "name" in `columns` property value with lambda function returning a Tuple with Maybe if different (L means List, T means Tuple, M means Maybe)
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


mapAmlSidebarMTM : (v -> ( v, Maybe a )) -> { item | amlSidebar : Maybe v } -> ( { item | amlSidebar : Maybe v }, Maybe a )
mapAmlSidebarMTM =
    mapMTM_ .amlSidebar setAmlSidebar


setAmlSource : v -> { item | amlSource : v } -> { item | amlSource : v }
setAmlSource =
    set_ .amlSource (\value item -> { item | amlSource = value })


mapAmlSourceT : (v -> ( v, a )) -> { item | amlSource : v } -> ( { item | amlSource : v }, a )
mapAmlSourceT =
    mapT_ .amlSource setAmlSource


setArea : v -> { item | area : v } -> { item | area : v }
setArea =
    set_ .area (\value item -> { item | area = value })


setBody : v -> { item | body : v } -> { item | body : v }
setBody =
    set_ .body (\value item -> { item | body = value })


mapBodyT : (v -> ( v, a )) -> { item | body : v } -> ( { item | body : v }, a )
mapBodyT =
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


mapCollapsedT : (v -> ( v, a )) -> { item | collapsed : v } -> ( { item | collapsed : v }, a )
mapCollapsedT =
    mapT_ .collapsed setCollapsed


setCollapseTableColumns : v -> { item | collapseTableColumns : v } -> { item | collapseTableColumns : v }
setCollapseTableColumns =
    set_ .collapseTableColumns (\value item -> { item | collapseTableColumns = value })


mapCollapseTableColumns : (v -> v) -> { item | collapseTableColumns : v } -> { item | collapseTableColumns : v }
mapCollapseTableColumns =
    map_ .collapseTableColumns setCollapseTableColumns


setColor : v -> { item | color : v } -> { item | color : v }
setColor =
    set_ .color (\value item -> { item | color = value })


mapColorT : (v -> ( v, a )) -> { item | color : v } -> ( { item | color : v }, a )
mapColorT =
    mapT_ .color setColor


setColors : v -> { item | colors : v } -> { item | colors : v }
setColors =
    set_ .colors (\value item -> { item | colors = value })


setColumns : v -> { item | columns : v } -> { item | columns : v }
setColumns =
    set_ .columns (\value item -> { item | columns = value })


mapColumns : (v -> v) -> { item | columns : v } -> { item | columns : v }
mapColumns =
    map_ .columns setColumns


mapColumnsT : (v -> ( v, a )) -> { item | columns : v } -> ( { item | columns : v }, a )
mapColumnsT =
    mapT_ .columns setColumns


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


mapContentT : (v -> ( v, a )) -> { item | content : v } -> ( { item | content : v }, a )
mapContentT =
    mapT_ .content setContent


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


mapDatabaseSourceT : (v -> ( v, a )) -> { item | databaseSource : v } -> ( { item | databaseSource : v }, a )
mapDatabaseSourceT =
    mapT_ .databaseSource setDatabaseSource


mapDatabaseSourceMTW : (v -> ( v, a )) -> a -> { item | databaseSource : Maybe v } -> ( { item | databaseSource : Maybe v }, a )
mapDatabaseSourceMTW transform default item =
    mapMT_ .databaseSource setDatabaseSource transform item |> Tuple.mapSecond (Maybe.withDefault default)


setDataExplorer : v -> { item | dataExplorer : v } -> { item | dataExplorer : v }
setDataExplorer =
    set_ .dataExplorer (\value item -> { item | dataExplorer = value })


mapDataExplorerT : (v -> ( v, a )) -> { item | dataExplorer : v } -> ( { item | dataExplorer : v }, a )
mapDataExplorerT =
    mapT_ .dataExplorer setDataExplorer


setDefaultSchema : v -> { item | defaultSchema : v } -> { item | defaultSchema : v }
setDefaultSchema =
    set_ .defaultSchema (\value item -> { item | defaultSchema = value })


setDetails : v -> { item | details : v } -> { item | details : v }
setDetails =
    set_ .details (\value item -> { item | details = value })


mapDetailsT : (v -> ( v, a )) -> { item | details : v } -> ( { item | details : v }, a )
mapDetailsT =
    mapT_ .details setDetails


setDetailsSidebar : v -> { item | detailsSidebar : v } -> { item | detailsSidebar : v }
setDetailsSidebar =
    set_ .detailsSidebar (\value item -> { item | detailsSidebar = value })


mapDetailsSidebarT : (v -> ( v, a )) -> { item | detailsSidebar : v } -> ( { item | detailsSidebar : v }, a )
mapDetailsSidebarT =
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


mapEmbedSourceParsingMTW : (v -> ( v, a )) -> a -> { item | embedSourceParsing : Maybe v } -> ( { item | embedSourceParsing : Maybe v }, a )
mapEmbedSourceParsingMTW transform default item =
    mapMT_ .embedSourceParsing setEmbedSourceParsing transform item |> Tuple.mapSecond (Maybe.withDefault default)


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


mapErdMTW : (v -> ( v, a )) -> a -> { item | erd : Maybe v } -> ( { item | erd : Maybe v }, a )
mapErdMTW transform default item =
    mapMT_ .erd setErd transform item |> Tuple.mapSecond (Maybe.withDefault default)


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


mapExportDialogT : (v -> ( v, a )) -> { item | exportDialog : v } -> ( { item | exportDialog : v }, a )
mapExportDialogT =
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


mapGroupsT : (v -> ( v, a )) -> { item | groups : v } -> ( { item | groups : v }, a )
mapGroupsT =
    mapT_ .groups setGroups


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


setHoverTable : v -> { item | hoverTable : v } -> { item | hoverTable : v }
setHoverTable =
    set_ .hoverTable (\value item -> { item | hoverTable = value })


mapHoverTable : (v -> v) -> { item | hoverTable : v } -> { item | hoverTable : v }
mapHoverTable =
    map_ .hoverTable setHoverTable


setHoverTableRow : v -> { item | hoverTableRow : v } -> { item | hoverTableRow : v }
setHoverTableRow =
    set_ .hoverTableRow (\value item -> { item | hoverTableRow = value })


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


mapJsonSourceT : (v -> ( v, a )) -> { item | jsonSource : v } -> ( { item | jsonSource : v }, a )
mapJsonSourceT =
    mapT_ .jsonSource setJsonSource


mapJsonSourceMTW : (v -> ( v, a )) -> a -> { item | jsonSource : Maybe v } -> ( { item | jsonSource : Maybe v }, a )
mapJsonSourceMTW transform default item =
    mapMT_ .jsonSource setJsonSource transform item |> Tuple.mapSecond (Maybe.withDefault default)


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


mapLayoutsDT : comparable -> (v -> ( v, a )) -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, Maybe a )
mapLayoutsDT =
    mapDT_ .layouts setLayouts


mapLayoutsDTM : comparable -> (v -> ( v, Maybe a )) -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, Maybe a )
mapLayoutsDTM =
    mapDTM_ .layouts setLayouts


mapLayoutsDTL : comparable -> (v -> ( v, List a )) -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, List a )
mapLayoutsDTL =
    mapDTL_ .layouts setLayouts


mapLayoutsDTW : comparable -> (v -> ( v, a )) -> a -> { item | layouts : Dict comparable v } -> ( { item | layouts : Dict comparable v }, a )
mapLayoutsDTW key transform default item =
    mapDT_ .layouts setLayouts key transform item |> Tuple.mapSecond (Maybe.withDefault default)


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


mapMemosT : (v -> ( v, a )) -> { item | memos : v } -> ( { item | memos : v }, a )
mapMemosT =
    mapT_ .memos setMemos


mapMemosLT : (v -> k) -> k -> (v -> ( v, t )) -> { item | memos : List v } -> ( { item | memos : List v }, Maybe t )
mapMemosLT =
    mapLT_ .memos setMemos


mapMemosLTL : (v -> k) -> k -> (v -> ( v, List t )) -> { item | memos : List v } -> ( { item | memos : List v }, List t )
mapMemosLTL =
    mapLTL_ .memos setMemos


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


mapNewLayoutMT : (v -> ( v, a )) -> { item | newLayout : Maybe v } -> ( { item | newLayout : Maybe v }, Maybe a )
mapNewLayoutMT transform item =
    mapMT_ .newLayout setNewLayout transform item


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


mapPositionT : (v -> ( v, a )) -> { item | position : v } -> ( { item | position : v }, a )
mapPositionT =
    mapT_ .position setPosition


setPrevious : v -> { item | previous : v } -> { item | previous : v }
setPrevious =
    set_ .previous (\value item -> { item | previous = value })


setPrismaSource : v -> { item | prismaSource : v } -> { item | prismaSource : v }
setPrismaSource =
    set_ .prismaSource (\value item -> { item | prismaSource = value })


mapPrismaSourceT : (v -> ( v, a )) -> { item | prismaSource : v } -> ( { item | prismaSource : v }, a )
mapPrismaSourceT =
    mapT_ .prismaSource setPrismaSource


mapPrismaSourceMTW : (v -> ( v, a )) -> a -> { item | prismaSource : Maybe v } -> ( { item | prismaSource : Maybe v }, a )
mapPrismaSourceMTW transform default item =
    mapMT_ .prismaSource setPrismaSource transform item |> Tuple.mapSecond (Maybe.withDefault default)


setProject : v -> { item | project : v } -> { item | project : v }
setProject =
    set_ .project (\value item -> { item | project = value })


mapProject : (v -> v) -> { item | project : v } -> { item | project : v }
mapProject =
    map_ .project setProject


mapProjectT : (v -> ( v, a )) -> { item | project : v } -> ( { item | project : v }, a )
mapProjectT =
    mapT_ .project setProject


setProjectSource : v -> { item | projectSource : v } -> { item | projectSource : v }
setProjectSource =
    set_ .projectSource (\value item -> { item | projectSource = value })


mapProjectSourceMTW : (v -> ( v, a )) -> a -> { item | projectSource : Maybe v } -> ( { item | projectSource : Maybe v }, a )
mapProjectSourceMTW transform default item =
    mapMT_ .projectSource setProjectSource transform item |> Tuple.mapSecond (Maybe.withDefault default)


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


mapPropsT : (v -> ( v, a )) -> { item | props : v } -> ( { item | props : v }, a )
mapPropsT =
    mapT_ .props setProps


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


mapResultsT : (v -> ( v, a )) -> { item | results : v } -> ( { item | results : v }, a )
mapResultsT =
    mapT_ .results setResults


setSampleSource : v -> { item | sampleSource : v } -> { item | sampleSource : v }
setSampleSource =
    set_ .sampleSource (\value item -> { item | sampleSource = value })


mapSampleSourceMTW : (v -> ( v, a )) -> a -> { item | sampleSource : Maybe v } -> ( { item | sampleSource : Maybe v }, a )
mapSampleSourceMTW transform default item =
    mapMT_ .sampleSource setSampleSource transform item |> Tuple.mapSecond (Maybe.withDefault default)


setSave : v -> { item | save : v } -> { item | save : v }
setSave =
    set_ .save (\value item -> { item | save = value })


mapSaveT : (v -> ( v, a )) -> { item | save : v } -> ( { item | save : v }, a )
mapSaveT =
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


mapSelectedMT : (v -> ( v, a )) -> { item | selected : Maybe v } -> ( { item | selected : Maybe v }, Maybe a )
mapSelectedMT transform item =
    mapMT_ .selected setSelected transform item


setSelectionBox : v -> { item | selectionBox : v } -> { item | selectionBox : v }
setSelectionBox =
    set_ .selectionBox (\value item -> { item | selectionBox = value })


mapSelectionBox : (v -> v) -> { item | selectionBox : v } -> { item | selectionBox : v }
mapSelectionBox =
    map_ .selectionBox setSelectionBox


setSharing : v -> { item | sharing : v } -> { item | sharing : v }
setSharing =
    set_ .sharing (\value item -> { item | sharing = value })


mapSharingT : (v -> ( v, a )) -> { item | sharing : v } -> ( { item | sharing : v }, a )
mapSharingT =
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


mapSourceUpdateT : (v -> ( v, a )) -> { item | sourceUpdate : v } -> ( { item | sourceUpdate : v }, a )
mapSourceUpdateT =
    mapT_ .sourceUpdate setSourceUpdate


setSqlSource : v -> { item | sqlSource : v } -> { item | sqlSource : v }
setSqlSource =
    set_ .sqlSource (\value item -> { item | sqlSource = value })


mapSqlSourceT : (v -> ( v, a )) -> { item | sqlSource : v } -> ( { item | sqlSource : v }, a )
mapSqlSourceT =
    mapT_ .sqlSource setSqlSource


mapSqlSourceMTW : (v -> ( v, a )) -> a -> { item | sqlSource : Maybe v } -> ( { item | sqlSource : Maybe v }, a )
mapSqlSourceMTW transform default item =
    mapMT_ .sqlSource setSqlSource transform item |> Tuple.mapSecond (Maybe.withDefault default)


setState : v -> { item | state : v } -> { item | state : v }
setState =
    set_ .state (\value item -> { item | state = value })


mapState : (v -> v) -> { item | state : v } -> { item | state : v }
mapState =
    map_ .state setState


mapStateT : (v -> ( v, a )) -> { item | state : v } -> ( { item | state : v }, a )
mapStateT =
    mapT_ .state setState


setTables : v -> { item | tables : v } -> { item | tables : v }
setTables =
    set_ .tables (\value item -> { item | tables = value })


mapTables : (v -> v) -> { item | tables : v } -> { item | tables : v }
mapTables =
    map_ .tables setTables


mapTablesT : (v -> ( v, a )) -> { item | tables : v } -> ( { item | tables : v }, a )
mapTablesT =
    mapT_ .tables setTables


mapTablesL : (v -> k) -> k -> (v -> v) -> { item | tables : List v } -> { item | tables : List v }
mapTablesL =
    mapL_ .tables setTables


mapTablesLTM : (v -> k) -> k -> (v -> ( v, Maybe a )) -> { item | tables : List v } -> ( { item | tables : List v }, Maybe a )
mapTablesLTM =
    mapLTM_ .tables setTables


setTableRows : v -> { item | tableRows : v } -> { item | tableRows : v }
setTableRows =
    set_ .tableRows (\value item -> { item | tableRows = value })


mapTableRows : (v -> v) -> { item | tableRows : v } -> { item | tableRows : v }
mapTableRows =
    map_ .tableRows setTableRows


mapTableRowsT : (v -> ( v, a )) -> { item | tableRows : v } -> ( { item | tableRows : v }, a )
mapTableRowsT =
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


mapToastsT : (v -> ( v, a )) -> { item | toasts : v } -> ( { item | toasts : v }, a )
mapToastsT =
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


mapMTW : (v -> ( v, a )) -> a -> Maybe v -> ( Maybe v, a )
mapMTW transform default item =
    -- map Maybe with default
    item |> Maybe.mapOrElse (transform >> Tuple.mapFirst Just) ( Nothing, default )


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


mapDTL_ : (item -> Dict comparable v) -> (Dict comparable v -> item -> item) -> comparable -> (v -> ( v, List a )) -> item -> ( item, List a )
mapDTL_ get update key transform item =
    item |> get |> Dict.get key |> Maybe.mapOrElse (transform >> Tuple.mapFirst (\n -> mapD_ get update key (\_ -> n) item)) ( item, [] )


mapL_ : (item -> List v) -> (List v -> item -> item) -> (v -> k) -> k -> (v -> v) -> item -> item
mapL_ get update getKey key transform item =
    -- update list values in a record if match condition
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
        |> (\l -> update l item)


mapLT_ : (item -> List v) -> (List v -> item -> item) -> (v -> k) -> k -> (v -> ( v, t )) -> item -> ( item, Maybe t )
mapLT_ get update getKey key transform item =
    -- update list values in a record if match condition
    (item
        |> get
        |> List.map
            (\v ->
                if getKey v == key then
                    transform v |> Tuple.mapSecond Just

                else
                    ( v, Nothing )
            )
    )
        |> List.unzip
        |> Tuple.mapBoth (\l -> update l item) (List.filterMap identity >> List.head)


mapLTM_ : (item -> List v) -> (List v -> item -> item) -> (v -> k) -> k -> (v -> ( v, Maybe a )) -> item -> ( item, Maybe a )
mapLTM_ get update getKey key transform item =
    item
        |> get
        |> List.map
            (\v ->
                if getKey v == key then
                    transform v

                else
                    ( v, Nothing )
            )
        |> List.unzip
        |> Tuple.mapBoth (\l -> update l item) (List.filterMap identity >> List.head)


mapLTL_ : (item -> List v) -> (List v -> item -> item) -> (v -> k) -> k -> (v -> ( v, List t )) -> item -> ( item, List t )
mapLTL_ get update getKey key transform item =
    -- update list values in a record if match condition
    item
        |> get
        |> List.map
            (\v ->
                if getKey v == key then
                    transform v

                else
                    ( v, [] )
            )
        |> List.unzip
        |> Tuple.mapBoth (\l -> update l item) List.concat
