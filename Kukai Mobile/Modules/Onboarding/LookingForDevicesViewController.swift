//
//  LookingForDevicesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/07/2024.
//

import UIKit
import KukaiCoreSwift
import Combine

class LookingForDevicesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var spinnerImage: UIImageView!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var pairButton: CustomisableButton!
	@IBOutlet weak var palceholderView: UIView!
	
	private var bag = Set<AnyCancellable>()
	private var deviceList: [String: String] = [:]
	private var didStartReceiving = false
	private var selectedIndex: IndexPath? = nil
	
	public var walletToMigrate: WalletMetadata? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		pairButton.customButtonType = .primary
		
		self.tableView.alpha = 0
		self.tableView.delegate = self
		self.tableView.dataSource = self
		
		NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).sink { [weak self] _ in
			self?.startListening()
		}.store(in: &bag)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		pairButton.isEnabled = false
		spinnerImage.rotate360Degrees()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		startListening()
	}
	
	private func startListening() {
		
		if !didStartReceiving {
			self.tableView.reloadData()
			LedgerService.shared.listenForDevices()
				.convertToResult()
				.sink { [weak self] result in
					guard let devices = try? result.get() else {
						let error = (try? result.getError()) ?? KukaiError.unknown()
						self?.windowError(withTitle: "error".localized(), description: "Unable to search for devices, please check bluetooth is enabled and turned on. Error: \(error)")
						return
					}
					
					self?.didStartReceiving = true
					self?.deviceList = devices
					self?.tableView.reloadData()
				}
				.store(in: &bag)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		spinnerImage.stopRotate360Degrees()
		
		if self.isMovingFromParent {
			LedgerService.shared.disconnectFromDevice()
		}
		
		LedgerService.shared.stopListening()
		didStartReceiving = false
	}
	
	func animateTableViewIn() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.palceholderView.alpha = 0
			self?.tableView.alpha = 1
		}
	}
	
	func animateTableViewOut() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.palceholderView.alpha = 1
			self?.tableView.alpha = 0
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? DeviceConnectedViewController {
			vc.walletToMigrate = self.walletToMigrate
		}
	}
	
	@IBAction func pairTapped(_ sender: Any) {
		guard let selectedIndex = selectedIndex else {
			return
		}
		
		let itemIndex = deviceList.index(deviceList.startIndex, offsetBy: selectedIndex.row)
		let selectedUUID = deviceList.keys[itemIndex]
		TransactionService.shared.ledgerSetupData.selectedUUID = selectedUUID
		
		self.showLoadingModal(completion: nil)
		LedgerService.shared.connectTo(uuid: selectedUUID)
			.sink(onError: { [weak self] error in
				self?.hideLoadingModal(completion: nil)
				self?.windowError(withTitle: "error".localized(), description: "\( error )")
				
			}, onSuccess: { [weak self] success in
				self?.hideLoadingModal(completion: nil)
				
				if !success {
					self?.windowError(withTitle: "error".localized(), description: "Unable to connect to device, please try again")
					return
				}
				
				LedgerService.shared.stopListening()
				self?.performSegue(withIdentifier: "next", sender: self)
				self?.bag = Set<AnyCancellable>()
			})
			.store(in: &bag)
	}
	
	
	// MARK: - TableView
	
	func numberOfSections(in tableView: UITableView) -> Int {
		if didStartReceiving, deviceList.keys.count == 0 {
			self.animateTableViewOut()
		} else if didStartReceiving, deviceList.keys.count > 0 {
			self.animateTableViewIn()
		}
		
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return deviceList.keys.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "LedgerDeviceCell", for: indexPath)
		
		if let deviceCell = cell as? LedgerDeviceCell {
			let itemIndex = deviceList.index(deviceList.startIndex, offsetBy: indexPath.row)
			let uuid = deviceList.keys[itemIndex]
			let name = deviceList.values[itemIndex]
			deviceCell.setup(title: name, uuid: uuid)
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		pairButton.isEnabled = true
		deselectCurrentSelection()
		
		selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
	}
	
	private func deselectCurrentSelection() {
		guard let selectedIndex = selectedIndex else {
			return
		}
		
		tableView.deselectRow(at: selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: selectedIndex)
		previousCell?.setSelected(false, animated: true)
	}
}
