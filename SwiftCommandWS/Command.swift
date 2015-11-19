//
//  Command.swift
//  testTelll
//
//  Created by Fernando Oliveira on 10/10/15.
//  Copyright © 2015 telll. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON
import CryptoSwift

public class Command : CustomStringConvertible {
    static let flow = [
        "__init__":     "REQUEST",
        "REQUEST":      "RESPONSE",
        "RESPONSE":     "CONFIRM",
        "__subs__":     "SUBSCRIBE",
        "SUBSCRIBE":    "EVENT",
        "EVENT":        "EVENT"
    ]
    
    static let fields2check = ["cmd", "counter", "trans_id", "version", "type"]
    
    static var transCounter : Int = 0;

    let socket      : WebSocket
    let json        : JSON?
    public let data        : JSON?
    let cmd         : String?
    let type        : String?
    let trans_id    : String?
    let version     : Int?
    let counter     : Int?
    var checksum    : String?
    public var description : String {
        /*return (json.rawString())!*/
        
        var jsonP = JSON([
            "cmd":      nil,
            "type":     nil,
            "data":     nil,
            "trans_id": nil/*,
            "version":  nil,
            "counter":  nil,
            "checksum": nil*/
        ])
        if (cmd != nil) {
            jsonP["cmd"].string = cmd
        }
        if (type != nil) {
            jsonP["type"].string = type
        }
        if (data != nil) {
            jsonP["data"] = data!
        }
        if (trans_id != nil) {
            jsonP["trans_id"].string = trans_id!
        }
        if (version != nil) {
            jsonP["version"].int = version!
        }
        if (counter != nil) {
            jsonP["counter"].int = counter!
        }
        if (checksum != nil) {
            jsonP["checksum"].string = checksum!
        }

        return jsonP.rawString()!
    }

    convenience init(socket sock: WebSocket, fromString string :String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        
        self.init(socket: sock, fromData: data)
    }
    
    init(socket sock: WebSocket, fromData sData :NSData) {
        socket = sock

        json = JSON(data: sData)
        cmd         = json!["cmd"]       .string
        type        = json!["type"]      .string
        trans_id    = json!["trans_id"]  .string
        version     = json!["version"]   .int
        counter     = json!["counter"]   .int
        checksum    = json!["checksum"]  .string
        data        = json!["data"]
    }
    
    
    init(socket sock: WebSocket, cmd localCmd : String, type localType : String = "REQUEST", data localData : JSON? = nil) {
        socket      = sock
        json        = nil
        cmd         = localCmd
        type        = localType
        trans_id    = Command.generateTransId()
        version     = 1
        counter     = 0
        //checksum    = "1234567890123456789012345678901234567890"
        checksum    = nil
        data        = localData
    }
    
    subscript(index : String) -> String? {
        get {
            var ret : String?
            switch index {
                case "cmd":
                    ret = cmd!
                break
                case "type":
                    ret = type!
                break
                case "trans_id":
                    ret = trans_id!
                break
                case "version":
                    ret = "\(version!)"
                break
                case "counter":
                    ret = "\(counter!)"
                break
                default:
                    ret = nil
                break
            }
            return ret
        }
    }
    
    func send() {
        checksum = generateCheckSum()
        socket.writeData(description.dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    static func generateTransId() -> String {
        let date    = String(NSDate())
        let count   = String(Command.transCounter++)
        let rand    = String(arc4random_uniform(10000))
        
        return [date, count, rand, "CommandWS"].joinWithSeparator(" - ").sha1()
    }
    
    func generateCheckSum() -> String {
        print(Command.fields2check.map({field in return self[field]!}).joinWithSeparator("\n"))
        return Command.fields2check.map({field in return self[field]!}).joinWithSeparator("\n").sha1()
    }
}