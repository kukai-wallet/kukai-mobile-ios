//
//  CollectiblesCollectionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import SDWebImage

class CollectiblesCollectionCell: UICollectionViewCell, UITableViewCellImageDownloading {
	
	@IBOutlet weak var collectionIcon: UIImageView!
	@IBOutlet weak var collectionName: UILabel!
	@IBOutlet weak var stackView: UIStackView!
	
	private var imageViews: [SDAnimatedImageView] = []
	private var lastLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
	private var gradientLayer: CAGradientLayer? = nil
	private var remainderCount: Int = 0
	private var displayCount: Int = 0
	private var previousGradientBounds = CGRect.zero
	
	func setup(title: String, displayCount: Int, totalCount: Int) {
		self.collectionName.text = title
		self.remainderCount = totalCount
		self.displayCount = displayCount
		
		if imageViews.count == 0 {
			for _ in 0..<displayCount {
				let imageView = SDAnimatedImageView(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
				imageView.translatesAutoresizingMaskIntoConstraints = false
				imageView.customCornerRadius = 6
				imageView.maskToBounds = true
				imageView.backgroundColor = .colorNamed("BG3")
				imageView.borderWidth = 1
				imageView.borderColor = .colorNamed("BG2")
				
				NSLayoutConstraint.activate([
					imageView.heightAnchor.constraint(equalToConstant: 54),
					imageView.widthAnchor.constraint(equalToConstant: 54)
				])
				
				imageViews.append(imageView)
				stackView.addArrangedSubview(imageView)
			}
			
			lastLabel.font = .custom(ofType: .bold, andSize: 14)
			lastLabel.textColor = .colorNamed("Txt14")
			lastLabel.textAlignment = .center
			
			imageViews.last?.addSubview(lastLabel)
		}
		
		collectionIcon.accessibilityIdentifier = "collecibtles-group-icon"
	}
	
	func setupCollectionImage(url: URL?) {
		MediaProxyService.load(url: url, to: collectionIcon, withCacheType: .temporary, fallback: UIImage.unknownToken(), downSampleSize: nil)
	}
	
	func setupImages(imageURLs: [URL?]) {
		let halfMegaByte: UInt = 500000
		
		for (index, imageView) in imageViews.enumerated() {
			if imageURLs.count > index, (remainderCount <= 0 || (remainderCount > 0 && index != imageViews.count-1)) {
				MediaProxyService.load(url: imageURLs[index], to: imageView, withCacheType: .temporary, fallback: UIImage.unknownGroup(), maxAnimatedImageSize: halfMegaByte)
			}
		}
		
		if remainderCount > 0 {
			lastLabel.text = "+\(remainderCount+1)" // +1 because we remove one of the images in order to display the remainder
			lastLabel.isHidden = false
			
		} else {
			lastLabel.isHidden = true
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if self.previousGradientBounds.width != self.contentView.bounds.width {
			addGradientBackground() // Strange loading issue. First time it loads these cells, width is 50% of what it should be
		}
	}
	
	public func addGradientBackground() {
		contentView.customCornerRadius = 8
		contentView.maskToBounds = true
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
		
		self.previousGradientBounds = self.contentView.bounds
	}
	
	override func prepareForReuse() {
		for imageView in imageViews {
			imageView.image = nil
			imageView.backgroundColor = .clear
		}
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return imageViews
	}
}
