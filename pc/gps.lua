function evtProc_nmsg_gps_pos_req(evtParams)
    if not tf.cfg["pos"] or not tf.cfg["pos"]["x"] or not tf.cfg["pos"]["y"] or not tf.cfg["pos"]["z"] then
        tf.chatSend("My position is not set!")
        return
    end
    tf.nmsgSend("gps_pos_res", { tf.cfg["pos"]["x"], tf.cfg["pos"]["y"], tf.cfg["pos"]["z"] }, evtParams[1])
end

function evtProc_nmsg_pos_upd(evtParams)
    local posX, posY, posZ = evtParams[3], evtParams[4], evtParams[5]
    if not tf.cfg["pos"] then
        tf.cfg["pos"] = {}
    end
    tf.cfg["pos"]["x"] = posX
    tf.cfg["pos"]["y"] = posY
    tf.cfg["pos"]["z"] = posZ
    tf.cfgSave()
    tf.chatSend("Position set: " .. posX .. ", " .. posY .. ", " .. posZ)
end
