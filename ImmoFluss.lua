-- ImmoFluss-Extension für MoneyMoney
--
-- Zeigt die Immobilien aus ImmoFluss als Depot (Marktwert je Objekt) und jedes
-- Darlehen als Kreditkonto (Restschuld). Damit steht das Immobilienvermögen in
-- MoneyMoney neben Girokonto und Wertpapierdepot.
--
-- Zugang: persönlicher API-Key aus der ImmoFluss-App
-- (Konto → Integrationen → API-Keys). Nur lesend, Pro oder Ultra.
-- Die Zahlen kommen aus GET /api/v1/net-worth und sind dieselben wie in der App.

WebBanking {
  version = 1.00,
  url = "https://app.immo-fluss.de",
  services = {"ImmoFluss"},
  description = "Immobilien und Darlehen aus ImmoFluss"
}

local API = "https://app.immo-fluss.de/api/v1"
local PORTFOLIO_NUMBER = "immofluss-immobilien"
local LOAN_PREFIX = "immofluss-kredit-"

local connection
local apiKey
local netWorth -- pro Sitzung einmal laden, spart Tageskontingent

local function get(path)
  local headers = {
    ["Accept"] = "application/json",
    ["Authorization"] = "Bearer " .. apiKey,
  }
  local content = connection:request("GET", API .. path, nil, nil, headers)
  return JSON(content):dictionary()
end

local function errorText(response)
  if response["message"] then
    return response["message"]
  end
  return "ImmoFluss meldet einen Fehler (" .. tostring(response["error"]) .. ")."
end

local function loadNetWorth()
  if netWorth == nil then
    local response = get("/net-worth")
    if response["error"] then
      return nil, errorText(response)
    end
    netWorth = response
  end
  return netWorth
end

local function parseDate(iso)
  local y, m, d = string.match(iso or "", "^(%d+)-(%d+)-(%d+)")
  if not y then
    return nil
  end
  return os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12})
end

local function loanName(loan)
  local name = "Darlehen " .. (loan["bank"] or loan["name"] or "")
  if loan["propertyName"] then
    name = name .. " (" .. loan["propertyName"] .. ")"
  end
  return name
end

function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "ImmoFluss"
end

function InitializeSession(protocol, bankCode, username, customer, password, credential)
  -- Der Key darf in einem der beiden Felder stehen; das andere Feld ist frei
  -- (z. B. die E-Mail-Adresse, nur zur Anzeige in MoneyMoney).
  if string.sub(password or "", 1, 7) == "imf_sk_" then
    apiKey = password
  elseif string.sub(username or "", 1, 7) == "imf_sk_" then
    apiKey = username
  else
    return "Bitte trage deinen ImmoFluss-API-Key (beginnt mit imf_sk_) als Passwort ein. " ..
      "Du findest ihn in der App unter Konto → Integrationen → API-Keys."
  end

  connection = Connection()
  netWorth = nil

  local status = get("/status")
  if status["error"] == "unauthorized" or status["error"] == "account_not_found" then
    return LoginFailed
  end
  if status["error"] then
    return errorText(status)
  end
  if status["tier"] == "free" then
    return "Die Anbindung an MoneyMoney ist in ImmoFluss Pro und Ultra enthalten. " ..
      "Du kannst in der App unter Profil → Abo upgraden."
  end
  return nil
end

function ListAccounts(knownAccounts)
  local data, err = loadNetWorth()
  if not data then
    return err
  end

  local accounts = {{
    name = "ImmoFluss Immobilien",
    accountNumber = PORTFOLIO_NUMBER,
    portfolio = true,
    currency = "EUR",
    type = AccountTypePortfolio,
  }}
  for _, loan in ipairs(data["loans"] or {}) do
    table.insert(accounts, {
      name = loanName(loan),
      accountNumber = LOAN_PREFIX .. loan["id"],
      currency = "EUR",
      type = AccountTypeLoan,
    })
  end
  return accounts
end

function RefreshAccount(account, since)
  local data, err = loadNetWorth()
  if not data then
    return err
  end

  if account.accountNumber == PORTFOLIO_NUMBER then
    local securities = {}
    for _, property in ipairs(data["properties"] or {}) do
      table.insert(securities, {
        name = property["name"],
        quantity = 1,
        purchasePrice = property["purchasePriceEur"],
        currencyOfPurchasePrice = "EUR",
        price = property["currentValueEur"],
        currencyOfPrice = "EUR",
        amount = property["currentValueEur"],
        tradeTimestamp = parseDate(property["purchaseDate"]),
      })
    end
    return {securities = securities}
  end

  for _, loan in ipairs(data["loans"] or {}) do
    if account.accountNumber == LOAN_PREFIX .. loan["id"] then
      return {balance = -loan["remainingDebtEur"], transactions = {}}
    end
  end
  return "Dieses Darlehen gibt es in ImmoFluss nicht mehr. Du kannst das Konto in MoneyMoney löschen."
end

function EndSession()
  netWorth = nil
  return nil
end
