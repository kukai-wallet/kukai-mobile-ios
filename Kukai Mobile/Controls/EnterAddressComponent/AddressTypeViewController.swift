//
//  AddressTypeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import UIKit
import KukaiCoreSwift

public enum AddressType: String, CaseIterable {
	case tezosAddress = "Tezos Address"
	case tezosDomain = "Tezos Domain"
	case gmail = "Google"
	case reddit = "Reddit"
	case twitter = "Twitter"
}

public protocol AddressTypeDelegate: AnyObject {
	func addressTypeChosen(type: AddressType)
}

class AddressTypeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	
	public weak var delegate: AddressTypeDelegate? = nil
	public var selectedType: AddressType = .tezosAddress
	public var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		self.view.addSubview(tableView)
		self.tableView.delegate = self
		self.tableView.dataSource = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let sheetController = self.presentationController as? UISheetPresentationController {
			let customMediumHeight = UISheetPresentationController.Detent.custom { context in
				return context.maximumDetentValue * 0.90
			}
			
			sheetController.detents = [customMediumHeight, .large()]
			sheetController.prefersGrabberVisible = true
			sheetController.preferredCornerRadius = 30
			sheetController.prefersScrollingExpandsWhenScrolledToEdge = true
		}
	}
	
	static func imageFor(addressType: AddressType) -> UIImage {
		var tempMetadata = WalletMetadata(address: "", type: .regular, children: [], isChild: false, bas58EncodedPublicKey: "")
		
		switch addressType {
			case .tezosAddress:
				tempMetadata = WalletMetadata(address: "", type: .regular, children: [], isChild: false, bas58EncodedPublicKey: "")
				
			case .tezosDomain:
				tempMetadata = WalletMetadata(address: "", displayName: "", tezosDomain: "", type: .regular, children: [], isChild: false, bas58EncodedPublicKey: "")
				
			case .gmail:
				tempMetadata = WalletMetadata(address: "", displayName: "", socialType: .google, type: .social, children: [], isChild: false, bas58EncodedPublicKey: "")
				
			case .reddit:
				tempMetadata = WalletMetadata(address: "", displayName: "", socialType: .reddit, type: .social, children: [], isChild: false, bas58EncodedPublicKey: "")
				
			case .twitter:
				tempMetadata = WalletMetadata(address: "", displayName: "", socialType: .twitter, type: .social, children: [], isChild: false, bas58EncodedPublicKey: "")
		}
		
		return TransactionService.walletMedia(forWalletMetadata: tempMetadata, ofSize: .medium).image
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
	
	
	// MARK: - TableView
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return AddressType.allCases.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddressTypeCell", for: indexPath) as? AddressTypeCell else {
			return UITableViewCell()
		}
		
		let addressType = AddressType.allCases[indexPath.section]
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
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
		
		if indexPath == selectedIndex {
			cell.setSelected(true, animated: true)
			
		} else {
			cell.setSelected(false, animated: true)
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
