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
import EventEmitter

public class CommandWS : EventEmitter {
    let socket  : WebSocket
    var cmds    : [String:CommandStruct] = [:]
    
    struct CommandStruct {
        let name    : String;
        let schema  : JSON?
    }
    
    public init(url: NSURL) {

        socket = WebSocket(url: url)
        super.init()

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
    
    public func run(cmd: String, data: JSON = nil, cb: (Command -> Void)? = nil) -> Command? {
        if let cmdConf = cmds[cmd] {
            let cmd = Command(socket: socket, cmd: cmdConf.name, data: data)
            if cb != nil {
                print("once: \(cmd.cmd!) \(cmd.trans_id!)")
                once("\(cmd.cmd!) \(cmd.trans_id!)") {
                    (resp : Command) in
                    print("recebeu")
                    if resp.type?.uppercaseString == (Command.flow[cmd.type!]?.uppercaseString)! || (resp.type?.uppercaseString)! == "ERROR" {
                        cb!(resp)
                    }
                }
            }
            cmd.send()
            return cmd
        }
        return nil
    }
    
    public func disconnect() {
        cmds = [:]
        socket.disconnect()
    }
}