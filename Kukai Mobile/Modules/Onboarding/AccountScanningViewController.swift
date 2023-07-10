//
//  AccountScanningViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 10/07/2023.
//

import UIKit

class AccountScanningViewController: UIViewController {

	@IBOutlet weak var spinnerImage: UIImageView!
	@IBOutlet weak var kukaiLogoImage: UIImageView!
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var scanningLabel: UILabel!
	@IBOutlet weak var numberLabel: UILabel!
	@IBOutlet weak var foundLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		numberLabel.text = "0"
    }
	
	public func hideAllText() {
		DispatchQueue.main.async { [weak self] in
			//self?.titleLabel.isHidden = true
			self?.scanningLabel.isHidden = true
			self?.numberLabel.isHidden = true
			self?.foundLabel.isHidden = true
		}
	}
	
	public func showAllText() {
		DispatchQueue.main.async { [weak self] in
			//self?.titleLabel.isHidden = false
			self?.scanningLabel.isHidden = false
			self?.numberLabel.isHidden = false
			self?.foundLabel.isHidden = false
		}
	}
	
	public func updateFound(_ found: Int) {
		DispatchQueue.main.async { [weak self] in
			self?.numberLabel.text = found.description
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		spinnerImage.rotate360Degrees(duration: 2)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		spinnerImage.stopRotate360Degrees()
	}
}
