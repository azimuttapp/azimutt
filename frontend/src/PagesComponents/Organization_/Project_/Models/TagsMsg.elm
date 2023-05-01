module PagesComponents.Organization_.Project_.Models.TagsMsg exposing (TagsMsg(..))

import Libs.Models.Tag exposing (Tag)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)


type TagsMsg
    = TEdit String
    | TSave TableId (Maybe ColumnPath) (List Tag) (List Tag)
