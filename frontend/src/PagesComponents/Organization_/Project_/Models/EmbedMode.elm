module PagesComponents.Organization_.Project_.Models.EmbedMode exposing (EmbedMode, EmbedModeId, advanced, all, default, frozen, full, key, layout, move, static)

import PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf, embedDefault)


type alias EmbedMode =
    { id : EmbedModeId, description : String, conf : ErdConf }


type alias EmbedModeId =
    String


all : List EmbedMode
all =
    [ { id = frozen, description = "nothing move, like an image", conf = embedDefault }
    , { id = static, description = "highlight on hover but no move", conf = { embedDefault | hover = True, select = True } }
    , { id = move, description = "can move things but not more", conf = { embedDefault | hover = True, select = True, move = True } }
    , { id = layout, description = "can update the layout", conf = { embedDefault | hover = True, select = True, move = True, layout = True } }
    , { id = advanced, description = "can see and navigate between layouts", conf = { embedDefault | hover = True, select = True, move = True, layout = True, showNavbar = True, findPath = True } }
    , { id = full, description = "can do anything, except save", conf = { embedDefault | hover = True, select = True, move = True, layout = True, showNavbar = True, findPath = True, layoutManagement = True } }
    ]


key : String
key =
    "mode"


default : EmbedModeId
default =
    layout


frozen : EmbedModeId
frozen =
    "frozen"


static : EmbedModeId
static =
    "static"


move : EmbedModeId
move =
    "move"


layout : EmbedModeId
layout =
    "layout"


advanced : EmbedModeId
advanced =
    "advanced"


full : EmbedModeId
full =
    "full"
