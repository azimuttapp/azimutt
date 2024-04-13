import {zodValidate} from "@azimutt/database-model";
import {ZodType} from "zod/lib/types";
import * as Json from "./json";

export const getJson = <Response>(url: string, zod: ZodType<Response>, label: string): Promise<Response> => customFetch('GET', url, undefined, zod, label)
export const postJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>, label: string): Promise<Response> => customFetch('POST', url, body, zod, label)
export const postNoContent = <Body>(url: string, body: Body): Promise<void> => customFetch('POST', url, body)
export const postMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>, label: string): Promise<Response> => customFetch('POST', url, body, zod, label)
export const putJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>, label: string): Promise<Response> => customFetch('PUT', url, body, zod, label)
export const putMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>, label: string): Promise<Response> => customFetch('PUT', url, body, zod, label)
export const deleteNoContent = (url: string): Promise<void> => customFetch('DELETE', url)

type Method = 'GET' | 'POST' | 'PUT' | 'DELETE'

function customFetch<Body, Response>(method: Method, path: string, body?: Body, zod?: ZodType<Response>, label?: string): Promise<Response> {
    const url = path.startsWith('http') ? path : `${window.location.origin}${path}`
    let opts: RequestInit = path.startsWith('http') ? {method} : {method, credentials: 'include'}
    if (body instanceof FormData) {
        opts = {...opts, body: body}
    } else if (typeof body === 'object' && body !== null) {
        opts = {...opts, body: JSON.stringify(body), headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}}
    }
    return fetch(url, opts).then(r => zod && label ? buildJsonResponse(zod, label)(r) : buildNoContentResponse(r))
}

const buildJsonResponse = <T>(zod: ZodType<T>, label: string) => (res: Response): Promise<T> =>
    res.ok ? res.text().then(v => zodValidate(Json.parse(v), zod, label)) : res.text().then(err => Promise.reject(Json.parse(err)))
const buildNoContentResponse = <T>(res: Response): Promise<T> =>
    res.ok ? Promise.resolve() as Promise<T> : res.text().then(err => Promise.reject(Json.parse(err)))
