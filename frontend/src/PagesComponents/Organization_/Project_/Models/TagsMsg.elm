module PagesComponents.Organization_.Project_.Models.TagsMsg exposing (TagsMsg(..))

import Libs.Models.Tag exposing (Tag)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableId exposing (TableId)


type TagsMsg
    = TEdit String
    | TSave TableId (Maybe ColumnName) (List Tag) (List Tag)
