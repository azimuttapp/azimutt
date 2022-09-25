import {ZodType} from "zod/lib/types";
import * as Zod from "./zod";
import * as Json from "./json";

export const getJson = <Response>(url: string, zod: ZodType<Response>, label: string): Promise<Response> => fetch(url, {credentials: 'include'}).then(buildJsonResponse(zod, label))
export const postJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>, label: string): Promise<Response> => fetchJson('POST', url, body, zod, label)
export const postMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>, label: string): Promise<Response> => fetchMultipart('POST', url, body, zod, label)
export const putJson = <Body, Response>(url: string, body: Body, zod: ZodType<Response>, label: string): Promise<Response> => fetchJson('PUT', url, body, zod, label)
export const putMultipart = <Response>(url: string, body: FormData, zod: ZodType<Response>, label: string): Promise<Response> => fetchMultipart('PUT', url, body, zod, label)
export const deleteNoContent = (url: string): Promise<void> => fetch(url, {method: 'DELETE', credentials: 'include'}).then(buildNoContentResponse)


type Method = 'GET' | 'POST' | 'PUT' | 'DELETE'

function fetchJson<Body, Response>(method: Method, url: string, body: Body, zod: ZodType<Response>, label: string): Promise<Response> {
    return fetch(url, {
        method,
        credentials: 'include',
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: JSON.stringify(body)
    }).then(buildJsonResponse(zod, label))
}

function fetchMultipart<Response>(method: Method, url: string, body: FormData, zod: ZodType<Response>, label: string): Promise<Response> {
    return fetch(url, {
        method,
        credentials: 'include',
        body: body
    }).then(buildJsonResponse(zod, label))
}

const buildJsonResponse = <T>(zod: ZodType<T>, label: string) => (res: Response): Promise<T> =>
    res.ok ? res.text().then(v => Zod.validate(Json.parse(v), zod, label)) : res.text().then(err => Promise.reject(Json.parse(err)))
const buildNoContentResponse = (res: Response): Promise<void> =>
    res.ok ? Promise.resolve() : res.text().then(err => Promise.reject(Json.parse(err)))
