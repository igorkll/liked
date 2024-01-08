local registry = require("registry")
local account = {}

--------------------------------

function account.getToken(name, password)
    return "test"
end

function account.checkToken(token)
    return true
end

function account.getStorage()
    local proxy = require("component").proxy(require("computer").tmpAddress())
    proxy.cloud = true
    return proxy
end

--------------------------------

function account.getLocked() --получает с сервера, на какую учетную запись заблокировано устройтсво
    return registry.account or "QWE"
end

function account.getLogin()
    return registry.account
end

function account.login(name, password)
    if registry.account then
        return nil, "log out from another account first"
    end

    registry.account = name
    registry.accountPassword = password
    return true
end

function account.unlogin(password)
    if not registry.account then
        return nil, "you are not logged in to account"
    end

    if password == registry.accountPassword then
        registry.account = nil
        registry.accountPassword = nil
        return true
    else
        return nil, "invalid password"
    end
end

function account.register(name, password)

end

function account.unregister(name, password)

end

account.unloadable = true
return account