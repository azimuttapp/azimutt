module PagesComponents.Projects.Id_.Models.ErdConf exposing (ErdConf, default, embedDefault)


type alias ErdConf =
    { fitOnLoad : Bool
    , fullscreen : Bool
    , save : Bool
    , hover : Bool
    , select : Bool
    , move : Bool
    , layout : Bool
    , showNavbar : Bool
    , dashboardLink : Bool
    , findPath : Bool
    , layoutManagement : Bool
    , projectManagement : Bool
    , sharing : Bool
    }


default : ErdConf
default =
    -- used for real app
    { fitOnLoad = False
    , fullscreen = False
    , save = True
    , hover = True
    , select = True
    , move = True
    , layout = True
    , showNavbar = True
    , dashboardLink = True
    , findPath = True
    , layoutManagement = True
    , projectManagement = True
    , sharing = True
    }


embedDefault : ErdConf
embedDefault =
    -- used for embed app
    { fitOnLoad = True
    , fullscreen = True
    , save = False
    , hover = False
    , select = False
    , move = False
    , layout = False
    , showNavbar = False
    , dashboardLink = False
    , findPath = False
    , layoutManagement = False
    , projectManagement = False
    , sharing = False
    }
