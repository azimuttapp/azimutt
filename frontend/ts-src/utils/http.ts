import {ZodType} from "zod";
import {zodParse} from "@azimutt/models";
import * as Json from "./json";

export const getJson = <Response>(url: string, zod: ZodType<Response>, headers?: RequestInit): Promise<Response> => customFetch('GET', url, undefined, zod, headers)
export const postJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>): Promise<Response> => customFetch('POST', url, body, zod)
export const postNoContent = <Body>(url: string, body: Body): Promise<void> => customFetch('POST', url, body)
export const postMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>): Promise<Response> => customFetch('POST', url, body, zod)
export const putJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>): Promise<Response> => customFetch('PUT', url, body, zod)
export const putMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>): Promise<Response> => customFetch('PUT', url, body, zod)
export const deleteNoContent = (url: string): Promise<void> => customFetch('DELETE', url)

type Method = 'GET' | 'POST' | 'PUT' | 'DELETE'

function customFetch<Body, Response>(method: Method, path: string, body?: Body, zod?: ZodType<Response>, headers?: RequestInit): Promise<Response> {
    const url = path.startsWith('http') ? path : `${window.location.origin}${path}`
    let opts: RequestInit = headers ? headers : {}
    opts = path.startsWith('http') ? {...opts, method} : {...opts, method, credentials: 'include'}
    if (body instanceof FormData) {
        opts = {...opts, body: body}
    } else if (typeof body === 'object' && body !== null) {
        opts = {...opts, body: JSON.stringify(body), headers: {'Accept': 'application/json', 'Content-Type': 'application/json'}}
    }
    return fetch(url, opts).then(r => zod ? buildJsonResponse(zod)(r) : buildNoContentResponse(r))
}

const buildJsonResponse = <T>(zod: ZodType<T>) => (res: Response): Promise<T> =>
    res.ok ? res.text().then(v => zodParse(zod)(Json.parse(v)).toPromise()) : res.text().then(err => Promise.reject(Json.parse(err)))
const buildNoContentResponse = <T>(res: Response): Promise<T> =>
    res.ok ? Promise.resolve() as Promise<T> : res.text().then(err => Promise.reject(Json.parse(err)))
