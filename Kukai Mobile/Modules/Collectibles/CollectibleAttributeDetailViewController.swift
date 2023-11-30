//
//  CollectibleAttributeDetailViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2023.
//

import UIKit

class CollectibleAttributeDetailViewController: UIViewController {

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var percentageLabel: UILabel!
	
	public var attributeItem: AttributeItem? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let att = attributeItem {
			titleLabel.text = att.name
			descriptionLabel.text = att.value
			percentageLabel.text = att.percentage
		}
	}
}
