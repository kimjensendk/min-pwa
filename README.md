# Hotel Sportsbooking PWA med Supabase-backend

Denne version bruger Supabase/Postgres som fælles backend, så bookinger kan ses på tværs af gæsternes telefoner.

## Filer

- `index.html` - selve appen
- `config.js` - Supabase URL og public key
- `schema.sql` - database, tabeller, view, policies og funktioner
- `manifest.json` - PWA metadata
- `service-worker.js` - offline/cache
- `icon.svg` - appikon

## Opsætning

1. Opret et projekt på https://supabase.com
2. Åbn Supabase SQL Editor
3. Kør hele `schema.sql`
4. Find din Supabase URL og public/publishable key
5. Åbn `config.js` og udfyld:

```js
const SUPABASE_URL = "https://DIN-PROJEKT-ID.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "DIN_PUBLIC_KEY_HER";
```

6. Upload filerne til GitHub
7. Aktivér GitHub Pages

## Vigtigt om sikkerhed

- Brug kun Supabase publishable key / anon public key i `config.js`
- Brug aldrig secret key eller service_role key i frontend
- Cancellation codes gemmes lokalt i gæstens browser
- En gæst kan kun afbooke den booking fra samme browser/enhed, hvor bookingen blev lavet

## Begrænsninger i denne prototype

- Ingen login
- Ingen administrationsside
- Alle gæster kan se navne og værelsesnumre på bookinger
- Aktiviteter oprettes i databasen via SQL

Til rigtig produktion bør der tilføjes:
- admin-login
- bedre GDPR/privacy-model
- mulighed for at hotellet kan oprette aktiviteter i en admin-skærm
- rate limiting / spam-beskyttelse
