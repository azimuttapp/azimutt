module PagesComponents.Projects.Id_.Updates exposing (updateSizes)

import Conf
import Dict
import Libs.Area exposing (Area)
import Libs.Bool as B
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (SizeChange)
import Libs.Models.Position exposing (Position)
import Libs.Models.Size exposing (Size)
import Models.Project exposing (viewportArea)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models exposing (Model, Msg(..))
import Random


updateSizes : List SizeChange -> Model -> ( Model, Cmd Msg )
updateSizes sizeChanges model =
    ( sizeChanges |> List.foldl updateSize model, Cmd.batch (sizeChanges |> List.filterMap (initializeTableOnFirstSize model)) )


updateSize : SizeChange -> Model -> Model
updateSize change model =
    { model | domInfos = model.domInfos |> Dict.update change.id (\_ -> B.cond (change.size == Size 0 0) Nothing (Just { position = change.position, size = change.size })) }


initializeTableOnFirstSize : Model -> SizeChange -> Maybe (Cmd Msg)
initializeTableOnFirstSize model change =
    model.project
        |> Maybe.andThen
            (\p ->
                Maybe.map3 (\table props canvasInfos -> ( table, props, canvasInfos ))
                    (p.tables |> Dict.get (TableId.fromHtmlId change.id))
                    (p.layout.tables |> L.findBy .id (TableId.fromHtmlId change.id))
                    (model.domInfos |> Dict.get Conf.ids.erd)
                    |> M.filter (\( _, props, _ ) -> props.position == Position 0 0 && not (model.domInfos |> Dict.member change.id))
                    |> Maybe.map (\( t, _, canvasInfos ) -> t.id |> initializeTable change.size (viewportArea canvasInfos.size p.layout.canvas))
            )


initializeTable : Size -> Area -> TableId -> Cmd Msg
initializeTable size area id =
    positionGen size area |> Random.generate (InitializedTable id)


positionGen : Size -> Area -> Random.Generator Position
positionGen size area =
    Random.map2 Position
        (Random.float 0 (max 0 (area.size.width - size.width)) |> Random.map (\v -> area.position.left + v))
        (Random.float 0 (max 0 (area.size.height - size.height)) |> Random.map (\v -> area.position.top + v))
