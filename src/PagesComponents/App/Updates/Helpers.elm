module PagesComponents.App.Updates.Helpers exposing (decodeErrorToHtml, setCanvas, setLayout, setLayouts, setListTable, setPosition, setProject, setProjectWithCmd, setSchema, setSchemaWithCmd, setSettings, setSwitch, setTables, setTime)

import Draggable
import Json.Decode as Decode
import Libs.Bool as B
import Libs.Models exposing (ZoomLevel)
import Libs.Position exposing (Position)


setTime : (t -> t) -> { item | time : t } -> { item | time : t }
setTime transform item =
    { item | time = item.time |> transform }


setSwitch : (s -> s) -> { item | switch : s } -> { item | switch : s }
setSwitch transform item =
    { item | switch = item.switch |> transform }


setProject : (p -> p) -> { item | project : Maybe p } -> { item | project : Maybe p }
setProject transform item =
    { item | project = item.project |> Maybe.map transform }


setProjectWithCmd : (p -> ( p, Cmd msg )) -> { item | project : Maybe p } -> ( { item | project : Maybe p }, Cmd msg )
setProjectWithCmd transform item =
    item.project |> Maybe.map (\p -> p |> transform |> Tuple.mapFirst (\project -> { item | project = Just project })) |> Maybe.withDefault ( item, Cmd.none )


setSchema : (s -> s) -> { item | schema : s } -> { item | schema : s }
setSchema transform item =
    { item | schema = transform item.schema }


setSchemaWithCmd : (s -> ( s, Cmd msg )) -> { item | schema : s } -> ( { item | schema : s }, Cmd msg )
setSchemaWithCmd transform item =
    transform item.schema |> Tuple.mapFirst (\s -> { item | schema = s })


setLayout : (l -> l) -> { item | layout : l } -> { item | layout : l }
setLayout transform item =
    { item | layout = item.layout |> transform }


setCanvas : (l -> l) -> { item | canvas : l } -> { item | canvas : l }
setCanvas transform item =
    { item | canvas = item.canvas |> transform }


setTables : (t -> t) -> { item | tables : t } -> { item | tables : t }
setTables transform item =
    { item | tables = item.tables |> transform }


setLayouts : (l -> l) -> { item | layouts : l } -> { item | layouts : l }
setLayouts transform item =
    { item | layouts = item.layouts |> transform }


setPosition : Draggable.Delta -> ZoomLevel -> { item | position : Position } -> { item | position : Position }
setPosition ( dx, dy ) zoom item =
    { item | position = Position (item.position.left + (dx / zoom)) (item.position.top + (dy / zoom)) }


setListTable : (table -> comparable) -> comparable -> (table -> table) -> { item | tables : List table } -> { item | tables : List table }
setListTable get id transform item =
    { item | tables = item.tables |> List.map (\t -> B.cond (get t == id) (transform t) t) }


setSettings : (s -> s) -> { item | settings : s } -> { item | settings : s }
setSettings transform item =
    { item | settings = item.settings |> transform }


decodeErrorToHtml : Decode.Error -> String
decodeErrorToHtml error =
    "<pre>" ++ Decode.errorToString error ++ "</pre>"



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
