module Services.Lenses exposing (setActive, setAllTableProps, setCanvas, setCurrentLayout, setErd, setLayout, setLayoutTables, setLayouts, setNavbar, setParsing, setParsingWithCmd, setPosition, setProject, setProjectWithCmd, setRelations, setScreen, setSearch, setSettings, setSizes, setSourceUpload, setSourceUploadWithCmd, setSwitch, setTableInList, setTableList, setTableProp, setTableProps, setTables, setTime)

import Libs.Bool as B
import Libs.Delta exposing (Delta)
import Libs.Maybe as M
import Libs.Models.Position exposing (Position)
import Libs.Models.ZoomLevel exposing (ZoomLevel)


setTime : (t -> t) -> { item | time : t } -> { item | time : t }
setTime transform item =
    { item | time = item.time |> transform }


setNavbar : (n -> n) -> { item | navbar : n } -> { item | navbar : n }
setNavbar transform item =
    { item | navbar = item.navbar |> transform }


setSearch : (s -> s) -> { item | search : s } -> { item | search : s }
setSearch transform item =
    { item | search = item.search |> transform }


setErd : (e -> e) -> { item | erd : Maybe e } -> { item | erd : Maybe e }
setErd transform item =
    { item | erd = item.erd |> Maybe.map transform }


setSizes : (s -> s) -> { item | sizes : s } -> { item | sizes : s }
setSizes transform item =
    { item | sizes = item.sizes |> transform }


setTableProps : (s -> s) -> { item | tableProps : s } -> { item | tableProps : s }
setTableProps transform item =
    { item | tableProps = item.tableProps |> transform }


setActive : (a -> a) -> { item | active : a } -> { item | active : a }
setActive transform item =
    { item | active = item.active |> transform }


setSwitch : (s -> s) -> { item | switch : s } -> { item | switch : s }
setSwitch transform item =
    { item | switch = item.switch |> transform }


setScreen : (s -> s) -> { item | screen : s } -> { item | screen : s }
setScreen transform item =
    { item | screen = item.screen |> transform }


setProject : (p -> p) -> { item | project : Maybe p } -> { item | project : Maybe p }
setProject transform item =
    { item | project = item.project |> Maybe.map transform }


setProjectWithCmd : (p -> ( p, Cmd msg )) -> { item | project : Maybe p } -> ( { item | project : Maybe p }, Cmd msg )
setProjectWithCmd transform item =
    item.project |> M.mapOrElse (\p -> p |> transform |> Tuple.mapFirst (\project -> { item | project = Just project })) ( item, Cmd.none )


setRelations : (r -> r) -> { item | relations : r } -> { item | relations : r }
setRelations transform item =
    { item | relations = item.relations |> transform }


setLayout : (l -> l) -> { item | layout : l } -> { item | layout : l }
setLayout transform item =
    { item | layout = item.layout |> transform }


setCurrentLayout : (l -> l) -> { m | project : Maybe { p | layout : l } } -> { m | project : Maybe { p | layout : l } }
setCurrentLayout transform item =
    setProject (setLayout transform) item


setLayoutTables : (t -> t) -> { m | project : Maybe { p | layout : { l | tables : t } } } -> { m | project : Maybe { p | layout : { l | tables : t } } }
setLayoutTables transform item =
    setProject (setLayout (setTables transform)) item


setAllTableProps : ({ t | id : comparable } -> { t | id : comparable }) -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } } -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } }
setAllTableProps transform item =
    setLayoutTables (List.map transform) item


setTableProp : comparable -> ({ t | id : comparable } -> { t | id : comparable }) -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } } -> { m | project : Maybe { p | layout : { l | tables : List { t | id : comparable } } } }
setTableProp id transform item =
    setProject (setLayout (setTableInList .id id transform)) item


setCanvas : (l -> l) -> { item | canvas : l } -> { item | canvas : l }
setCanvas transform item =
    { item | canvas = item.canvas |> transform }


setTables : (t -> t) -> { item | tables : t } -> { item | tables : t }
setTables transform item =
    { item | tables = item.tables |> transform }


setTableList : (table -> Bool) -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
setTableList predicate transform item =
    setTables (\tables -> tables |> List.map (\t -> B.cond (predicate t) (transform t) t)) item


setTableInList : (table -> comparable) -> comparable -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
setTableInList get id transform item =
    setTableList (\t -> get t == id) transform item


setLayouts : (l -> l) -> { item | layouts : l } -> { item | layouts : l }
setLayouts transform item =
    { item | layouts = item.layouts |> transform }


setPosition : Delta -> ZoomLevel -> { item | position : Position } -> { item | position : Position }
setPosition delta zoom item =
    { item | position = Position (item.position.left + (delta.dx / zoom)) (item.position.top + (delta.dy / zoom)) }


setSettings : (s -> s) -> { item | settings : s } -> { item | settings : s }
setSettings transform item =
    { item | settings = item.settings |> transform }


setSourceUpload : (su -> su) -> { item | sourceUpload : Maybe su } -> { item | sourceUpload : Maybe su }
setSourceUpload transform item =
    { item | sourceUpload = item.sourceUpload |> Maybe.map transform }


setSourceUploadWithCmd : (su -> ( su, Cmd msg )) -> { item | sourceUpload : Maybe su } -> ( { item | sourceUpload : Maybe su }, Cmd msg )
setSourceUploadWithCmd transform item =
    item.sourceUpload |> M.mapOrElse (transform >> Tuple.mapFirst (\su -> { item | sourceUpload = Just su })) ( item, Cmd.none )


setParsing : (p -> p) -> { item | parsing : p } -> { item | parsing : p }
setParsing transform item =
    { item | parsing = transform item.parsing }


setParsingWithCmd : (p -> ( p, Cmd msg )) -> { item | parsing : p } -> ( { item | parsing : p }, Cmd msg )
setParsingWithCmd transform item =
    item.parsing |> transform |> Tuple.mapFirst (\p -> { item | parsing = p })



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
