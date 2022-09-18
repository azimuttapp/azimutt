export const getJson = <Response>(url: string): Promise<JsonResponse<Response>> => fetch(url, {credentials: 'include'}).then(buildJsonResponse<Response>)
export const postJson = <Body, Response>(url: string, body: Body): Promise<JsonResponse<Response>> => fetchJson('POST', url, body)
export const postMultipart = <Response>(url: string, formData: FormData): Promise<JsonResponse<Response>> => fetchMultipart('POST', url, formData)
export const putJson = <Body, Response>(url: string, body: Body): Promise<JsonResponse<Response>> => fetchJson('PUT', url, body)
export const putMultipart = <Response>(url: string, formData: FormData): Promise<JsonResponse<Response>> => fetchMultipart('PUT', url, formData)
export const deleteJson = <Response>(url: string): Promise<JsonResponse<Response>> => fetch(url, {method: 'DELETE', credentials: 'include'}).then(buildJsonResponse<Response>)
export const deleteNoContent = (url: string): Promise<NoContentResponse> => fetch(url, {method: 'DELETE', credentials: 'include'}).then(buildNoContentResponse)

type Method = 'GET' | 'POST' | 'PUT' | 'DELETE'

function fetchJson<Body, Response>(method: Method, url: string, body: Body): Promise<JsonResponse<Response>> {
    return fetch(url, {
        method,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        credentials: 'include',
        body: JSON.stringify(body)
    }).then(buildJsonResponse<Response>)
}

function fetchMultipart<Response>(method: Method, url: string, formData: FormData): Promise<JsonResponse<Response>> {
    return fetch(url, {
        method,
        credentials: 'include',
        body: formData
    }).then(buildJsonResponse<Response>)
}

interface NoContentResponse {
    type: string
    url: string
    ok: boolean
    status: number
    statusText: string
    redirected: boolean
}

function buildNoContentResponse(res: Response): Promise<NoContentResponse> {
    if (res.ok) {
        return Promise.resolve(buildResponse(res))
    } else {
        return res.json().then(json => Promise.reject({...buildResponse(res), json: json}))
    }
}

interface JsonResponse<T> extends NoContentResponse {
    json: T
}

function buildJsonResponse<T>(res: Response): Promise<JsonResponse<T>> {
    return res.json().then(json => {
        const response = {...buildResponse(res), json: json}
        return res.ok ? Promise.resolve(response) : Promise.reject(response)
    })
}

function buildResponse(res: Response): NoContentResponse {
    return {
        type: res.type,
        url: res.url,
        ok: res.ok,
        status: res.status,
        statusText: res.statusText,
        redirected: res.redirected,
    }
}
