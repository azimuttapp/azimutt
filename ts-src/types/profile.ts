import {Email, FileUrl, Username, Uuid} from "./basics";

export type UserId = Uuid
export interface Profile {
    id: UserId
    email: Email
    username: Username
    name: string
    avatar: FileUrl | null
    bio: string | null
    company: string | null
    location: string | null
    website: string | null
    github: string | null
    twitter: string | null
}
