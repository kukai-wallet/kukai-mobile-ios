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
	private var initURL: URL
	
	public init(withURL url: URL) {
		self.initURL = url
		self.isConnected = false
		self.request = URLRequest(url: url)
		super.init()
	}
	
	public func reconnect() {
		self.socket = URLSession.shared.webSocketTask(with: initURL)
		self.socket?.delegate = self
		self.isConnected = false
		self.connect()
	}
	
	
	
	// MARK: - WebSocketConnecting
	
	public var isConnected: Bool
	
	public var onConnect: (() -> Void)?
	
	public var onDisconnect: ((Error?) -> Void)?
	
	public var onText: ((String) -> Void)?
	
	public var request: URLRequest {
		didSet {
			os_log("NativeSocket new request set", log: .default, type: .info)
			
			if let url = request.url {
				self.socket = URLSession.shared.webSocketTask(with: url)
				self.socket?.delegate = self
				self.isConnected = false
				self.initURL = url
				
				self.connect()
			}
		}
	}
	
	public func connect() {
		if socket != nil {
			os_log("NativeSocket connect func called", log: .default, type: .info)
			socket?.resume()
			
		} else {
			os_log("NativeSocket connect func called, triggering reconnect", log: .default, type: .info)
			reconnect()
		}
	}
	
	public func disconnect() {
		os_log("NativeSocket disconnect func called", log: .default, type: .info)
		isConnected = false
		socket?.cancel()
		socket = nil
	}
	
	public func write(string: String, completion: (() -> Void)?) {
		let message = URLSessionWebSocketTask.Message.string(string)
		socket?.send(message) { err in
			if let e = err {
				os_log("NativeSocket sending error: %@", log: .default, type: .info, "\(e)")
				
			} else {
				os_log("NativeSocket sent: %@", log: .default, type: .info, string)
			}
			
			if let comp = completion {
				comp()
			}
		}
	}
	
	
	
	// MARK: - URLSessionWebSocketDelegate
	
	
	public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
		isConnected = true
		os_log("NativeSocket connected", log: .default, type: .info)
		
		if let onC = onConnect {
			onC()
		}
		
		receiveMessage()
	}
	
	public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
		isConnected = false
		os_log("NativeSocket did close", log: .default, type: .error)
		
		if let onD = onDisconnect {
			if closeCode != URLSessionWebSocketTask.CloseCode.normalClosure {
				os_log("NativeSocket did close with code: normal", log: .default, type: .error)
				onD(NativeSocketError.errorWithCode(closeCode))
				
			} else {
				os_log("NativeSocket did close with code: %@", log: .default, type: .error, "\(closeCode)")
				onD(nil)
			}
		}
	}
	
	func receiveMessage() {
		socket?.receive(completionHandler: { [weak self] result in
			
			switch result {
				case .failure(let error):
					os_log("NativeSocket Error receiving: %@", log: .default, type: .error, "\(error)")
					
					// If its failing because the conneciton closed by itself, try to reconnect
					let nsErr = error as NSError
					if nsErr.code == 57 && nsErr.domain == "NSPOSIXErrorDomain" {
						self?.isConnected = false
					}
					
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
			
			if self?.isConnected == true {
				self?.receiveMessage()
			}
		})
	}
}

struct NativeSocketFactory: WebSocketFactory {
	
	func create(with url: URL) -> WebSocketConnecting {
		return NativeSocket(withURL: url)
	}
}
