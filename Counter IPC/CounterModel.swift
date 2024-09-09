//
//  CounterModel.swift
//  Counter IPC
//
//  Created by Seth Corker on 07/09/2024.
//

import Foundation

class CounterModel: ObservableObject {
    @Published var value: Int = 0;
    
    var socketFileDescriptor: Int32 = -1;
    
    func increment() {
        sendMessage("increment()")
        value = Int(receiveMessage()!, radix: 10) ?? value
    }
    
    func decrement() {
        sendMessage("decrement()")
        value = Int(receiveMessage()!, radix: 10) ?? value
    }
    
    func sendMessage(_ message: String) {
        let messageBytes = [UInt8](message.utf8)
        
        let bytesSent = messageBytes.withUnsafeBytes {
            send(socketFileDescriptor, $0.baseAddress, $0.count, 0)
        }
        
        if bytesSent < 0 {
            print("Error sending data: \(errno)")
            close(socketFileDescriptor)
            return
        }
        
        print("Sent \(bytesSent) bytes to the socket.")
    }
    
    func receiveMessage() -> String? {
        // Receive a response from the socket
        var buffer = [UInt8](repeating: 0, count: 1024)
        
        let bytesReceived = buffer.withUnsafeMutableBytes {
            recv(socketFileDescriptor, $0.baseAddress, $0.count, 0)
        }
        
        if bytesReceived < 0 {
            print("Error receiving data: \(errno)")
            close(socketFileDescriptor)
            return nil
        }
        
        let receivedMessage = String(bytes: buffer.prefix(bytesReceived), encoding: .utf8)
        return receivedMessage?.replacingOccurrences(of: "\r\n", with: "")
    }
    
    func closeConnection() {
        close(socketFileDescriptor)
    }
    
    func setupConnection() {
        let socketPath = "/tmp/.test-ipc.sock"
        socketFileDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        if socketFileDescriptor < 0 {
            print("Error creating socket: \(errno)")
            return
        }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxPathLen = MemoryLayout.size(ofValue: addr.sun_path)
        
        // Ensure the socket path fits in sun_path
        if socketPath.count >= maxPathLen {
            print("Socket path too long")
            close(socketFileDescriptor)
            return
        }
        
        strcpy(&addr.sun_path, socketPath)
        
        let addrSize = socklen_t(MemoryLayout<sockaddr_un>.size)
        let result = withUnsafePointer(to: &addr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketFileDescriptor, $0, addrSize)
            }
        }
        
        if result < 0 {
            let errorMessage = String(cString: strerror(errno))
            print("Error connecting to socket: \(errno) — \(errorMessage)")
            close(socketFileDescriptor)
            return
        }
        
        print("Connected to Unix domain socket.")
    }
}
