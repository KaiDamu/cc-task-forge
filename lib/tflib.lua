defDat = defDat or {}
defDat.cmd = defDat.cmd or {}

onEvt = onEvt or {}
onEvt.sys = onEvt.sys or {}
onEvt.cmd = onEvt.cmd or {}
onEvt.msg = onEvt.msg or {}

local tf = {}

function tf.queueNew()
    return { first = 1, last = 0 }
end

function tf.queueAdd(queue, val)
    queue.last = queue.last + 1
    queue[queue.last] = val
end

function tf.queueGet(queue)
    if queue.first > queue.last then
        return nil
    end
    local val = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return val
end

tf.type = {}
tf.type.INT = 1
tf.type.FLOAT = 2
tf.type.STR = 3
tf.type.LABEL_M = 4
tf.type.LABEL_EX = 5

tf.type.toStr = {
    [tf.type.INT] = "int",
    [tf.type.FLOAT] = "float",
    [tf.type.STR] = "str",
    [tf.type.LABEL_M] = "label_m",
    [tf.type.LABEL_EX] = "label_ex"
}

function tf.type.castStrict(val, type_)
    if type_ == tf.type.INT then
        local num = tonumber(val)
        if num and math.floor(num) == num then
            return num
        else
            return nil
        end
    elseif type_ == tf.type.FLOAT then
        return tonumber(val)
    elseif type_ == tf.type.STR then
        return tostring(val)
    elseif type_ == tf.type.LABEL_M then
        local label, labelSub, labelObj = tf.labelExToLabelDat(tostring(val))
        if label and labelSub and not labelObj then
            return { label, labelSub }
        else
            return nil
        end
    elseif type_ == tf.type.LABEL_EX then
        local label, labelSub, labelObj = tf.labelExToLabelDat(tostring(val))
        if label and labelSub and labelObj then
            return { label, labelSub, labelObj }
        else
            return nil
        end
    else
        return nil
    end
end

tf.ABS_SIDES = { "top", "bottom", "north", "south", "west", "east" }
tf.REL_SIDES = { "top", "bottom", "front", "back", "left", "right" }

tf.SLOT_BOOTS = 100
tf.SLOT_LEGGINGS = 101
tf.SLOT_CHESTPLATE = 102
tf.SLOT_HELMET = 103
tf.SLOT_OFFHAND = 40
tf.SLOTS_ARMOR = { tf.SLOT_BOOTS, tf.SLOT_LEGGINGS, tf.SLOT_CHESTPLATE, tf.SLOT_HELMET }
tf.PERI_TYPE_MODEM_WIRED = "!modem_wired"
tf.PERI_TYPE_MODEM_WIRELESS = "!modem_wireless"
tf.PERI_TYPE_CHAT_BOX = "chat_box"
tf.PERI_TYPE_ME_BRIDGE = "me_bridge"
tf.PERI_TYPE_PLAYER_DET = "player_detector"
tf.PERI_TYPE_INV_MGR = "inventory_manager"
tf.PERI_TYPE_SPEAKER = "speaker"

tf.HUGE = 2147483647
tf.CHAT_CMD_PRE = "."
tf.NET_CH_BROADCAST = 15305
tf.NMSG_HDR = 47619
tf.CHAT_SEND_CD = 0.25

tf.cfg = nil
tf.periNet = nil
tf.pcId = os.getComputerID()
tf.pcLabel = nil
tf.pcLabelSub = nil
tf.pcName = "PC"
tf.pcNetCh = tf.NET_CH_BROADCAST + tf.pcId + 1
tf.mainNetCh = nil
tf.pcLabelMToNetChTab = {}
tf.pcNetChToLabelMTab = {}
tf.evtPrioQueue = tf.queueNew()
tf.chatSendTime = 0.0
tf.conCol = colors.white

function tf.dbgPrint(msg)
    if tf.cfg["isDbg"] then
        print("[DBG] " .. msg)
    end
end

function tf.dbgChat(msg)
    if tf.cfg["isDbg"] then
        tf.chatSend("[DBG] " .. msg)
    end
end

function tf.booln(val)
    if val then
        return 1
    else
        return 0
    end
end

function tf.len(obj)
    local len = #obj or 0
    if len == 0 then
        for _ in pairs(obj) do
            len = len + 1
        end
    end
    return len
end

function tf.arrToStr(arr)
    local ret = "{"
    for i = 1, #arr do
        if i > 1 then
            ret = ret .. ", "
        end
        ret = ret .. tostring(arr[i])
    end
    return ret .. "}"
end

function tf.split(str, c)
    if not str then
        return {}
    end
    local result = {}
    for part in str:gmatch("[^" .. c .. "]+") do
        table.insert(result, part)
    end
    return result
end

function tf.labelToDispName(str)
    return str:gsub("_", " "):gsub("(%a)(%a*)", function(first, rest) return first:upper() .. rest:lower() end)
end

function tf.dispNameToLabel(str)
    return str:gsub("%s+", "_"):lower()
end

function tf.tabToStr(tab, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local lines = {}
    for key, val in pairs(tab) do
        if type(val) == "table" then
            table.insert(lines, indentStr .. tostring(key) .. ":")
            table.insert(lines, tf.tabToStr(val, indent + 1))
        else
            table.insert(lines, indentStr .. tostring(key) .. ": " .. tostring(val))
        end
    end
    return table.concat(lines, "\n")
end

function tf.fnList(obj)
    local ret = {}
    if type(obj) == "table" then
        for key, val in pairs(obj) do
            if type(val) == "function" then
                table.insert(ret, key)
            end
        end
    end
    return ret
end

function tf.argsParse(argsStr)
    local args = {}
    for arg in argsStr:gmatch("%S+") do
        table.insert(args, arg)
    end
    return args
end

function tf.labelDatTolabelM(label, labelSub)
    return label .. ":" .. tostring(labelSub)
end

function tf.labelMToLabelDat(labelM)
    local parts = tf.split(labelM, ":")
    if #parts ~= 2 then
        return nil, nil
    end
    local label = parts[1]
    local labelSub = tonumber(parts[2])
    return label, labelSub
end

function tf.labelExToLabelDat(labelEx)
    local parts = tf.split(labelEx, ":")
    local label, labelSub, labelObj = nil, 1, nil
    if #parts > 0 and #parts < 4 then
        label = parts[1]
        if #parts == 2 then
            local num = tonumber(parts[2])
            if num then
                labelSub = num
            else
                labelObj = parts[2]
            end
        elseif #parts == 3 then
            labelSub = tonumber(parts[2]) or 1
            labelObj = parts[3]
        end
    end
    return label, labelSub, labelObj
end

function tf.time()
    return os.epoch("ingame") / 1000.0
end

function tf.periTypeGet(nameOrObj)
    if not nameOrObj then
        return nil
    end
    local type_ = peripheral.getType(nameOrObj)
    if type_ == "modem" then
        if peripheral.call(nameOrObj, "isWireless") then
            type_ = tf.PERI_TYPE_MODEM_WIRELESS
        else
            type_ = tf.PERI_TYPE_MODEM_WIRED
        end
    end
    return type_
end

function tf.periNamesByType(type_)
    local ret = {}
    local names = peripheral.getNames()
    for i = 1, #names do
        if tf.periTypeGet(names[i]) == type_ then
            table.insert(ret, names[i])
        end
    end
    return ret
end

function tf.periObjByName(name)
    if name then
        return peripheral.wrap(name)
    else
        return nil
    end
end

function tf.periObjByType(type_, which)
    local names = tf.periNamesByType(type_)
    if #names == 0 then
        return nil
    end
    if which then
        if type_ == tf.PERI_TYPE_INV_MGR then
            for i = 1, #names do
                if peripheral.call(names[i], "getOwner") == which then
                    return tf.periObjByName(names[i])
                end
            end
            return nil
        end
    end
    return tf.periObjByName(names[1])
end

function tf.periObjByLabel(label)
    if not tf.cfg["labels"] then
        tf.cfg["labels"] = {}
        tf.cfgSave()
    end
    return tf.periObjByName(tf.cfg["labels"][label])
end

function tf.periObjFind(label, type_, which, name)
    local peri = nil
    if label then
        peri = tf.periObjByLabel(label)
        if peri and (not type_ or tf.periTypeGet(peri) == type_) then
            return peri
        end
    end
    if name then
        peri = tf.periObjByName(name)
        if peri then
            return peri
        end
    end
    if type_ then
        peri = tf.periObjByType(type_, which)
        if peri then
            return peri
        end
    end
    return nil
end

function tf.pcLabelMToNetCh(pcLabelM)
    local pcNetCh = tf.pcLabelMToNetChTab[pcLabelM]
    if not pcNetCh then
        local label, labelSub = tf.labelMToLabelDat(pcLabelM)
        tf.msgSend("pc_label_req", { true, label, labelSub }, tf.NET_CH_BROADCAST)
        local pcLabelRes = tf.evtWaitForNmsgs("pc_label_res")[1]
        local senderNetCh = pcLabelRes[1]
        local senderLabel, senderLabelSub = pcLabelRes[3], pcLabelRes[4]
        if senderLabel == label and senderLabelSub == labelSub then
            pcNetCh = senderNetCh
            tf.pcLabelMToNetChTab[pcLabelM] = pcNetCh
            tf.pcNetChToLabelMTab[pcNetCh] = pcLabelM
        end
    end
    return pcNetCh
end

function tf.pcNetChToLabelM(pcNetCh, doFancy)
    local pcLabelM = tf.pcNetChToLabelMTab[pcNetCh]
    if not pcLabelM then
        tf.msgSend("pc_label_req", { false }, pcNetCh)
        local pcLabelRes = tf.evtWaitForNmsgs("pc_label_res")[1]
        local senderNetCh = pcLabelRes[1]
        if senderNetCh == pcNetCh then
            pcLabelM = tf.labelDatTolabelM(pcLabelRes[3], pcLabelRes[4])
            tf.pcLabelMToNetChTab[pcLabelM] = pcNetCh
            tf.pcNetChToLabelMTab[pcNetCh] = pcLabelM
        end
    end
    if doFancy and pcLabelM then
        local label, labelSub = tf.labelMToLabelDat(pcLabelM)
        pcLabelM = tf.labelToDispName(label)
        if labelSub > 1 then
            pcLabelM = pcLabelM .. ":" .. tostring(labelSub)
        end
    end
    return pcLabelM
end

function tf.msgSend(msgName, msgDat, ch)
    if not tf.periNet then
        error("Network not initialized")
    end
    msgDat = msgDat or {}
    ch = ch or tf.NET_CH_BROADCAST
    tf.periNet.transmit(ch, tf.pcNetCh, { tf.NMSG_HDR, msgName, msgDat })
    tf.dbgPrint("Nmsg sent: " .. msgName .. " to ch " .. tostring(ch))
end

function tf._evtWait(doSkipQueue)
    if not doSkipQueue then
        local queuedEvt = tf.queueGet(tf.evtPrioQueue)
        if queuedEvt then
            return queuedEvt
        end
    end
    if not tf.periNet then
        error("Network not initialized")
    end
    while true do
        local evtDat = { os.pullEvent() }
        if evtDat[1] == "chat" and evtDat[3]:sub(1, #tf.CHAT_CMD_PRE) == tf.CHAT_CMD_PRE and #evtDat[3] > #tf.CHAT_CMD_PRE then
            local args = tf.argsParse(evtDat[3]:sub(#tf.CHAT_CMD_PRE + 1))
            return { "cmd", args[1], { evtDat[2], table.unpack(args, 2) } }                           -- {"cmd", cmd, {sender, cmdArgs...}}
        elseif evtDat[1] == "modem_message" and evtDat[5][1] == tf.NMSG_HDR then
            return { "msg", evtDat[5][2], { evtDat[4], evtDat[6] or 0, table.unpack(evtDat[5][3]) } } -- {"msg", msg, {senderNetCh, dist, msgDat...}}
        elseif evtDat[1] == "timer" then
            return { "timer", evtDat[2] }                                                             -- {"timer", timerId}
        end
        tf.dbgPrint("Event ignored: " .. evtDat[1])
    end
end

function tf.evtWait(doSkipQueue)
    local evt = tf._evtWait(doSkipQueue)
    tf.dbgPrint("Event received: " .. evt[1] .. " " .. evt[2])
    return evt
end

function tf.evtWaitForNmsgs(msgName, cntMax, timeout)
    cntMax = cntMax or 1
    timeout = timeout or tf.HUGE
    local collectedMsgs = {}
    local timerId = os.startTimer(timeout)

    while #collectedMsgs < cntMax do
        local evt = tf.evtWait(true) -- Skip queue to prioritize new events

        local isAdded = false
        if evt[1] == "msg" then
            local msgName, msgParams = evt[2], evt[3]
            if msgName == msgName then
                table.insert(collectedMsgs, msgParams)
                isAdded = true
            end
        elseif evt[1] == "timer" and evt[2] == timerId then
            break -- Timeout reached
        end

        if not isAdded then
            tf.queueAdd(tf.evtPrioQueue, evt) -- Queue non-matching events for later retrieval
        end
    end

    return collectedMsgs
end

function tf.chatSendAs(msg, sender, range)
    if not tf.periChat then
        if tf.pcNetCh == tf.mainNetCh or sender ~= tf.pcName or range then
            error("Chat not initialized")
        else
            tf.msgSend("chat_send", { msg }, tf.mainNetCh)
            return
        end
    end
    sender = sender or "UNKNOWN"
    if tf.time() - tf.chatSendTime < tf.CHAT_SEND_CD then
        sleep(tf.CHAT_SEND_CD - (tf.time() - tf.chatSendTime))
    end
    while not tf.periChat.sendMessage(msg, sender, "<>", nil, range) do
        sleep(0.05)
    end
    tf.chatSendTime = tf.time()
end

function tf.chatSend(msg, range)
    tf.chatSendAs(msg, tf.pcName, range)
end

function tf.conWriteCol(msg, col)
    if col ~= tf.conCol then
        term.setTextColor(col)
    end
    print(msg)
    if col ~= tf.conCol then
        term.setTextColor(tf.conCol)
    end
end

function tf.pcLabelSet(label, labelSub)
    tf.pcLabel = label
    tf.pcLabelSub = labelSub or 1
end

function tf.pcNameSet(name)
    tf.pcName = name
end

function tf.dbSave(db, name)
    local file = fs.open(name .. ".txt", "w")
    if file then
        file.write(textutils.serialize(db))
        file.close()
    else
        error("Failed to open file for writing: " .. name .. ".txt")
    end
end

function tf.dbLoad(name)
    local file = fs.open(name .. ".txt", "r")
    if file then
        local db = textutils.unserialize(file.readAll())
        file.close()
        return db
    else
        return {} -- Return empty table if file doesn't exist
    end
end

function tf.cfgSave()
    tf.dbSave(tf.cfg, "cfg")
end

function tf.cfgLoad()
    tf.cfg = tf.dbLoad("cfg")
end

function tf.trilaterate4(p1, r1, p2, r2, p3, r3, p4, r4)
    local function trilaterate3(p1_, r1_, p2_, r2_, p3_, r3_)
        local ex = (p2_ - p1_):normalize()
        local i = ex:dot(p3_ - p1_)
        local tmp = (p3_ - p1_) - ex * i
        local ey = tmp:normalize()
        local ez = ex:cross(ey)
        local d = (p2_ - p1_):length()
        local j = ey:dot(p3_ - p1_)
        local x = (r1_ ^ 2 - r2_ ^ 2 + d ^ 2) / (2 * d)
        local y = (r1_ ^ 2 - r3_ ^ 2 + i ^ 2 + j ^ 2 - 2 * i * x) / (2 * j)
        local z2 = r1_ ^ 2 - x ^ 2 - y ^ 2
        if z2 < 0 then
            return nil, nil
        end
        local z = math.sqrt(z2)
        local res1 = p1_ + ex * x + ey * y + ez * z
        local res2 = p1_ + ex * x + ey * y - ez * z
        return res1, res2
    end

    local res1, res2 = trilaterate3(p1, r1, p2, r2, p3, r3)
    if not res1 then
        return nil
    end

    local function err(p)
        return math.abs((p - p4):length() ^ 2 - r4 ^ 2)
    end
    if err(res1) < err(res2) then
        return res1
    else
        return res2
    end
end

function tf.init(label, labelSub)
    tf.periNet = tf.periObjByType(tf.PERI_TYPE_MODEM_WIRELESS)
    if not tf.periNet then
        tf.conWriteCol("Connect an Ender Modem...", colors.red)
        while not tf.periNet do
            sleep(1.0)
            tf.periNet = tf.periObjByType(tf.PERI_TYPE_MODEM_WIRELESS)
        end
    end
    tf.periNet.open(tf.NET_CH_BROADCAST)
    tf.periNet.open(tf.pcNetCh)

    local name = tf.labelToDispName(label)
    tf.pcLabelSet(label, labelSub)
    tf.pcNameSet(name)

    tf.msgSend("pc_init", { tf.pcLabel, tf.pcLabelSub }, tf.NET_CH_BROADCAST)
    if tf.pcLabel == "main" then
        tf.mainNetCh = tf.pcNetCh
    else
        local pcAccept = tf.evtWaitForNmsgs("pc_accept", 1, 1.5)[1]
        if not pcAccept then
            print("Waiting for main to accept connection...")
        end
        while not pcAccept do
            tf.msgSend("pc_init", { tf.pcLabel, tf.pcLabelSub }, tf.NET_CH_BROADCAST)
            pcAccept = tf.evtWaitForNmsgs("pc_accept", 1, 5.0)[1]
        end
        tf.mainNetCh = pcAccept[1]
    end

    tf.conWriteCol(name .. " #" .. tf.pcLabelSub .. " online!", colors.green)

    if onEvt.sys.init then
        local sysInitResult = onEvt.sys.init({})
        if sysInitResult then
            return sysInitResult
        end
    end

    return nil
end

function tf.free()
    if onEvt.sys.free then
        onEvt.sys.free({})
    end
    tf.periNet.close(tf.pcNetCh)
    tf.periNet.close(tf.NET_CH_BROADCAST)
    tf.periNet = nil
end

function tf.cmdHelpStr(cmdName)
    if not defDat.cmd[cmdName] then
        return "No help available for unknown command '" .. cmdName .. "'!"
    end
    local infoMsg = "Usage: " .. cmdName
    if defDat.cmd[cmdName].params then
        for _, param in ipairs(defDat.cmd[cmdName].params) do
            local enclose = { " <", ">" }
            if param.defa then
                enclose = { " [", "]" }
            end
            infoMsg = infoMsg .. enclose[1] .. param.name .. ": " .. tf.type.toStr[param.type]
            if param.picks then
                infoMsg = infoMsg .. " (" .. table.concat(param.picks, " | ") .. ")"
            end
            if param.defa and param.defa ~= "" then
                infoMsg = infoMsg .. " =" .. tostring(param.defa)
            end
            infoMsg = infoMsg .. enclose[2]
        end
    end
    if defDat.cmd[cmdName].desc then
        infoMsg = infoMsg .. " - " .. defDat.cmd[cmdName].desc
    end
    if defDat.cmd[cmdName].examples and #defDat.cmd[cmdName].examples > 0 then
        infoMsg = infoMsg .. " - Example: " .. defDat.cmd[cmdName].examples[1]
    end
    return infoMsg
end

function onEvt.msg.pc_label_req(evtParams)
    if evtParams[3] then
        if evtParams[4] ~= tf.pcLabel or evtParams[5] ~= tf.pcLabelSub then
            return
        end
    end
    tf.msgSend("pc_label_res", { tf.pcLabel, tf.pcLabelSub }, evtParams[1])
end

function onEvt.msg.ping(evtParams)
    tf.msgSend("pong", {}, evtParams[1])
end

function onEvt.msg.reboot(evtParams)
    os.reboot()
end

return tf
