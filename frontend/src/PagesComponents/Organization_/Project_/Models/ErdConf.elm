module PagesComponents.Organization_.Project_.Models.ErdConf exposing (ErdConf, default, embedDefault)


type alias ErdConf =
    { fitOnLoad : Bool -- to run fit to screen on project load
    , fullscreen : Bool -- to allow fullscreen button
    , save : Bool -- to allow to save the project
    , hover : Bool -- to be responsive to the hover (column & link highlight)
    , select : Bool -- to allow to select tables
    , move : Bool -- to allow to move tables
    , layout : Bool -- to allow to update the current layout
    , update : Bool -- to enable AML sources button
    , showNavbar : Bool -- to show navbar
    , dashboardLink : Bool -- if top left Azimutt link send to home or landing page
    , findPath : Bool -- to allow find path feature
    , layoutManagement : Bool -- to allow to create & change layouts
    , projectManagement : Bool -- to allow to change, update or create projects
    , sharing : Bool -- to display embed button
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
    , update = True
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
    , update = False
    , showNavbar = False
    , dashboardLink = False
    , findPath = False
    , layoutManagement = False
    , projectManagement = False
    , sharing = False
    }
