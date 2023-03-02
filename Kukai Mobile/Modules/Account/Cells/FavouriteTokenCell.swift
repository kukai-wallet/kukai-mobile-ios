//
//  FavouriteTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit

class FavouriteTokenCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var favIcon: UIImageView!
	@IBOutlet weak var favIconStackview: UIStackView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var lockContainer: UIStackView!
	@IBOutlet weak var containerView: UIView!
	
	var gradientLayer = CAGradientLayer()
	private var myReorderImage: UIImage? = nil
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	func setup(isFav: Bool, isLocked: Bool) {
		if isFav {
			favIcon.image = UIImage(named: "FavoritesOn")
			
		} else {
			favIcon.image = UIImage(named: "FavoritesOff")
		}
		
		if isLocked {
			lockContainer.isHidden = false
		} else {
			lockContainer.isHidden = true
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		setEditView(editing: editing, withAnimation: true)
		
		if editing {
			for subViewA in self.subviews {
				if (subViewA.classForCoder.description() == "UITableViewCellReorderControl") {
					for subViewB in subViewA.subviews {
						if (subViewB.isKind(of: UIImageView.classForCoder())) {
							let imageView = subViewB as! UIImageView
							if (self.myReorderImage == nil) {
								let myImage = imageView.image
								myReorderImage = myImage?.withRenderingMode(.alwaysTemplate)
							}
							imageView.image = self.myReorderImage
							imageView.tintColor = UIColor.colorNamed("Grey1200")
							break
						}
					}
					break
				}
			}
		}
	}
	
	public func setEditView(editing: Bool, withAnimation: Bool) {
		favIconStackview.isHidden = editing
		
		if withAnimation {
			UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
				self?.layoutIfNeeded()
			}
		}
	}
}
