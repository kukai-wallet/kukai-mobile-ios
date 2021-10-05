//
//  LedgerScanningViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/10/2021.
//

import UIKit
import KukaiCoreSwift

class LedgerScanningViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var tableView: UITableView!
	
	private var deviceList: [String: String] = [:]
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.tableView.delegate = self
		self.tableView.dataSource = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		LedgerService.shared.setupBluetoothConnection { success in
			if !success {
				self.alert(errorWithMessage: "Unable to open bluetooth connection, please make sure bluetooth is turned on")
				self.navigationController?.popViewController(animated: true)
				return
			}
			
			LedgerService.shared.delegate = self
			LedgerService.shared.listenForDevices()
		}
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
		
		print("Searching for: \(selectedUUID)")
		
		self.showActivity(clearBackground: false)
		LedgerService.shared.connectTo(uuid: selectedUUID)
	}
}

extension LedgerScanningViewController: LedgerServiceDelegate {
	
	func deviceListUpdated(devices: [String : String]) {
		self.deviceList = devices
		self.tableView.reloadData()
	}
	
	func deviceConnectedStatus(success: Bool) {
		self.hideActivity()
		
		if !success {
			self.alert(errorWithMessage: "Unable to connect to device, please try again")
			return
		}
		
		LedgerService.shared.stopListening()
		self.performSegue(withIdentifier: "setup", sender: self)
	}
	
	func partialMessageSuccessReceived() {
		
	}
}
