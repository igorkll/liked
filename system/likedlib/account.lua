local registry = require("registry")
local internet = require("internet")
local json = require("json")
local graphic = require("graphic")
local apps = require("apps")
local lastinfo = require("lastinfo")
local account = {}

local host = "http://127.0.0.1"
local regHost = host .. "/likeID/reg/"
local unregHost = host .. "/likeID/unreg/"
local changePasswordHost = host .. "/likeID/changePassword/"
local getTokenHost = host .. "/likeID/getToken/"
local checkTokenHost = host .. "/likeID/checkToken/"
local userExistsHost = host .. "/likeID/userExists/"
local getLockedHost = host .. "/likeID/getLocked/"
local detachHost = host .. "/likeID/detach/"

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

function account.deviceId()
    for uuid, value in pairs(lastinfo.deviceinfo) do
        if value.class == "processor" then
            return uuid
        end
    end
end

function account.check()
    if registry.account then
        if not post(userExistsHost, {name = registry.account}) then
            registry.accountToken = nil
            registry.account = nil
        end
    end
end

function account.updateToken(name, password)
    local ok, tokenOrError = post(getTokenHost, {name = name, password = password, device = account.deviceId()})
    if ok then
        registry.accountToken = tokenOrError
        return true
    else
        return nil, tokenOrError
    end
end

function account.checkToken()
    return registry.account and registry.accountToken and (post(checkTokenHost, {name = registry.account, token = registry.accountToken}))
end

function account.getStorage()
    if not registry.account then return end
    local proxy = require("component").proxy(require("computer").tmpAddress())
    proxy.cloud = true
    return proxy
end

function account.loginWindow(screen)
    account.check()
    account.loginWindowOpenFlag = true
    local window = graphic.createWindow(screen)
    assert(apps.execute("/system/bin/setup.app/inet.lua", screen, nil, window, true))
    account.loginWindowOpenFlag = nil
end

--------------------------------

local function getLocked()
    if not registry.account then return end
    local ok, data = post(getLockedHost, {device = account.deviceId()})
    if ok then
        return data
    end
end

function account.getLocked() --получает с сервера, на какую учетную запись заблокировано устройтсво
    local data = getLocked()
    if data and data:sub(1, 1) == "0" then
        return data:sub(2, #data)
    end
end

function account.isBricked()
    local data = getLocked()
    return data and data:sub(1, 1) == "1"
end

function account.getLogin()
    return registry.account
end

function account.login(name, password)
    local ok, err = account.updateToken(name, password)

    if ok then
        registry.account = name
        return true, "you have successfully login to your account"
    end

    return false, err
end

function account.unlogin(password)
    if not registry.account then
        return false, "you are not logged in to account"
    end

    local ok, err = post(detachHost, {name = registry.account, password = password, device = account.deviceId()})
    if ok then
        registry.account = nil
        registry.accountPassword = nil
        return true, "you have successfully logout from your account"
    else
        return nil, err
    end
end

function account.register(name, password)
    return post(regHost, {name = name, password = password})
end

function account.unregister(name, password)
    local ok, err = post(unregHost, {name = name, password = password})
    if ok then
        account.unlogin(password)
    end
    return ok, err
end

function account.changePassword(name, password, newPassword)
    return post(unregHost, {name = name, password = password, newPassword = newPassword})
end

account.unloadable = true
return account