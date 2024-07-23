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
	
    override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		clearButton.customButtonType = .secondary
		setup()
    }
	
	func setup() {
		let total = (MediaProxyService.sizeOf(cache: .temporary) + MediaProxyService.sizeOf(cache: .detail))
		let imageCacheSize = total.description
		let int64 = Int64(imageCacheSize) ?? 0
		let collectibleStorageSize = ByteCountFormatter().string(fromByteCount: int64)
		
		storageLabel.text = collectibleStorageSize
	}

	@IBAction func clearButtonTapped(_ sender: Any) {
		self.showLoadingModal()
		
		MediaProxyService.removeAllImages(fromCache: .temporary) {
			MediaProxyService.removeAllImages(fromCache: .detail) { [weak self] in
				self?.setup()
				self?.hideLoadingModal(completion: { [weak self] in
					self?.dismissBottomSheet()
				})
			}
		}
	}
}
