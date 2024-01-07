local registry = require("registry")
local account = {}

--------------------------------

function account.getToken(name, password)
    return "test"
end

function account.checkToken(token)
    return true
end

--------------------------------

function account.getLocked() --получает с сервера, на какую учетную запись заблокировано устройтсво
    return registry.account
end

function account.getLogin()
    return registry.account
end

function account.login(name, password)
    if registry.account then
        return nil, "log out from another account first"
    end

    registry.account = name
    return true
end

function account.unlogin()
    if not registry.account then
        return nil, "you are not logged in to account"
    end

    registry.account = nil
    return true
end

account.unloadable = true
return account