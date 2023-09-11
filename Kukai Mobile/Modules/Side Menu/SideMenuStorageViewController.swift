//
//  SideMenuStorageViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/09/2023.
//

import UIKit
import KukaiCoreSwift

class SideMenuStorageViewController: UIViewController {
	
	@IBOutlet weak var storageLabel: UILabel!
	@IBOutlet weak var clearButton: CustomisableButton!
	
	private var gradient = CAGradientLayer()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
		clearButton.customButtonType = .secondary
		setup()
    }
	
	func setup() {
		let imageCacheSize = MediaProxyService.sizeOf(cache: .temporary).description
		let int64 = Int64(imageCacheSize) ?? 0
		let collectibleStorageSize = ByteCountFormatter().string(fromByteCount: int64)
		
		storageLabel.text = collectibleStorageSize
	}

	@IBAction func clearButtonTapped(_ sender: Any) {
		self.showLoadingModal()
		
		MediaProxyService.removeAllImages(fromCache: .temporary) { [weak self] in
			self?.setup()
			self?.hideLoadingModal(completion: { [weak self] in
				self?.dismissBottomSheet()
			})
		}
	}
}
