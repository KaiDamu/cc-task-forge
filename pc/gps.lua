function tf.at.msg.gps_pos_req(evtParams)
    if not tf.cfg.dat["pos"] or not tf.cfg.dat["pos"]["x"] or not tf.cfg.dat["pos"]["y"] or not tf.cfg.dat["pos"]["z"] then
        tf.chat.send("My position is not set!")
        return
    end
    tf.net.send("gps_pos_res", { tf.cfg.dat["pos"]["x"], tf.cfg.dat["pos"]["y"], tf.cfg.dat["pos"]["z"] }, evtParams[1])
end

function tf.at.msg.pos_upd(evtParams)
    local posX, posY, posZ = evtParams[3], evtParams[4], evtParams[5]
    if not tf.cfg.dat["pos"] then
        tf.cfg.dat["pos"] = {}
    end
    tf.cfg.dat["pos"]["x"] = posX
    tf.cfg.dat["pos"]["y"] = posY
    tf.cfg.dat["pos"]["z"] = posZ
    tf.cfg.save()
    tf.chat.send("Position set: " .. posX .. ", " .. posY .. ", " .. posZ)
end
