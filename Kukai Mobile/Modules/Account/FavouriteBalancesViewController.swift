//
//  FavouriteBalancesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class FavouriteBalancesViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var reOrderButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = FavouriteBalancesViewModel()
	private var cancellable: AnyCancellable?
	private var isReOrder = false
	private let sectionFooterSpacer = UIView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionHeaderTopPadding = 0
		tableView.sectionHeaderHeight = 0
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
		sectionFooterSpacer.backgroundColor = .clear
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					self?.reOrderButton.isHidden = !(self?.viewModel.showReorderButton() ?? false)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
	
	@IBAction func reOrderButtonTapped(_ sender: Any) {
		isReOrder = !isReOrder
		
		if isReOrder {
			self.title = "Reorder Favorites"
			reOrderButton.setTitle("Done", for: .normal)
			
			viewModel.isEditing = isReOrder
			viewModel.refresh(animate: true)
			tableView.isEditing = isReOrder // set editing after cells removed, so old cells don't show edit then slide away
			
			let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FavouriteTokenCell
			cell?.setEditView(editing: true, withAnimation: true)
			
		} else {
			self.title = "Favorites"
			reOrderButton.setTitle("Reorder", for: .normal)
			
			tableView.isEditing = isReOrder // remove editing before cells added, so old cells appear without edit as they slide in
			viewModel.isEditing = isReOrder
			viewModel.refresh(animate: true)
			
			let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? FavouriteTokenCell
			cell?.setEditView(editing: false, withAnimation: true)
		}
	}
	
	
	
	// MARK: Tableview
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 62
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return sectionFooterSpacer
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		viewModel.handleTap(onTableView: tableView, atIndexPath: indexPath)
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard let c = cell as? FavouriteTokenCell else {
			return
		}
		
		if indexPath.section == 0 {
			c.tokenIcon.backgroundColor = .colorNamed("BG4")
			c.tokenIcon.image = UIImage.tezosToken().resizedImage(size: CGSize(width: 50, height: 50))
			
		} else if let token = viewModel.token(atIndexPath: indexPath) {
			c.tokenIcon.backgroundColor = .colorNamed("BG4")
			MediaProxyService.load(url: token.thumbnailURL, to: c.tokenIcon, withCacheType: .permanent, fallback: UIImage.unknownToken()) { res in
				if res != nil {
					c.tokenIcon.backgroundColor = .white
				} else {
					c.tokenIcon.backgroundColor = .colorNamed("BG4")
				}
			}
			
		} else {
			c.tokenIcon.backgroundColor = .colorNamed("BG4")
			c.tokenIcon.image = UIImage.unknownToken()
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard let cell = cell as? UITableViewCellImageDownloading else {
			return
		}
		
		cell.downloadingImageViews().forEach({ $0.sd_cancelCurrentImageLoad() })
	}
}
