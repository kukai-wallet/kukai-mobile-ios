//
//  NetworkChooserViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift

class NetworkChooserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	
	private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		tableView.delegate = self
		tableView.dataSource = self
		
		let index = DependencyManager.shared.currentNetworkType == .mainnet ? 0 : 1
		selectedIndex = IndexPath(row: index, section: 0)
    }
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkChoiceCell", for: indexPath) as? NetworkChoiceCell else {
			return UITableViewCell()
		}
		
		if indexPath.row == 0 {
			cell.networkLabel.text = "Mainnet"
			cell.descriptionLabel.text = "Live network with real XTZ and Tokens with real values"
			
		} else {
			cell.networkLabel.text = "Ghostnet"
			cell.descriptionLabel.text = "A test network running the lastest Tezos protocol, with fake XTZ and tokens with no monetary value"
		}
		
		return cell
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		deselectCurrentSelection()
		
		selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		
		DependencyManager.shared.tezosNodeClient.networkVersion = nil
		if indexPath.row == 0 {
			DependencyManager.shared.setDefaultMainnetURLs()
		} else {
			DependencyManager.shared.setDefaultGhostnetURLs()
		}
		
		self.dismissBottomSheet()
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
	
	private func deselectCurrentSelection() {
		tableView.deselectRow(at: selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: selectedIndex)
		previousCell?.setSelected(false, animated: true)
	}
}
