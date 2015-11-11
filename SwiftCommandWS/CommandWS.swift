//
//  CommandWS.swift
//  testTelll
//
//  Created by Fernando Oliveira on 10/10/15.
//  Copyright © 2015 telll. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

class CommandWS : EventEmitter {
    let socket  : WebSocket
    var cmds    : [String:CommandStruct] = [:]
    
    struct CommandStruct {
        let name    : String;
        let schema  : JSON?
    }
    
    init(url: NSURL) {
        super.init(socket = WebSocket(url: url))

        socket.onConnect = {
            print("websocket is connected")
            let cmd = Command(socket: self.socket, cmd: "list_commands")
            cmd.send()
        }

        socket.onDisconnect = { (error :NSError?) in
            print("websocket is disconnected: \(error?.localizedDescription)")
            self.emit("disconnect")
        }

        socket.onText = { (text : String) in
            let cmd = Command(socket: self.socket, fromString: text)
            print("emit \(cmd.cmd!)")
            self.receiveRequest(cmd)
        }

        socket.onData = { (data : NSData) in
            let cmd = Command(socket: self.socket, fromData: data)
            self.receiveRequest(cmd)
        }
        
        on("list_commands") {
            (cmd : Command) in
            print("CMD: ", cmd)
            for (cmdName, node) in cmd.data! {
                print(cmdName)
                /*self.cmds[cmdName] = {(data : JSON?, cb: ((JSON?) -> Void)?) in
                    let cmd = Command(socket: self.socket, cmd: cmdName, data: data)
                    cmd.send()
                }*/
                self.cmds[cmdName] = CommandStruct(name: cmdName, schema: node["schema"])
            }
            self.emit("open")
        }

        socket.connect()
    }
    
    private func receiveRequest(cmd : Command) {
        emit("command", data: cmd)
        emit("\(cmd.cmd!)", data: cmd)
        emit("\(cmd.cmd!) \(cmd.trans_id!)", data: cmd)
        emit("\(cmd.cmd!) \(cmd.trans_id!) \(cmd.type!)", data: cmd)
    }
    
    func run(cmd: String, data: JSON = nil, cb: (Command -> Void)? = nil) -> Command? {
        if let cmdConf = cmds[cmd] {
            let cmd = Command(socket: socket, cmd: cmdConf.name, data: data)
            if cb != nil {
                once("\(cmd.cmd) \(cmd.trans_id)") {
                    (cmd : Command) in
                    print("recebeu")
                    if cmd.type?.uppercaseString == (Command.flow[cmd.type!]?.uppercaseString)! || (cmd.type?.uppercaseString)! == "ERROR" {
                        cb!(cmd)
                    }
                }
            }
            cmd.send()
            return cmd
        }
        return nil
    }
    
    func disconnect() {
        cmds = [:]
        socket.disconnect()
    }
}