import {FileUrl, Uuid} from "./basics";

export type UserRole = string // ex: authenticated
export type AuthProvider = string // ex: github
export interface User {
    id: Uuid
    username: string
    name: string
    email: string | undefined
    avatar: FileUrl
    role: UserRole | undefined
    provider: AuthProvider | undefined
}
