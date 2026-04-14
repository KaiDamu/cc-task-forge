defDat.cmd.perilabel = {
    params = {
        { name = "peri_label", type = tf.type.LABEL_EX },
        { name = "peri_name",  type = tf.type.STR,     picks = { "*", "clear" }, defa = "" }
    },
    desc = "Link a peripheral name to a computer's peripheral label (or clear it). Or get the linked peripheral name.",
    examples = { "perilabel chester:so me_bridge_3" }
}

function onEvt.sys.init(evtParams)
    tf.periChat = tf.periObjByType(tf.PERI_TYPE_CHAT_BOX)
    if not tf.periChat then
        return "A required Chat Box is not connected!"
    end
    return nil
end

function onEvt.sys.free(evtParams)
    tf.periChat = nil
end

function onEvt.cmd.dbg(evtParams)
    tf.cfg["isDbg"] = not tf.cfg["isDbg"]
    tf.cfgSave()
    tf.chatSend("Debug mode " .. (tf.cfg["isDbg"] and "enabled" or "disabled"))
end

function onEvt.cmd.reboot(evtParams)
    tf.msgSend("reboot", {}, tf.NET_CH_BROADCAST)
    onEvt.msg.reboot({})
end

function onEvt.cmd.locate(evtParams)
    tf.msgSend("gps_pos_req", {}, tf.NET_CH_BROADCAST)

    local posResList = tf.evtWaitForNmsgs("gps_pos_res", 4, 3.0)
    if #posResList < 4 then
        tf.chatSend("Not enough position responses received for trilateration (need 4, got " .. #posResList .. ")")
        return
    end

    local points = {}
    local radii = {}
    for i = 1, 4 do
        points[i] = vector.new(posResList[i][3], posResList[i][4], posResList[i][5])
        radii[i] = posResList[i][2]
    end

    local pos = tf.trilaterate4(points[1], radii[1], points[2], radii[2], points[3], radii[3], points[4], radii[4])
    if pos then
        tf.chatSend("My position is: " .. pos.x .. ", " .. pos.y .. ", " .. pos.z)
    else
        tf.chatSend("Failed to trilaterate position - no solution found")
    end
end

function onEvt.cmd.ping(evtParams)
    tf.msgSend("ping", {}, tf.NET_CH_BROADCAST)
    local pongs = tf.evtWaitForNmsgs("pong", tf.HUGE, 1.5)
    tf.chatSend("Online devices: " .. (#pongs + 1))
end

function onEvt.cmd.perilabel(evtParams, fnName)
    local pcLabel, pcLabelSub, periLabel = tf.labelExToLabelDat(evtParams[2])
    local periName = evtParams[3]
    if pcLabel and pcLabelSub and periLabel then
        local netCh = tf.pcLabelMToNetCh(tf.labelDatTolabelM(pcLabel, pcLabelSub))
        tf.msgSend("label_upd", { periLabel, periName }, netCh)
    else
        local infoMsg = "Usage: " .. fnName
        for _, param in ipairs(defDat.cmd.perilabel.params) do
            local enclose = { " <", ">" }
            if param.defa then
                enclose = { " [", "]" }
            end
            infoMsg = infoMsg .. enclose[1] .. param.name .. ": " .. tf.type.toStr[param.type]
            if param.picks then
                infoMsg = infoMsg .. " (" .. table.concat(param.picks, "|") .. ")"
            end
            if param.defa and param.defa ~= "" then
                infoMsg = infoMsg .. " =" .. tostring(param.defa)
            end
            infoMsg = infoMsg .. enclose[2]
        end
        if defDat.cmd.perilabel.desc then
            infoMsg = infoMsg .. " - " .. defDat.cmd.perilabel.desc
        end
        if defDat.cmd.perilabel.examples and #defDat.cmd.perilabel.examples > 0 then
            infoMsg = infoMsg .. " - Example: " .. defDat.cmd.perilabel.examples[1]
        end
        tf.chatSend(infoMsg)
    end
end

function onEvt.cmd.pos(evtParams)
    if evtParams[2] == "set" then
        local pcLabel, pcLabelSub = tf.labelExToLabelDat(evtParams[3])
        local posX, posY, posZ = tonumber(evtParams[4]), tonumber(evtParams[5]), tonumber(evtParams[6])
        if pcLabel and pcLabelSub and posX and posY and posZ then
            local netCh = tf.pcLabelMToNetCh(tf.labelDatTolabelM(pcLabel, pcLabelSub))
            tf.msgSend("pos_upd", { posX, posY, posZ }, netCh)
        else
            tf.chatSend("Usage: pos set <pc_label> <x> <y> <z>")
        end
    end
end

function onEvt.cmd.so(evtParams)
    tf.msgSend("so", { evtParams[2], evtParams[3] })
end

function onEvt.cmd.undress(evtParams)
    tf.msgSend("undress", { evtParams[2] })
end

function onEvt.cmd.disenchant(evtParams)
    tf.msgSend("disenchant", { evtParams[2] })
end

function onEvt.cmd.random(evtParams)
    if evtParams[2] == "color" then
        local cnt = tonumber(evtParams[3]) or 1
        local COLORS = {
            "black", "red", "green", "brown", "blue", "purple", "cyan", "light_gray", "gray", "pink", "lime", "yellow",
            "light_blue", "magenta", "orange", "white"
        }
        local result = "Random colors:"
        for i = 1, cnt do
            local color = COLORS[math.random(1, #COLORS)]
            result = result .. " " .. color
        end
        tf.chatSend(result)
    end
end

function onEvt.cmd.hello(evtParams)
    tf.chatSend("Hi " .. evtParams[1] .. "!")
end

function onEvt.msg.chat_send(evtParams)
    tf.chatSendAs(evtParams[3], tf.pcNetChToLabelM(evtParams[1], true))
end

function onEvt.msg.con_send(evtParams)
    print("<" .. tf.pcNetChToLabelM(evtParams[1], true) .. "> " .. evtParams[3])
end

function onEvt.msg.pc_init(evtParams)
    local senderNetCh = evtParams[1]
    local labelM = tf.labelDatTolabelM(evtParams[3], evtParams[4])
    tf.pcLabelMToNetChTab[labelM] = senderNetCh
    tf.pcNetChToLabelMTab[senderNetCh] = labelM
    tf.msgSend("pc_accept", {}, senderNetCh)
end
