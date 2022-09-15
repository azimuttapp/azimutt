import {SupabaseClient} from "@supabase/supabase-js";
import {ProjectId, ProjectInfoNoStorage, ProjectNoStorage} from "../types/project";
import {Profile, UserId} from "../types/profile";
import {User as SupabaseUser} from "@supabase/gotrue-js/src/lib/types";
import {Email} from "../types/basics";
import jiff from "jiff";

export class SupabaseStorage {
    private projects: { [id: ProjectId]: ProjectNoStorage } = {}

    constructor(private supabase: SupabaseClient, private baseUrl: string) {
    }

    getProfile = async (id: UserId): Promise<Profile> => this.get<Profile>(`/users/${id}`)
    fetchProfile = async (email: Email): Promise<Profile> => this.get<Profile>(`/users/fetch?email=${encodeURIComponent(email)}`)
    updateProfile = async (profile: Profile): Promise<void> => this.put(`/users/${profile.id}`, {
        username: profile.username,
        name: profile.name,
        avatar: profile.avatar || null,
        bio: profile.bio || null,
        company: profile.company || null,
        location: profile.location || null,
        website: profile.website || null,
        github: profile.github || null,
        twitter: profile.twitter || null,
    })
    createProfile = async (user: SupabaseUser): Promise<Profile> => {
        if (!user.email) return Promise.reject('missing email')
        const profile = {
            id: user.id,
            email: user.email,
            username: user.user_metadata.user_name || user.email.split('@')[0],
            name: user.user_metadata.name || user.email.split('@')[0],
            avatar: user.user_metadata.avatar_url,
            bio: null,
            company: null,
            location: null,
            website: null,
            github: null,
            twitter: null
        }
        return this.post(`/users`, profile).then(_ => profile)
    }
    getOrCreateProfile = async (user: SupabaseUser): Promise<Profile> => this.getProfile(user.id).catch(_ => this.createProfile(user))


    getProjects = (): Promise<ProjectInfoNoStorage[]> => this.get<ProjectInfoNoStorage[]>(`/projects`)
    getProject = async (id: ProjectId): Promise<ProjectNoStorage> => {
        const project = await this.get<ProjectNoStorage>(`/projects/${id}`)
        this.projects[id] = project
        return project
    }
    createProject = async (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        if (isSample(id)) return Promise.reject("Sample projects can't be uploaded!")
        await this.post(`/projects`, {
            id: id,
            name: p.name,
            tables: 0,
            relations: 0,
            layouts: Object.keys(p.layouts).length,
            project: p
        })
        this.projects[id] = p
        return p
    }
    updateProject = async (id: ProjectId, p: ProjectNoStorage): Promise<ProjectNoStorage> => {
        const initial = this.projects[id]
        const current = await this.get<ProjectNoStorage>(`/projects/${id}`)
        if (initial.updatedAt !== current.updatedAt) {
            try {
                const patch = jiff.diff(initial, p)
                p = jiff.patch(patch, current)
            } catch (e) {
                console.warn('patch failed', e)
                return Promise.reject("Project has been updated by another user! Please reload and save again (you will have to do you changes again).")
            }
        }
        await this.put(`/projects/${id}`, {
            id: id,
            name: p.name,
            tables: 0,
            relations: 0,
            layouts: Object.keys(p.layouts).length,
            project: p
        })
        this.projects[id] = p
        return p
    }
    dropProject = async (id: ProjectId): Promise<void> => {
        await this.delete(`/projects/${id}`)
        delete this.projects[id]
    }

    getOwners = async (id: ProjectId): Promise<Profile[]> => this.get(`/projects/${id}/owners`)
    setOwners = async (id: ProjectId, owners: UserId[]): Promise<Profile[]> => this.put(`/projects/${id}/owners`, owners).then(_ => this.getOwners(id))

    private get = <T>(path: string): Promise<T> => this.fetch('GET', path)
    private post = <T>(path: string, body: object): Promise<T> => this.fetch('POST', path, body)
    private put = <T>(path: string, body: object): Promise<T> => this.fetch('PUT', path, body)
    private delete = <T>(path: string): Promise<T> => this.fetch('DELETE', path)

    private fetch<T>(method: string, path: string, body?: object): Promise<T> {
        const token = this.supabase.auth.session()?.access_token
        if (token) {
            const init: RequestInit = body ? {
                method,
                headers: {Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'},
                body: JSON.stringify(body)
            } : {
                method,
                headers: {Authorization: `Bearer ${token}`},
            }
            return fetch(`${this.baseUrl}${path}`, init).then(async res => {
                let text = await res.text()
                let json: any
                try {
                    json = JSON.parse(text)
                } catch (e) {
                    json = text
                }
                return res.ok ? json as T : Promise.reject(json.message || JSON.stringify(json))
            })
        } else {
            return Promise.reject('not connected')
        }
    }
}

function isSample(id: ProjectId): boolean {
    return id.startsWith('0000')
}
