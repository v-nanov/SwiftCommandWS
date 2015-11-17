////
////  StarscreamMock.swift
////  SwiftCommandWS
////
////  Created by Fernando Oliveira on 17/11/15.
////  Copyright © 2015 FCO. All rights reserved.
////
//
//import Foundation
//import EventEmitter
//
//class WebSocket : EventEmitter {
//    let url             : NSURL
//    var onConnect       : (Any -> Void)?
//    var onDisconnect    : (Any -> Void)?
//    var onText          : (Any -> Void)?
//    var onData          : (Any -> Void)?
//    
//    init(url : NSURL) {
//        self.url = url
//        self.on("connected") {
//            (self.onConnect)?()
//        }
//    }
//    
//    func connect() {
//        self.emit("connected")
//    }
//}