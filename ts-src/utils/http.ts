export function getJson<Response>(url: string): Promise<JsonResponse<Response>> {
    return fetch(url).then(buildJsonResponse<Response>)
}

export function postJson<Body, Response>(url: string, body: Body): Promise<JsonResponse<Response>> {
    return fetch(url, {
        method: 'POST',
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: JSON.stringify(body)
    }).then(buildJsonResponse<Response>)
}

export function deleteJson<Response>(url: string): Promise<JsonResponse<Response>> {
    return fetch(url, {method: 'DELETE'}).then(buildJsonResponse<Response>)
}

export function deleteNoContent(url: string): Promise<NoContentResponse> {
    return fetch(url, {method: 'DELETE'}).then(buildNoContentResponse)
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
