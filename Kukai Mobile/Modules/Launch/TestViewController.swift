//
//  TestViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/02/2025.
//

import UIKit

class TestViewController: UIViewController {

	@IBOutlet weak var placeholder: UIView!
	
	private let modelVc = ThreeDimensionModelViewController()
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.addChild(modelVc)
		self.placeholder.addSubview(modelVc.view)
		modelVc.view.frame = placeholder.bounds
		
		let urlToDownload = URL(string: "https://data.mantodev.com/media/mobile900/ipfs/QmVD7jNTXZZZWzRQWpkyrjxdAMEjSgTnYnVzvECDndgNQu")!
		modelVc.setAssetUrl(urlToDownload)
	}
}
