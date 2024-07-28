export async function aesEncrypt(key: string, text: string): Promise<string> {
    const textBuffer = new TextEncoder().encode(text)
    const iv = crypto.getRandomValues(new Uint8Array(12))

    const cryptoKey = await aesImportKey(key)
    const cipherBuffer = await crypto.subtle.encrypt({name: 'AES-GCM', iv}, cryptoKey, textBuffer)

    const combinedBuffer = new Uint8Array(iv.length + cipherBuffer.byteLength)
    combinedBuffer.set(iv, 0)
    combinedBuffer.set(new Uint8Array(cipherBuffer), iv.length)

    return base64Encode(String.fromCharCode(...combinedBuffer))
}

export async function aesDecrypt(key: string, secret: string): Promise<string> {
    const combinedBuffer = Uint8Array.from(base64Decode(secret), c => c.charCodeAt(0))
    const iv = combinedBuffer.slice(0, 12)
    const cipherBuffer = combinedBuffer.slice(12)

    const cryptoKey = await aesImportKey(key)
    const decryptedBuffer = await crypto.subtle.decrypt({name: 'AES-GCM', iv: iv}, cryptoKey, cipherBuffer)

    return new TextDecoder().decode(decryptedBuffer)
}

// key should be 32 char
function aesImportKey(key: string, strict: boolean = true): Promise<CryptoKey> {
    let keyBuffer: Uint8Array
    if (strict) {
        keyBuffer = new TextEncoder().encode(key)
    } else {
        keyBuffer = new Uint8Array(32)
        keyBuffer.set(new TextEncoder().encode(key).slice(0, 32))
    }
    return crypto.subtle.importKey('raw', keyBuffer, {name: 'AES-GCM', length: 256}, true, ['encrypt', 'decrypt'])
}

async function aesExportKey(key: CryptoKey): Promise<string> {
    const keyBuffer = await crypto.subtle.exportKey('raw', key)
    return base64Encode(String.fromCharCode(...new Uint8Array(keyBuffer)))
}

export async function aesRandomKey(): Promise<string> {
    const key: CryptoKey = await crypto.subtle.generateKey({name: 'AES-GCM', length: 256}, true, ['encrypt', 'decrypt'])
    return aesExportKey(key)
}

export function base64Encode(plaintext: string): string {
    return btoa(plaintext)
}

export function base64Decode(base64: string): string {
    return atob(base64)
}

export function base64Valid(text: string): boolean {
    return !!text.match(/^[a-zA-Z0-9+/]+={0,2}$/g) && text.length % 4 === 0
}
