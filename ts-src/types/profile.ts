import {Email, FileUrl, Username} from "./basics";
import {Uuid} from "./uuid";

export type UserId = Uuid
// TODO delete!
export interface Profile {
    id: UserId
    username: Username
    email: Email
    name: string
    avatar: FileUrl | null
    bio: string | null
    company: string | null
    location: string | null
    website: string | null
    github: string | null
    twitter: string | null
}
