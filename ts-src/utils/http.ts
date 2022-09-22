import {ZodType} from "zod/lib/types";
import * as Zod from "./zod";

export const getJson = <Response>(url: string, zod: ZodType<Response>): Promise<Response> => fetch(url, {credentials: 'include'}).then(buildJsonResponse(zod))
export const postJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>): Promise<Response> => fetchJson('POST', url, body, zod)
export const postMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>): Promise<Response> => fetchMultipart('POST', url, body, zod)
export const putJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>): Promise<Response> => fetchJson('PUT', url, body, zod)
export const putMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>): Promise<Response> => fetchMultipart('PUT', url, body, zod)
export const deleteNoContent = (url: string): Promise<void> => fetch(url, {method: 'DELETE', credentials: 'include'}).then(buildNoContentResponse)


type Method = 'GET' | 'POST' | 'PUT' | 'DELETE'

function fetchJson<Body, Response>(method: Method, url: string, body: Body, zod: ZodType<Response>): Promise<Response> {
    return fetch(url, {
        method,
        credentials: 'include',
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: JSON.stringify(body)
    }).then(buildJsonResponse(zod))
}

function fetchMultipart<Response>(method: Method, url: string, body: FormData, zod: ZodType<Response>): Promise<Response> {
    return fetch(url, {
        method,
        credentials: 'include',
        body: body
    }).then(buildJsonResponse(zod))
}

const buildJsonResponse = <T>(zod: ZodType<T>) => (res: Response): Promise<T> =>
    res.ok ? res.json().then(v => Zod.validate(v, zod)) : res.json().then(Promise.reject)
const buildNoContentResponse = (res: Response): Promise<void> =>
    res.ok ? Promise.resolve() : res.json().then(Promise.reject)
