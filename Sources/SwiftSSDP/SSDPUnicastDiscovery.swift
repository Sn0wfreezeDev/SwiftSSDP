//
//  File.swift
//  
//
//  Created by Alex - SEEMOO on 16.04.24.
//

import Foundation

public class SSDPUnicastDiscovery: SSDPDiscovery {
    
    var unicastAddresses = [String]()
    
    public init(responseQueue: DispatchQueue, ipAddressRange: (String, String) ) {
        super.init(responseQueue: responseQueue)
        
        let ipStart = ipAddressRange.0
        let ipEnd = ipAddressRange.1
        
        guard let startNumString = ipStart.split(separator: ".").last,
                let startNum = Int(startNumString),
              let endNumString = ipEnd.split(separator: ".").last,
              let endNum = Int(endNumString) else {
            return
        }
        
        let base = ipStart.split(separator: ".")
        
        let ipAddresses = (startNum...endNum).map { ipNum in
            var ipArray = base
            ipArray[base.count-1] = String.SubSequence(stringLiteral: "\(ipNum)")
            
            return ipArray.joined(separator: ".")
        }
        self.unicastAddresses = ipAddresses
    }
    
    public override func sendRequestMessage(request: SSDPMSearchRequest, retry: Bool = false) {
        if let socket = self.asyncUdpSocket {
            let messageData = request.message.data(using: .utf8)!
            
            for ip in unicastAddresses {
                sendUnicastRequestMessage(message: messageData, retry: retry, ipAddress: ip, socket: socket)
            }
//            socket.send(messageData, toHost: SSDPDiscovery.ssdpHost, port: UInt16(SSDPDiscovery.ssdpPort), withTimeout: -1, tag: 1000)
        }
    }
    
    internal func sendUnicastRequestMessage(message: Data, retry: Bool = false, ipAddress: String, socket: SSDPUDPSocket) {
        
        do {
            try socket.send(messageData: message, toHost: SSDPDiscovery.ssdpHost, port: UInt16(SSDPDiscovery.ssdpPort), withTimeout: -1, tag: 1000)
        }catch {
            os_log(.error, "Failed sending SSDP request message %@", error.localizedDescription)
            guard !retry else {return}
            //Failed. Retry later
            DispatchQueue.main.asyncAfter(deadline: .now()+1, execute: {
                self.sendUnicastRequestMessage(message: message, retry: true, ipAddress: ipAddress, socket: socket)
            })
        }
    }
    
    
}
