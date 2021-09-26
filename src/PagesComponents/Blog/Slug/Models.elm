module PagesComponents.Blog.Slug.Models exposing (Content, Model(..))

import Http
import Libs.Nel exposing (Nel)


type Model
    = Loading
    | BadSlug Http.Error
    | BadContent (Nel String)
    | Loaded Content


type alias Content =
    { category : Maybe String
    , title : String
    , author : String
    , body : String
    , tags : List String
    , excerpt : String
    }
