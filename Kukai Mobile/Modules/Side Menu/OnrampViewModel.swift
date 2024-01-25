//
//  OnrampViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/01/2024.
//

import UIKit
import KukaiCoreSwift

public struct OnrampOption: Codable, Hashable {
	let title: String
	let subtitle: String
	let imageName: String
	let key: String
}

class OnrampViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var ramps: [OnrampOption] = []
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? OnrampOption, let cell = tableView.dequeueReusableCell(withIdentifier: "TitleSubtitleImageContainerCell", for: indexPath) as? TitleSubtitleImageContainerCell {
				cell.iconView.image = UIImage(named: obj.imageName)
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		snapshot.appendItems([
			OnrampOption(title: "Coinbase", subtitle: "Transfer from your Coinbase account", imageName: "coinbase", key: "coinbase"),
			OnrampOption(title: "Transak", subtitle: "Bank transfers & local payment methods in 120+ countries", imageName: "transak", key: "transak"),
			OnrampOption(title: "Moonpay", subtitle: "Cards & banks transfers", imageName: "moonpay", key: "moonpay")
		], toSection: 0)
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	public func url(forIndexPath indexPath: IndexPath, completion: @escaping ((Result<URL, KukaiError>) -> Void)) {
		guard let ramp = dataSource?.itemIdentifier(for: indexPath) as? OnrampOption, let currentAddress = DependencyManager.shared.selectedWalletAddress else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		var baseURLString = ""
		switch ramp.key {
			case "coinbase":
				baseURLString = "https://pay.coinbase.com"
				buildCoinbaseURL(withBaseURL: baseURLString, andAddress: currentAddress, completion: completion)
				
			case "transak":
				baseURLString = "https://global.transak.com"
				buildTransakURL(withBaseURL: baseURLString, andAddress: currentAddress, completion: completion)
				
			case "moonpay":
				baseURLString = "https://buy.moonpay.com"
				signMoonPayUrl(withBaseURL: baseURLString, andAddress: currentAddress, completion: completion)
			
			default:
				completion(Result.failure(KukaiError.unknown()))
		}
		
	}
	
	private func buildCoinbaseURL(withBaseURL: String, andAddress address: String, completion: @escaping ((Result<URL, KukaiError>) -> Void)) {
		let appID = "aa41d510-15f9-4426-87bd-3a506b6e22c0"
		let walletData: [[String: Any]] = [
			[
				"address": address,
				"blockchains": [ "tezos" ]
			]
		]
		
		guard let jsonData = try? JSONSerialization.data(withJSONObject: walletData),
			  let jsonString = String(data: jsonData, encoding: .utf8),
			  let url = URL(string: "\(withBaseURL)/buy/select-asset?appId=\(appID)&destinationWallets=\(jsonString)") else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
			
		completion(Result.success(url))
	}
	
	private func buildTransakURL(withBaseURL: String, andAddress address: String, completion: @escaping ((Result<URL, KukaiError>) -> Void)) {
		let apiKey = "f1336570-699b-4181-9bd1-cdd57206981f" // "3b0e81f3-37dc-41f3-9837-bd8d2c350313" : "f1336570-699b-4181-9bd1-cdd57206981f"

		guard let url = URL(string: "\(withBaseURL)?apiKey=\(apiKey)&cryptoCurrencyCode=XTZ&walletAddressesData={\"coins\":{\"XTZ\":{\"address\":\"\(address)\"}}}&disableWalletAddressForm=true}") else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		completion(Result.success(url))
	}
	
	private func signMoonPayUrl(withBaseURL: String, andAddress address: String, completion: @escaping ((Result<URL, KukaiError>) -> Void)) {
		guard address.prefix(2).lowercased() == "tz", let kukaiServiceURL = URL(string: "https://utils.kukai.network/moonpay/sign") else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		let key = "pk_live_rP9HlBRO54nY4QKLxc6ONl4Prrm6vymK" // "pk_test_M23P0Zc5SvBORSFV63sfWKi7n5QbGZR" : "pk_live_rP9HlBRO54nY4QKLxc6ONl4Prrm6vymK"
		var query = "?apiKey=\(key)&colorCode=%237178E3&currencyCode=xtz&walletAddress=\(address)"
		
		let params: [String: Any] = [
			"dev": false,
			"url": query
		]
		
		let data = try? JSONSerialization.data(withJSONObject: params)
		DependencyManager.shared.tezosNodeClient.networkService.request(url: kukaiServiceURL, isPOST: true, withBody: data, forReturnType: Data.self) { result in
			guard let res = try? result.get(), let sigString = String(data: res, encoding: .utf8), let sanitised = sigString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			query += "&signature=\(sanitised))"
			
			if let url = URL(string: "\(withBaseURL)\(query)") {
				completion(Result.success(url))
			} else {
				completion(Result.failure(KukaiError.unknown()))
			}
		}
	}
}
