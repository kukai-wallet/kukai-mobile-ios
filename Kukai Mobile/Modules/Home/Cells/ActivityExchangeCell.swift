//
//  ActivityExchangeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/03/2022.
//

import UIKit

class ActivityExchangeCell: UITableViewCell {

	@IBOutlet weak var sentLabel: UILabel!
	@IBOutlet weak var receivedLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var chevronView: UIImageView!
	
	private var timer: Timer? = nil
	public var date: Date? = nil {
		didSet {
			if timer == nil {
				self.dateLabel.text = self.date?.timeAgoDisplay()
				
				timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { [weak self] timer in
					self?.dateLabel.text = self?.date?.timeAgoDisplay()
				})
			}
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		timer?.invalidate()
		timer = nil
	}
	
	func setClosed() {
		chevronView.image = UIImage(systemName: "chevron.right")
	}
	
	func setOpen() {
		chevronView.image = UIImage(systemName: "chevron.down")
	}
}
