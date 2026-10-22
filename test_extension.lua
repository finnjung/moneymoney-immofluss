-- Lokaler Test der Extension ohne MoneyMoney: stellt die MoneyMoney-API
-- (WebBanking, Connection, JSON, Konstanten) nach und spielt Antworten ab.
-- Aufruf: lua integrations/moneymoney/test_extension.lua

ProtocolWebBanking, ProtocolFinTS = "webbanking", "fints"
AccountTypePortfolio, AccountTypeLoan = "portfolio", "loan"
LoginFailed = "LOGIN_FAILED"
function WebBanking(_) end

local responses, calls = {}, {}
function Connection()
  return {request = function(_, method, url, _, _, headers)
    table.insert(calls, url)
    assert(headers["Authorization"] == "Bearer imf_sk_test", "Key fehlt im Header")
    return responses[url:match("/api/v1(.*)$")]
  end}
end
function JSON(value) return {dictionary = function() return value end} end

local dir = arg[0]:match("^(.*)/") or "."
dofile(dir .. "/ImmoFluss.lua")

local function check(cond, msg) if not cond then error("FEHLER: " .. msg, 2) end end

responses["/status"] = {tier = "prime"}
responses["/net-worth"] = {
  properties = {{id = "i1", name = "ETW Offenbach", purchasePriceEur = 250000,
    purchaseDate = "2021-03-01", currentValueEur = 310000}},
  loans = {{id = "k1", name = "Annuität", bank = "Sparkasse", propertyName = "ETW Offenbach",
    remainingDebtEur = 180000}},
}

check(SupportsBank(ProtocolWebBanking, "ImmoFluss"), "SupportsBank")
check(not SupportsBank(ProtocolFinTS, "ImmoFluss"), "SupportsBank FinTS")
check(InitializeSession(ProtocolWebBanking, "ImmoFluss", "x@y.de", "", "kein-key") ~= nil, "falscher Key")
check(InitializeSession(ProtocolWebBanking, "ImmoFluss", "x@y.de", "", "imf_sk_test") == nil, "Login")

local accounts = ListAccounts({})
check(#accounts == 2, "2 Konten")
check(accounts[1].type == AccountTypePortfolio and accounts[1].portfolio, "Depot")
check(accounts[2].name == "Darlehen Sparkasse (ETW Offenbach)", "Kreditname: " .. accounts[2].name)

local depot = RefreshAccount(accounts[1], nil)
check(depot.securities[1].amount == 310000 and depot.securities[1].quantity == 1, "Wert")
check(depot.securities[1].purchasePrice == 250000, "Kaufpreis")
check(type(depot.securities[1].tradeTimestamp) == "number", "Kaufdatum")
local loan = RefreshAccount(accounts[2], 0)
check(loan.balance == -180000 and #loan.transactions == 0, "Restschuld")
check(type(RefreshAccount({accountNumber = "immofluss-kredit-weg"}, 0)) == "string", "gelöschter Kredit")

local netWorthCalls = 0
for _, url in ipairs(calls) do if url:find("/net%-worth$") then netWorthCalls = netWorthCalls + 1 end end
check(netWorthCalls == 1, "net-worth nur einmal pro Sitzung, war " .. netWorthCalls)
EndSession()

responses["/status"] = {error = "unauthorized"}
check(InitializeSession(ProtocolWebBanking, "ImmoFluss", "", "", "imf_sk_test") == LoginFailed, "LoginFailed")
responses["/status"] = {tier = "free"}
check(type(InitializeSession(ProtocolWebBanking, "ImmoFluss", "", "", "imf_sk_test")) == "string", "Free-Hinweis")
responses["/status"] = {tier = "ultra"}
responses["/net-worth"] = {error = "upgrade_required", message = "Pro nötig"}
InitializeSession(ProtocolWebBanking, "ImmoFluss", "", "", "imf_sk_test")
check(ListAccounts({}) == "Pro nötig", "Fehlertext durchreichen")

print("Alle Extension-Tests grün")
