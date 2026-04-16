tf.info.cmd.hello = {
    args = {
        { name = "pc", type = tf.type.LABEL_M, isDst = true }
    },
    desc = "Just say hi to the sender."
}
function tf.at.cmd.hello(args, sender)
    tf.chat.send("Hi " .. sender .. "!")
end

function tf.at.msg.gps_pos_req(dat, senderCh)
    if not tf.cfg.dat["pos"] or not tf.cfg.dat["pos"]["x"] or not tf.cfg.dat["pos"]["y"] or not tf.cfg.dat["pos"]["z"] then
        tf.chat.send("My position is not set!")
        return
    end
    tf.net.send("gps_pos_res", { tf.cfg.dat["pos"]["x"], tf.cfg.dat["pos"]["y"], tf.cfg.dat["pos"]["z"] }, senderCh)
end

function tf.at.msg.cfg_pos(dat)
    local posX, posY, posZ = dat[1], dat[2], dat[3]
    if not tf.cfg.dat["pos"] then
        tf.cfg.dat["pos"] = {}
    end
    tf.cfg.dat["pos"]["x"] = posX
    tf.cfg.dat["pos"]["y"] = posY
    tf.cfg.dat["pos"]["z"] = posZ
    tf.cfg.save()
    tf.chat.send("Position set: " .. posX .. ", " .. posY .. ", " .. posZ)
end
