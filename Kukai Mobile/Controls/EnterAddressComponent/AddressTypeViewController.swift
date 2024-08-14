//
//  AddressTypeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import UIKit
import KukaiCoreSwift
import CloudKit

public enum AddressType: String, CaseIterable {
	case tezosAddress = "Tezos Address"
	case tezosDomain = "Tezos Domain"
	case gmail = "Google"
	case reddit = "Reddit"
	case twitter = "Twitter"
	case email = "Email"
}

public protocol AddressTypeDelegate: AnyObject {
	func addressTypeChosen(type: AddressType)
}

class AddressTypeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	public weak var delegate: AddressTypeDelegate? = nil
	public var selectedType: AddressType = .tezosAddress
	public var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	public var headerText: String = "Recipient Address"
	public var supportedAddressTypes: [AddressType] = [.tezosAddress, .tezosDomain, .gmail, .reddit, .twitter, .email]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		self.view.addSubview(tableView)
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.titleLabel.text = headerText
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let sheetController = self.presentationController as? UISheetPresentationController {
			sheetController.detents = [.large()]
			sheetController.prefersGrabberVisible = true
			sheetController.preferredCornerRadius = 30
			sheetController.prefersScrollingExpandsWhenScrolledToEdge = true
		}
	}
	
	static func imageFor(addressType: AddressType) -> UIImage {
		var tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, type: .regular, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
		
		switch addressType {
			case .tezosAddress:
				tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, type: .regular, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
				
			case .tezosDomain:
				let fakeRecord = TezosDomainsReverseRecord(id: "123", address: "123", owner: "123", expiresAtUtc: "123", domain: TezosDomainsDomain(name: "123", address: "123"))
				tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, mainnetDomains: [fakeRecord], ghostnetDomains: [fakeRecord], type: .regular, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
				
			case .gmail:
				tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: .google, type: .social, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
				
			case .reddit:
				tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: .reddit, type: .social, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
				
			case .twitter:
				tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: .twitter, type: .social, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
				
			case .email:
				tempMetadata = WalletMetadata(address: "", hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: .email, type: .social, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: false, customDerivationPath: nil)
		}
		
		return TransactionService.walletMedia(forWalletMetadata: tempMetadata, ofSize: .size_22).image
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
	
	
	// MARK: - TableView
	
	func numberOfSections(in tableView: UITableView) -> Int {
		//return AddressType.allCases.count
		return supportedAddressTypes.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddressTypeCell", for: indexPath) as? AddressTypeCell else {
			return UITableViewCell()
		}
		
		//let addressType = AddressType.allCases[indexPath.section]
		let addressType = supportedAddressTypes[indexPath.section]
		cell.titleLabel?.text = addressType.rawValue
		cell.iconView.image = AddressTypeViewController.imageFor(addressType: addressType)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
		view.backgroundColor = .clear
		return view
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath == selectedIndex {
			cell.setSelected(true, animated: false)
			
		} else {
			cell.setSelected(false, animated: false)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: selectedIndex)
		previousCell?.setSelected(false, animated: true)
		
		let choice = AddressType.allCases[indexPath.section]
		selectedIndex = indexPath
		selectedType = choice
		
		self.delegate?.addressTypeChosen(type: choice)
		self.dismiss(animated: true)
	}
}
