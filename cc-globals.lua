--- @class fs
fs = {}

--- @class http
http = {}

--- @class peripheral
peripheral = {}

--- @class sleep
function sleep(seconds) end

--- @type fun(url: string): table | nil
http.get = function(url) return nil end

--- @type fun(path: string): boolean
fs.exists = function(path) return false end

--- @type fun(path: string, mode: string): table | nil
fs.open = function(path, mode) return nil end

--- @type fun(path: string)
fs.makeDir = function(path) end

--- @type fun(nameOrObj: string): string | nil
peripheral.getType = function(nameOrObj) return nil end

--- @type fun(): string[]
peripheral.getNames = function() return {} end

--- @type fun(name: string): table | nil
peripheral.wrap = function(name) return nil end

--- @type fun(nameOrObj: string, method: string, ...: any): any
peripheral.call = function(nameOrObj, method, ...) return nil end

--- @class term
term = {}

--- @type fun()
term.clear = function() end

--- @type fun(x: number, y: number)
term.setCursorPos = function(x, y) end

--- @class textutils
textutils = {}

--- @type fun(obj: any): string
textutils.serialize = function(obj) return "" end

--- @type fun(str: string): any
textutils.unserialize = function(str) return nil end

--- @class os
os = {}

--- @type fun(event: string?): any
os.pullEvent = function(event) return nil end
