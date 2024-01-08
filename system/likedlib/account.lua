local registry = require("registry")
local internet = require("internet")
local json = require("json")
local account = {}

local host = "http://127.0.0.1"
local regHost = host .. "/likeID/reg/"
local unregHost = host .. "/likeID/unreg/"
local changePasswordHost = host .. "/likeID/changePassword/"

--------------------------------

function account.getToken(name, password)
    return "test"
end

function account.checkToken(token)
    return true
end

function account.getStorage()
    if not registry.account then return end
    local proxy = require("component").proxy(require("computer").tmpAddress())
    proxy.cloud = true
    return proxy
end

--------------------------------

function account.getLocked() --получает с сервера, на какую учетную запись заблокировано устройтсво
    return
end

function account.getLogin()
    return registry.account
end

function account.login(name, password)
    if registry.account then
        return "log out from another account first"
    end

    registry.account = name
    registry.accountPassword = password
    return "you have successfully logged in to your account"
end

function account.unlogin(password)
    if not registry.account then
        return "you are not logged in to account"
    end

    if password == registry.accountPassword then
        registry.account = nil
        registry.accountPassword = nil
        return "you have successfully logged out from your account"
    else
        return "invalid password"
    end
end

function account.register(name, password)
    local card = internet.cardProxy()
    local userdata = card.request(regHost, json.encode({name = name, password = password}))
    return tostring(internet.readAll(userdata))
end

function account.unregister(name, password)
    local card = internet.cardProxy()
    local userdata = card.request(unregHost, json.encode({name = name, password = password}))
    return tostring(internet.readAll(userdata))
end

account.unloadable = true
return account