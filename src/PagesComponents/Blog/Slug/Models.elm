module PagesComponents.Blog.Slug.Models exposing (Content, Model(..))

import Http
import Libs.Nel exposing (Nel)


type Model
    = Loading
    | BadSlug Http.Error
    | BadContent (Nel String)
    | Loaded Content


type alias Content =
    { title : String
    , excerpt : String
    , category : Maybe String
    , tags : List String
    , author : String
    , published : String
    , body : String
    }
