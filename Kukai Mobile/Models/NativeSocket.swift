//
//  NativeSocket.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/07/2022.
//

import Foundation
import WalletConnectRelay
import OSLog

public enum NativeSocketError: Error {
	case errorWithCode(URLSessionWebSocketTask.CloseCode)
}

public class NativeSocket: NSObject, WebSocketConnecting, URLSessionWebSocketDelegate {
	
	private var socket: URLSessionWebSocketTask? = nil
	
	init(withURL url: URL) {
		self.socket = URLSession.shared.webSocketTask(with: url)
		self.isConnected = false
		super.init()
		
		self.socket?.delegate = self
	}
	
	
	
	// MARK: - WebSocketConnecting
	
	public var isConnected: Bool
	
	public var onConnect: (() -> Void)?
	
	public var onDisconnect: ((Error?) -> Void)?
	
	public var onText: ((String) -> Void)?
	
	public func connect() {
		socket?.resume()
	}
	
	public func disconnect() {
		socket?.cancel()
	}
	
	public func write(string: String, completion: (() -> Void)?) {
		let message = URLSessionWebSocketTask.Message.string(string)
		socket?.send(message) { err in
			if let e = err {
				os_log("NativeSocket sending error: %@", log: .default, type: .info, "\(e)")
				
			}
			
			if let comp = completion {
				comp()
			}
		}
	}
	
	
	
	// MARK: - URLSessionWebSocketDelegate
	
	public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
		isConnected = true
		
		if let onC = onConnect {
			onC()
		}
		
		receiveMessage()
	}
	
	public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
		isConnected = false
		
		if let onD = onDisconnect {
			if closeCode != URLSessionWebSocketTask.CloseCode.normalClosure {
				onD(NativeSocketError.errorWithCode(closeCode))
			}
			
			onD(nil)
		}
	}
	
	func receiveMessage() {
		socket?.receive(completionHandler: { [weak self] result in
			
			switch result {
				case .failure(let error):
					os_log("NativeSocket Error receiving: %@", log: .default, type: .error, "\(error)")
					
				case .success(let message):
					switch message {
						case .string(let messageString):
							os_log("NativeSocket received message: %@", log: .default, type: .info, messageString)
							if let onT = self?.onText {
								onT(messageString)
							}
							
						case .data(let data):
							os_log("NativeSocket received data: %@", log: .default, type: .info, data.description)
							if let onT = self?.onText {
								onT(data.description)
							}
							
						default:
							os_log("NativeSocket received unknown data", log: .default, type: .info)
					}
			}
			self?.receiveMessage()
		})
	}
}

struct NativeSocketFactory: WebSocketFactory {
	
	func create(with url: URL) -> WebSocketConnecting {
		return NativeSocket(withURL: url)
	}
}
