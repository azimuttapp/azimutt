module PagesComponents.Organization_.Project_.Models.ErdComment exposing (ErdComment, create, unpack)

import Models.Project.Comment exposing (Comment)
import PagesComponents.Organization_.Project_.Models.Erd.TableWithOrigin exposing (CommentWithOrigin)
import PagesComponents.Organization_.Project_.Models.ErdOrigin exposing (ErdOrigin)


type alias ErdComment =
    { text : String
    , origins : List ErdOrigin
    }


create : CommentWithOrigin -> ErdComment
create comment =
    { text = comment.text
    , origins = comment.origins
    }


unpack : ErdComment -> Comment
unpack comment =
    { text = comment.text
    }
