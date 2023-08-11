module PagesComponents.Organization_.Project_.Views.Erd.RelationRow exposing (viewRelationRow)

import Components.Organisms.Relation as Relation
import Conf
import Libs.Models.Position exposing (Position)
import Models.Position as Position
import Models.Project.TableRow exposing (TableRow, TableRowSuccess, TableRowValue)
import Models.RelationStyle exposing (RelationStyle)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Views.Erd.Relation as Relation
import Svg exposing (Svg)
import Svg.Attributes exposing (strokeDasharray)


viewRelationRow : ErdConf -> RelationStyle -> ( ( TableRowSuccess, Int, TableRowValue ), ( TableRowSuccess, Int, TableRowValue ) ) -> Svg Msg
viewRelationRow conf style ( ( src, srcIndex, _ ), ( ref, refIndex, _ ) ) =
    let
        model : Relation.Model
        model =
            { hover = conf.hover }

        ( sPos, rPos ) =
            ( src.row.position |> Position.extractGrid, ref.row.position |> Position.extractGrid )

        ( ( srcX, srcDir ), ( refX, refDir ) ) =
            Relation.positionLeft src.row ref.row

        ( srcY, refY ) =
            ( sPos.top + Relation.deltaTop Conf.ui.tableRow srcIndex False, rPos.top + Relation.deltaTop Conf.ui.tableRow refIndex False )
    in
    Relation.show style model ( Position.canvas { left = srcX, top = srcY }, srcDir ) ( Position.canvas { left = refX, top = refY }, refDir ) [ strokeDasharray "2" ] Nothing "TODO" (\_ -> Noop "hover-relation-row")
