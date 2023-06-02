//
//  LookupService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 01/06/2023.
//

import Foundation
import KukaiCoreSwift

public enum LookupType: Int, Codable { // in order of priority
	case addressBook
	case tezosDomain
	case google
	case reddit
	case twitter
	case alias
	case address
}

public struct LookupResponse {
	let displayText: String
	let type: LookupType
	let iconName: String
}

public struct LookupRecord: Codable {
	let displayText: String
	let refreshDate: Date
}

public class LookupService {
	
	public static let shared = LookupService()
	
	private var records: [String: [LookupType: LookupRecord]] = [:]
	private static let cacheKey = "lookup-service-records"
	
	private init() {
		records = DiskService.read(type: [String: [LookupType: LookupRecord]].self, fromFileName: LookupService.cacheKey) ?? [:]
	}
	
	public func unresolvedDomains(addresses: [String]) -> [String] {
		let now = Date()
		return addresses.map({ [$0, BalanceService.addressCacheKey(forAddress: $0)] }).compactMap({
			if records[$0[1]]?[.tezosDomain] == nil || now.timeIntervalSince(records[$0[1]]?[.tezosDomain]?.refreshDate ?? now) > 0 {
				return $0[0]
			}
			
			return nil
		})
	}
	
	public func resolveAddresses(_ addresses: [String], completion: @escaping (() -> Void)) {
		if addresses.count == 0 {
			completion()
			return
		}
		
		// Only doing tezos domains, torus lookup was removed due to privacy concerns
		DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainsFor(addresses: addresses) { [weak self] result in
			guard let res = try? result.get() else {
				completion()
				return
			}
			
			for key in res.keys {
				self?.add(displayText: res[key]?.mainnet?.domain.name ?? "", forType: .tezosDomain, forAddress: key, isMainnet: true)
				self?.add(displayText: res[key]?.ghostnet?.domain.name ?? "", forType: .tezosDomain, forAddress: key, isMainnet: false)
			}
			
			self?.cacheRecords()
			completion()
		}
	}
	
	public func add(displayText: String, forType: LookupType, forAddress: String, isMainnet: Bool) {
		var addressKey = forAddress
		if !isMainnet {
			addressKey += "-ghostnet"
		}
		
		if records[addressKey] == nil { records[addressKey] = [:] }
		records[addressKey]?[forType] = LookupRecord(displayText: displayText, refreshDate: Date().addingTimeInterval(604800)) // 1 week
	}
	
	public func lookupFor(address: String) -> LookupResponse {
		guard let subRecord = records[BalanceService.addressCacheKey(forAddress: address)] else {
			return LookupResponse(displayText: address, type: .address, iconName: "Social_TZ_1color")
		}
		
		if let record = subRecord[.tezosDomain], record.displayText != "" {
			return LookupResponse(displayText: record.displayText, type: .tezosDomain, iconName: "Social_TZDomain_Color")
			
		} else if let record = subRecord[.google] {
			return LookupResponse(displayText: record.displayText, type: .google, iconName: "Social_Google_color")
			
		} else {
			return LookupResponse(displayText: address, type: .address, iconName: "Social_TZ_1color")
		}
	}
	
	public func cacheRecords() {
		let _ = DiskService.write(encodable: self.records, toFileName: LookupService.cacheKey)
	}
	
	public func deleteCache() {
		self.records = [:]
		let _ = DiskService.delete(fileName: LookupService.cacheKey)
	}
	
	
	
	
	
	
	
	
	
	/*
	private struct TorusLookupRequest: Codable {
		let jsonrpc: String
		let method: String
		let id: Int
		let params: TorusLookupRequestParams
	}
	
	private struct TorusLookupRequestParams: Codable {
		let pub_key_X: String
		let pub_key_Y: String
	}
	
	
	public func torusKeyLookup(forAddress address: String, completion: @escaping ((String?) -> Void)) {
		guard address.prefix(3) == "tz2" else {
			completion(nil)
			return
		}
		
		let baseURL = DependencyManager.shared.tezosClientConfig.primaryNodeURL
		DependencyManager.shared.tezosNodeClient.networkService.send(rpc: RPC.managerKey(forAddress: address), withBaseURL: baseURL) { [weak self] result in
			let torusLookupURLString = DependencyManager.shared.currentNetworkType == .mainnet ? "https://torus-19.torusnode.com/jrpc" : "https://teal-15-1.torusnode.com/jrpc"
			
			guard let res = try? result.get(), let torusLookupURL = URL(string: torusLookupURLString), let uncompressedKey = self?.uncompress(pk: res) else {
				completion(nil)
				return
			}
			
			let obj = TorusLookupRequest(jsonrpc: "2.0", method: "KeyLookupRequest", id: 10, params: TorusLookupRequestParams(pub_key_X: uncompressedKey.x, pub_key_Y: uncompressedKey.y))
			let jsonData = try? JSONEncoder().encode(obj)
			DependencyManager.shared.tezosNodeClient.networkService.request(url: torusLookupURL, isPOST: true, withBody: jsonData, forReturnType: [String: String].self) { result in
				completion(nil)
			}
		}
	}
	
	public func uncompress(pk: String) -> (x: String, y: String) {
		let decodePk = Base58Check.decode(string: pk, prefix: Prefix.Keys.Secp256k1.public)
		let uncompressedBytes = KeyPair.secp256k1PublicKey_uncompressed(fromBytes: decodePk ?? [])
		let minusPrefix = Array(uncompressedBytes[1..<uncompressedBytes.count])
		
		let x = minusPrefix[0..<32]
		let y = minusPrefix[32..<64]
		
		return (x: x.hexString, y: y.hexString)
	}
	*/
}
