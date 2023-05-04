//
//  CollectionDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine

class CollectionDetailsViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate {
	
	@IBOutlet weak var navBarMiddleView: UIView!
	@IBOutlet weak var navBarMiddleImage: UIImageView!
	@IBOutlet weak var navBarMiddleLabel: UILabel!
	@IBOutlet weak var moreButton: CustomisableButton!
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectionDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	public var selectedToken: Token? = nil
	public var externalImage: UIImage? = nil
	public var externalName: String? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		let navBarMiddleViewWidth = self.view.frame.width - (32 + 44 + 20) // 16 * 2 for left/right gutter, 44 for right buttons, 20 for 10px spacing in between
		navBarMiddleView.addConstraint(NSLayoutConstraint(item: navBarMiddleView as Any, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: navBarMiddleViewWidth))
		navBarMiddleView.addConstraint(NSLayoutConstraint(item: navBarMiddleView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 28))
		
		moreButton.addConstraint(NSLayoutConstraint(item: moreButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		moreButton.addConstraint(NSLayoutConstraint(item: moreButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		viewModel.makeDataSource(withCollectionView: collectionView)
		viewModel.selectedToken = selectedToken
		viewModel.externalName = externalName
		viewModel.externalImage = externalImage
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		collectionView.collectionViewLayout = createLayout()
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					print("loading")
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		navBarMiddleImage.image = externalImage ?? UIImage.unknownToken() // TODO: if no external image use selected token
		navBarMiddleLabel.text = externalName ?? selectedToken?.name
		navBarMiddleView.transform = .init(translationX: 0, y: 44)
		
		viewModel.refresh(animate: false)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let padding: CGFloat = 70
		let adjustedOffset = (scrollView.contentOffset.y - padding)
		navBarMiddleView.transform = .init(translationX: 0, y: max(0, (44 - adjustedOffset)))
	}
	
	@IBAction func moreButtonTapped(_ sender: Any) {
	}
	
	
	private func createLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == 0 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 16
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
				return section
				
			} else {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.48), heightDimension: .estimated(204))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(204))
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
				
				group.interItemSpacing = .fixed(18)
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 16
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
				return section
			}
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
	}
}



/*
extension CollectionDetailsViewController: UICollectionViewDelegateFlowLayout {
	
	/*
	private func prepareSection0(forCollectionView collectionView: UICollectionView, withOffset sectionOffset: CGFloat) -> CGFloat {
		var yOffset = sectionOffset
		
		for cellIndex in 0 ..< collectionView.numberOfItems(inSection: 0) {
			let indexPath = IndexPath(row: cellIndex, section: 0)
			guard let contentView = delegate?.configuredCell(forIndexPath: indexPath).contentView else {
				continue
			}
			
			let requiredSize = contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: 44), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
			let frame = CGRect(x: 0, y: yOffset, width: requiredSize.width, height: requiredSize.height.rounded(.up))
			let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
			attributes.frame = frame
			cache[0].append(attributes)
			
			yOffset += requiredSize.height + cellPadding
		}
		
		return yOffset
	}
	*/
	
	
}
*/
