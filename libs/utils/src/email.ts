export type EmailParsed = {full: string, domain?: string}

export function emailParse(email: string): EmailParsed {
    const [, domain] = email.match(/^[^\s@]+@([^\s@]+\.[^\s@]+)$/) || []
    return {full: email, domain}
}

// https://email-verify.my-addr.com/list-of-most-popular-email-domains.php
export const publicEmailDomains = [
    'aol.com',
    'fastmail.com',
    'gmail.com',
    'hotmail.co.uk',
    'hotmail.com',
    'hotmail.fr',
    'icloud.com',
    'mail.ru',
    'mail.com',
    'msn.com',
    'orange.fr',
    'outlook.com',
    'outlook.fr',
    'protonmail.com',
    'wanadoo.fr',
    'yahoo.com',
    'yahoo.fr',
    'yandex.com',
    'yandex.ru',
    'zoho.com',
]
