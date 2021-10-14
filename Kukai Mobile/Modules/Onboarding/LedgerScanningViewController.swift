//
//  LedgerScanningViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/10/2021.
//

import UIKit
import KukaiCoreSwift
import Combine

class LedgerScanningViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var tableView: UITableView!
	
	private var bag = Set<AnyCancellable>()
	private var deviceList: [String: String] = [:]
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		LedgerService.shared.listenForDevices()
			.convertToResult()
			.sink { [weak self] result in
				guard let devices = try? result.get() else {
					let error = (try? result.getError()) ?? ErrorResponse.unknownError()
					self?.alert(errorWithMessage: "Error from ledger: \( error )")
					return
				}
				
				self?.deviceList = devices
				self?.tableView.reloadData()
			}
			.store(in: &bag)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return deviceList.keys.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: LedgerDeviceCell.reuseIdentifier, for: indexPath)
		
		if let deviceCell = cell as? LedgerDeviceCell {
			let itemIndex = deviceList.index(deviceList.startIndex, offsetBy: indexPath.row)
			let uuid = deviceList.keys[itemIndex]
			let name = deviceList.values[itemIndex]
			deviceCell.setup(name: name, uuid: uuid)
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let itemIndex = deviceList.index(deviceList.startIndex, offsetBy: indexPath.row)
		let selectedUUID = deviceList.keys[itemIndex]
		
		self.showActivity(clearBackground: false)
		LedgerService.shared.connectTo(uuid: selectedUUID)
			.sink(onError: { [weak self] error in
				self?.hideActivity()
				self?.alert(errorWithMessage: "Error from ledger: \( error )")
				
			}, onSuccess: { [weak self] success in
				self?.hideActivity()
				
				if !success {
					self?.alert(errorWithMessage: "Unable to connect to device, please try again")
					return
				}
				
				LedgerService.shared.stopListening()
				self?.performSegue(withIdentifier: "setup", sender: self)
			})
			.store(in: &bag)
	}
}
