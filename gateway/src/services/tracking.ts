import fetch from "node-fetch";
import crypto from "node:crypto";

export async function track(name: string, details: object, instance: string, environment: string = 'prod'): Promise<void> {
    return await fetch('https://cockpit.azimutt.app/api/events', {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            id: crypto.randomUUID(),
            instance,
            environment,
            name,
            details,
            createdAt: new Date().toISOString()
        })
    }).then(() => {}, () => {})
}
