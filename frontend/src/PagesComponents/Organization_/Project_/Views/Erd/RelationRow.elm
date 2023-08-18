module PagesComponents.Organization_.Project_.Views.Erd.RelationRow exposing (viewRelationRow)

import Components.Organisms.Relation as Relation
import Components.Organisms.TableRow exposing (TableRowHover, TableRowRelation, TableRowSuccess)
import Conf
import Libs.Maybe as Maybe
import Libs.Models.Position exposing (Position)
import Libs.Tailwind exposing (Color)
import Models.Position as Position
import Models.Project.TableRow exposing (TableRow, TableRowColumn)
import Models.RelationStyle exposing (RelationStyle)
import PagesComponents.Organization_.Project_.Models exposing (Msg(..))
import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf)
import PagesComponents.Organization_.Project_.Views.Erd.Relation as Relation
import Svg exposing (Svg)
import Svg.Attributes exposing (strokeDasharray)


viewRelationRow : ErdConf -> RelationStyle -> Maybe TableRowHover -> TableRowRelation -> Svg Msg
viewRelationRow conf style hoverRow rel =
    let
        model : Relation.Model
        model =
            { hover = conf.hover }

        ( sPos, rPos ) =
            ( rel.src.row.position |> Position.extractGrid, rel.ref.row.position |> Position.extractGrid )

        ( ( srcX, srcDir ), ( refX, refDir ) ) =
            Relation.positionLeft rel.src.row rel.ref.row

        ( srcY, refY ) =
            ( sPos.top + Relation.deltaTop Conf.ui.tableRow rel.src.index rel.src.row.collapsed, rPos.top + Relation.deltaTop Conf.ui.tableRow rel.ref.index rel.ref.row.collapsed )

        color : Maybe Color
        color =
            hoverRow |> Maybe.filter (\h -> h == ( rel.src.row.id, Just rel.src.column.path ) || h == ( rel.ref.row.id, Just rel.ref.column.path )) |> Maybe.map (\_ -> rel.src.color)
    in
    Relation.show style model ( Position.canvas { left = srcX, top = srcY }, srcDir ) ( Position.canvas { left = refX, top = refY }, refDir ) [ strokeDasharray "2" ] color rel.id (\_ -> Noop "hover-relation-row")
