# ImmoFluss für MoneyMoney

Diese Extension holt deine Immobilien und Darlehen aus [ImmoFluss](https://www.immo-fluss.de) in [MoneyMoney](https://moneymoney.app).

- **Immobilien** erscheinen als Depot „ImmoFluss Immobilien“: je Objekt der aktuelle Marktwert, dazu Kaufpreis und Kaufdatum.
- **Darlehen** erscheinen als Kreditkonten mit der aktuellen Restschuld.

So siehst du dein Netto-Vermögen inklusive Immobilien an einer Stelle. Die Zahlen sind dieselben wie in der ImmoFluss-App (gleiche Bewertung, gleiche Restschuld-Berechnung).

## Voraussetzungen

- ImmoFluss Pro oder Ultra
- Ein persönlicher API-Key: in der ImmoFluss-App unter **Konto → Integrationen → API-Keys** erstellen. Lesezugriff reicht.

## Installation

1. [`ImmoFluss.lua`](https://raw.githubusercontent.com/finnjung/moneymoney-immofluss/main/ImmoFluss.lua) herunterladen.
2. In MoneyMoney **Hilfe → Datenbank im Finder zeigen** wählen und die Datei in den Ordner `Extensions` legen.
3. Solange die Extension noch nicht von MoneyMoney signiert ist: **Einstellungen → Erweiterungen** öffnen und „Digitale Signatur von Extensions überprüfen“ ausschalten.
4. **Konto → Konto hinzufügen → Andere** wählen und den Dienst **ImmoFluss** suchen.
5. Als Benutzername deine E-Mail-Adresse eintragen (nur zur Anzeige), als Passwort den API-Key (`imf_sk_…`).

Neue Darlehen, die du später in ImmoFluss anlegst, holst du über **Konto → Konten hinzufügen** für den bestehenden Zugang dazu.

## Datenschutz

Die Extension liest nur und überträgt nichts an Dritte. Sie ruft ausschließlich `https://app.immo-fluss.de/api/v1/status` und `/net-worth` auf. Der API-Key liegt verschlüsselt in MoneyMoney und lässt sich in der ImmoFluss-App jederzeit widerrufen.

## Entwicklung

- Die Extension nutzt die öffentliche ImmoFluss-REST-API: `GET /api/v1/status` und `GET /api/v1/net-worth` (Spezifikation: https://app.immo-fluss.de/api/v1/openapi.json).
- Test ohne MoneyMoney: `lua test_extension.lua` (stellt die MoneyMoney-API nach).
- Fragen und Fehler: Issue hier im Repo oder info@immo-fluss.de.

## Lizenz

MIT
