//
//  ActivityGenericCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/03/2022.
//

import UIKit

class ActivityGenericCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var prefixLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
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
	
	func setHasNoChildren() {
		chevronView.image = UIImage()
		self.selectionStyle = .none
	}
	
	func setHasChildren() {
		setClosed()
		self.selectionStyle = .default
	}
	
	func setClosed() {
		chevronView.image = UIImage(systemName: "chevron.right")
	}
	
	func setOpen() {
		chevronView.image = UIImage(systemName: "chevron.down")
	}
	
	func setSent() {
		iconView.image = UIImage(systemName: "arrow.up.right")
	}
	
	func setReceived() {
		iconView.image = UIImage(systemName: "arrow.down.right")
	}
}
