module PagesComponents.Projects.Id_.Models.EmbedMode exposing (EmbedMode, EmbedModeId, advanced, all, default, frozen, full, layout, move, static)

import PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf, embedDefault)


type alias EmbedMode =
    { id : EmbedModeId, description : String, conf : ErdConf }


type alias EmbedModeId =
    String


all : List EmbedMode
all =
    [ { id = frozen, description = "nothing move, like a image", conf = embedDefault }
    , { id = static, description = "highlight on hover but no move", conf = { embedDefault | hover = True, select = True } }
    , { id = move, description = "can move things but not more", conf = { embedDefault | hover = True, select = True, move = True } }
    , { id = layout, description = "can update the layout", conf = { embedDefault | hover = True, select = True, move = True, layout = True } }
    , { id = advanced, description = "can seen and navigate between layouts", conf = { embedDefault | hover = True, select = True, move = True, layout = True, showNavbar = True, findPath = True } }
    , { id = full, description = "can do anything, except save", conf = { embedDefault | hover = True, select = True, move = True, layout = True, showNavbar = True, findPath = True, layoutManagement = True } }
    ]


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
