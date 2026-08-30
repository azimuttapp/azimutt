export function loadIntlDate(): void {
    customElements.define('intl-date', IntlDate)
}

// example from https://guide.elm-lang.org/interop/custom_elements
//
//   <intl-date lang="sr-RS" year="2012" month="5">
//   <intl-date lang="en-GB" year="2012" month="5">
//   <intl-date lang="en-US" year="2012" month="5">
//
class IntlDate extends HTMLElement {
    constructor() {
        super()
    }

    connectedCallback() {
        this.setTextContent()
    }

    attributeChangedCallback() {
        this.setTextContent()
    }

    static get observedAttributes() {
        return ['lang', 'year', 'month']
    }

    // Our function to set the textContent based on attributes.
    setTextContent() {
        const lang: string | null = this.getAttribute('lang')
        const yearStr: string | null = this.getAttribute('year')
        const monthStr: string | null = this.getAttribute('month')
        if (lang === null) {
            this.textContent = 'missing "lang" parameter'
        } else if (yearStr === null) {
            this.textContent = 'missing "year" parameter'
        } else if (monthStr === null) {
            this.textContent = 'missing "month" parameter'
        } else if (lang.match(/^[a-z]{2}-[A-Z]{2}$/) === null) {
            this.textContent = 'invalid value for "lang" parameter'
        } else if (yearStr.match(/^\d+$/) === null) {
            this.textContent = 'invalid value for "year" parameter'
        } else if (monthStr.match(/^\d+$/) === null) {
            this.textContent = 'invalid value for "month" parameter'
        } else {
            this.textContent = localizeDate(lang, parseInt(yearStr), parseInt(monthStr))
        }
    }
}

//
//   localizeDate('sr-RS', 12, 5) === "петак, 1. јун 2012."
//   localizeDate('en-GB', 12, 5) === "Friday, 1 June 2012"
//   localizeDate('en-US', 12, 5) === "Friday, June 1, 2012"
//
function localizeDate(lang: string, year: number, month: number): string {
    const dateTimeFormat = new Intl.DateTimeFormat(lang, {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    })

    return dateTimeFormat.format(new Date(year, month))
}
