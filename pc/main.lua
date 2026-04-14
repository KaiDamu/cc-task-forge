defDat.cmd.dbg = {
    desc = "Toggle debug mode (more verbose logging)."
}
defDat.cmd.reboot = {
    desc = "Reboot all connected computers (including this one)."
}
defDat.cmd.locate = {
    desc = "Locate this computer using GPS."
}
defDat.cmd.ping = {
    desc = "Ping all connected computers to see who's online."
}
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

function onEvt.cmd.dbg()
    tf.cfg["isDbg"] = not tf.cfg["isDbg"]
    tf.cfgSave()
    tf.chatSend("Debug mode " .. (tf.cfg["isDbg"] and "enabled" or "disabled"))
end

function onEvt.cmd.reboot()
    tf.msgSend("reboot", {}, tf.NET_CH_BROADCAST)
    onEvt.msg.reboot({})
end

function onEvt.cmd.locate()
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

function onEvt.cmd.ping()
    tf.msgSend("ping", {}, tf.NET_CH_BROADCAST)
    local pongs = tf.evtWaitForNmsgs("pong", tf.HUGE, 1.5)
    tf.chatSend("Online devices: " .. (#pongs + 1))
end

function onEvt.cmd.perilabel(params)
    local pcLabel, pcLabelSub, periLabel = tf.labelExToLabelDat(params[1])
    local periName = params[2]
    if pcLabel and pcLabelSub and periLabel then
        local netCh = tf.pcLabelMToNetCh(tf.labelDatTolabelM(pcLabel, pcLabelSub))
        tf.msgSend("label_upd", { periLabel, periName }, netCh)
    end
end

function onEvt.cmd.pos(params)
    if params[1] == "set" then
        local pcLabel, pcLabelSub = tf.labelExToLabelDat(params[2])
        local posX, posY, posZ = tonumber(params[3]), tonumber(params[4]), tonumber(params[5])
        if pcLabel and pcLabelSub and posX and posY and posZ then
            local netCh = tf.pcLabelMToNetCh(tf.labelDatTolabelM(pcLabel, pcLabelSub))
            tf.msgSend("pos_upd", { posX, posY, posZ }, netCh)
        else
            tf.chatSend("Usage: pos set <pc_label> <x> <y> <z>")
        end
    end
end

function onEvt.cmd.so(params)
    tf.msgSend("so", { params[1], params[2] })
end

function onEvt.cmd.undress(params)
    tf.msgSend("undress", { params[1] })
end

function onEvt.cmd.disenchant(params)
    tf.msgSend("disenchant", { params[1] })
end

function onEvt.cmd.random(params)
    if params[1] == "color" then
        local cnt = tonumber(params[2]) or 1
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

function onEvt.cmd.hello(params, sender)
    tf.chatSend("Hi " .. sender .. "!")
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
