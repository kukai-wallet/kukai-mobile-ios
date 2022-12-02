//
//  AddressTypeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import UIKit

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
	
	private let tableView = UITableView()
	public weak var delegate: AddressTypeDelegate? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.addSubview(tableView)
		self.tableView.translatesAutoresizingMaskIntoConstraints = false
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basicCell")
		
		NSLayoutConstraint.activate([
			tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
			tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
			tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8),
			tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
		])
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let sheetController = self.presentationController as? UISheetPresentationController {
			sheetController.detents = [.medium()]
			sheetController.prefersGrabberVisible = false
			sheetController.preferredCornerRadius = 20
			sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
		}
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return AddressType.allCases.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
		cell.textLabel?.text = AddressType.allCases[indexPath.row].rawValue
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let choice = AddressType.allCases[indexPath.row]
		self.delegate?.addressTypeChosen(type: choice)
		self.dismiss(animated: true)
	}
}
