module PagesComponents.Organization_.Project_.Updates.Color exposing (Model, handleColor)

import Components.Slices.PlanDialog as PlanDialog
import Dict
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Tailwind exposing (Color)
import Libs.Task as T
import Models.Feature as Feature
import Models.Organization as Organization
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableMeta as TableMeta
import Models.ProjectRef exposing (ProjectRef)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.ColorMsg exposing (ColorMsg(..))
import PagesComponents.Organization_.Project_.Models.Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Updates.Extra as Extra exposing (Extra)
import PagesComponents.Organization_.Project_.Updates.Utils exposing (setDirty)
import Services.Lenses exposing (mapErdM, mapLayouts, mapMetadata, mapProps, setColor)
import Time
import Track


type alias Model x =
    { x
        | conf : ErdConf
        , dirty : Bool
        , erd : Maybe Erd
    }


handleColor : Time.Posix -> ProjectRef -> ColorMsg -> Model x -> ( Model x, Extra Msg )
handleColor now projectRef msg model =
    case msg of
        CSave table old new ->
            if Organization.canChangeColor projectRef then
                ( model |> mapErdM (mapMetadata (Dict.update table (Maybe.withDefault TableMeta.empty >> setColor new >> Just)))
                , Extra.history ( ColorMsg (CSave table new old), ColorMsg msg )
                )
                    |> setDirty

            else
                ( model, Extra.cmdL [ PlanDialog.colorsModalBody projectRef PlanDialogColors PlanDialog.colorsInit |> CustomModalOpen |> T.send, Track.planLimit Feature.colors model.erd ] )

        CApply table color ->
            model.erd
                |> Maybe.map
                    (\erd ->
                        let
                            toUpdate : List ( LayoutName, TableId, ( Color, Color ) )
                            toUpdate =
                                erd.layouts
                                    |> Dict.toList
                                    |> List.filterMap
                                        (\( name, layout ) ->
                                            layout.tables
                                                |> List.find (\t -> t.id == table && t.props.color /= color)
                                                |> Maybe.map (\t -> ( name, table, ( t.props.color, color ) ))
                                        )
                        in
                        ( model, CSet toUpdate |> ColorMsg |> Extra.msg )
                    )
                |> Maybe.withDefault ( model, Extra.none )

        CSet changes ->
            if Organization.canChangeColor projectRef then
                ( model |> mapErdM (mapLayouts (Dict.map (\name layout -> changes |> List.find (\( l, _, _ ) -> name == l) |> Maybe.mapOrElse (\( _, t, ( _, color ) ) -> updateLayoutTableColor now t color layout) layout)))
                , Extra.history ( changes |> List.map (\( l, t, ( old, new ) ) -> ( l, t, ( new, old ) )) |> CSet |> ColorMsg, changes |> CSet |> ColorMsg )
                )
                    |> setDirty

            else
                ( model, Extra.cmdL [ PlanDialog.colorsModalBody projectRef PlanDialogColors PlanDialog.colorsInit |> CustomModalOpen |> T.send, Track.planLimit Feature.colors model.erd ] )


updateLayoutTableColor : Time.Posix -> TableId -> Color -> ErdLayout -> ErdLayout
updateLayoutTableColor now table color layout =
    { layout
        | updatedAt = now
        , tables =
            layout.tables
                |> List.map
                    (\t ->
                        if t.id == table && t.props.color /= color then
                            t |> mapProps (setColor color)

                        else
                            t
                    )
    }
