local registry = require("registry")
local internet = require("internet")
local json = require("json")
local graphic = require("graphic")
local apps = require("apps")
local account = {}

local host = "http://127.0.0.1"
local regHost = host .. "/likeID/reg/"
local unregHost = host .. "/likeID/unreg/"
local changePasswordHost = host .. "/likeID/changePassword/"
local getTokenHost = host .. "/likeID/getToken/"
local checkTokenHost = host .. "/likeID/checkToken/"
local userExistsHost = host .. "/likeID/userExists/"

local function post(lhost, data)
    if type(data) == "table" then
        data = json.encode(data)
    end

    local card = internet.cardProxy()
    local userdata = card.request(lhost, data)
    local ok, err = internet.wait(userdata)
    if not ok then
        return err
    end

    local code = userdata.response()
    return code == 200, internet.readAll(userdata)
end
account._raw_post = post

--------------------------------

function account.check()
    if registry.account then
        if not post(userExistsHost, {name = registry.account}) then
            registry.accountToken = nil
            registry.account = nil
        end
    end
end

function account.updateToken(name, password)
    local ok, tokenOrError = post(getTokenHost, {name = name, password = password})
    if ok then
        registry.accountToken = tokenOrError
        return true
    else
        return nil, tokenOrError
    end
end

function account.checkToken()
    return false
end

function account.getStorage()
    if not registry.account then return end
    local proxy = require("component").proxy(require("computer").tmpAddress())
    proxy.cloud = true
    return proxy
end

function account.isBricked()
    
end

function account.loginWindow(screen)
    account.check()
    account.loginWindowOpenFlag = true
    local window = graphic.createWindow(screen)
    assert(apps.execute("/system/bin/setup.app/inet.lua", screen, nil, window, true))
    account.loginWindowOpenFlag = nil
end

--------------------------------

function account.getLocked() --получает с сервера, на какую учетную запись заблокировано устройтсво
    return
end

function account.getLogin()
    return registry.account
end

function account.login(name, password)
    if account.updateToken(name, password) then
        registry.account = name
        return true, "you have successfully login to your account"
    end

    return false, "failed to get a token"
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
    return post(regHost, {name = name, password = password})
end

function account.unregister(name, password)
    return post(unregHost, {name = name, password = password})
end

function account.changePassword(name, password, newPassword)
    return post(unregHost, {name = name, password = password, newPassword = newPassword})
end

account.unloadable = true
return account