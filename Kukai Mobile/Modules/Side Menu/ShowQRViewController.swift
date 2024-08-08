//
//  ShowQRViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/06/2023.
//

import UIKit
import QRCode

class ShowQRViewController: UIViewController {
	
	@IBOutlet weak var qrCodeImageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var copyButton: CustomisableButton!
	@IBOutlet weak var shareButton: CustomisableButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		let selectedMetdata = DependencyManager.shared.selectedWalletMetadata
		nameLabel.text = selectedMetdata?.walletNickname ?? "Account Address"
		addressLabel.text = selectedMetdata?.address.truncateTezosAddress() ?? "..."
		
		copyButton.customButtonType = .secondary
		shareButton.customButtonType = .secondary
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		if let logoImage = (UIImage(named: "Kukai") ?? UIImage()).cgImage {
			let doc = QRCode.Document(utf8String: address, errorCorrection: .high)
			doc.logoTemplate = QRCode.LogoTemplate(image: logoImage, path: CGPath(rect: CGRect(x: 0.35, y: 0.35, width: 0.30, height: 0.30), transform: nil), inset: 6)
			
			qrCodeImageView.image = doc.uiImage(CGSize(width: 186, height: 186))
		}
    }
	
	@IBAction func copyButtonTapped(_ sender: UIButton) {
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		
		Toast.shared.show(withMessage: "\(address.truncateTezosAddress()) copied!", attachedTo: sender)
		UIPasteboard.general.string = address
	}
	
	@IBAction func shareButtonTapped(_ sender: Any) {
		guard let address = DependencyManager.shared.selectedWalletMetadata?.address else {
			self.windowError(withTitle: "error".localized(), description: "error-no-wallet".localized())
			return
		}
		
		// set up activity view controller
		let textToShare = [ address  ]
		let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
		activityViewController.popoverPresentationController?.sourceView = self.view
		
		// exclude some activity types from the list (optional)
		activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
		
		// present the view controller
		self.present(activityViewController, animated: true, completion: nil)
	}
}
