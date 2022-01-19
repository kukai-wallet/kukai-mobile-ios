//
//  Option1AllViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import UIKit

public class Option1AllViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.dataSource = self
		self.tableView.delegate = self
		self.tableView.reloadData()
	}
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if PrototypeData.shared.selected == .token {
			return DependencyManager.shared.currentAccount?.tokens.count ?? 0
		} else {
			return DependencyManager.shared.currentAccount?.nfts.count ?? 0
		}
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if PrototypeData.shared.selected == .token {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell, let token = DependencyManager.shared.currentAccount?.tokens[indexPath.row] else {
				return UITableViewCell()
			}
			
			cell.tokenIconView.setKuakiImage(withURL: token.thumbnailURL, downSampleStandardImage: (width: 30, height: 30))
			cell.titleLabel.text = "\(token.balance.normalisedRepresentation) \(token.symbol)"
			return cell
		} else {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell, let token = DependencyManager.shared.currentAccount?.nfts[indexPath.row] else {
				return UITableViewCell()
			}
			
			cell.tokenIconView.setKuakiImage(withURL: token.thumbnailURL, downSampleStandardImage: (width: 30, height: 30))
			cell.titleLabel.text = token.name
			return cell
		}
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		PrototypeData.shared.selectedIndex = indexPath.row
		self.performSegue(withIdentifier: detailSegueID(), sender: indexPath)
	}
	
	public func detailSegueID() -> String {
		if PrototypeData.shared.selectedOption == 1 {
			return "detail-sheet"
			
		} else if PrototypeData.shared.selectedOption == 2 {
			return "detail-push"
			
		} else if PrototypeData.shared.selectedOption == 3 {
			return "detail-sheet"
		}
		
		return ""
	}
}
