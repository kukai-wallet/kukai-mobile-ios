//
//  OnrampViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/08/2023.
//

import UIKit

class OnrampViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	
	private let ramps = [
		(title: "Coinbase", subtitle: "Transfer from Coinbase", image: "coinbase"),
		(title: "Transak", subtitle: "Bank transfers & local payment methods in 120+ countries", image: "transak"),
		(title: "Moonpay", subtitle: "Cards & banks transfers", image: "moonpay")
	]
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ =  self.view.addGradientBackgroundFull()
		
		tableView.dataSource = self
		tableView.delegate = self
    }
	
	@IBAction func infoButtonTapped(_ sender: Any) {
		self.alert(errorWithMessage: "Under Construction")
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ramps.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "TitleSubtitleImageContainerCell", for: indexPath) as? TitleSubtitleImageContainerCell else {
			return UITableViewCell()
		}
		
		let ramp = ramps[indexPath.row]
		cell.iconView.image = UIImage(named: ramp.image)
		cell.titleLabel.text = ramp.title
		cell.subtitleLabel.text = ramp.subtitle
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.alert(errorWithMessage: "Under Construction")
	}
}
