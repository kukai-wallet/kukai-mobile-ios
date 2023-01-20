//
//  MenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/01/2023.
//

import UIKit

class MenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
	
	private var actions: [UIAction] = []
	private weak var sourceVC: UIViewController? = nil
	private static let rowHeight: CGFloat = 56
	
	convenience init(actions: [UIAction], sourceViewController: UIViewController) {
		self.init(style: .plain)
		self.actions = actions
		self.sourceVC = sourceViewController
		
		self.tableView.backgroundColor = UIColor.colorNamed("Grey1600")
		self.tableView.separatorColor = UIColor.colorNamed("Grey1500")
	}
	
	func setup() {
		var height = MenuViewController.rowHeight * CGFloat(actions.count)
		if height > 350 {
			height = 350
		}
		
		modalPresentationStyle = .popover
		preferredContentSize = CGSize(width: 274, height: height)
		presentationController?.delegate = self
		popoverPresentationController?.permittedArrowDirections = []
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
		tableView.rowHeight = MenuViewController.rowHeight
		tableView.separatorInset = .zero
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.popoverPresentationController?.containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return actions.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
		let action = actions[indexPath.row]
		cell.textLabel?.text = action.title
		cell.textLabel?.textColor = UIColor.colorNamed("Grey400")
		cell.textLabel?.font = UIFont.custom(ofType: .bold, andSize: 18)
		
		let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
		var image = action.image
		image = image?.resizedImage(Size: imageView.frame.size)
		image = image?.withTintColor(.colorNamed("Brand1000"))
		imageView.image = image
		cell.accessoryView = imageView
		
		cell.backgroundColor = .clear
		cell.contentView.backgroundColor = .clear
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.dismiss(animated: true)
		actions[indexPath.row].performWithSender(nil, target: nil)
	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
	
	public func display(attachedTo sourceView: UIView) {
		self.setup()
		
		self.popoverPresentationController?.sourceView = sourceView
		self.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.origin.x, y: (preferredContentSize.height / 2) + sourceView.bounds.height, width: sourceView.bounds.width, height: sourceView.bounds.height)
		sourceVC?.present(self, animated: true, completion: nil)
	}
}
