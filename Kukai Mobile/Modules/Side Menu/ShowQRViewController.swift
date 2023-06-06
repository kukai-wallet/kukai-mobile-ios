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
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		if let logoImage = (UIImage(named: "Kukai") ?? UIImage()).cgImage {
			let doc = QRCode.Document(utf8String: address, errorCorrection: .high)
			doc.logoTemplate = QRCode.LogoTemplate(image: logoImage, path: CGPath(rect: CGRect(x: 0.35, y: 0.35, width: 0.30, height: 0.30), transform: nil), inset: 6)
			
			qrCodeImageView.image = doc.uiImage(CGSize(width: 160, height: 160))
		}
    }
}
