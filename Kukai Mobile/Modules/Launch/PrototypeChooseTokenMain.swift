//
//  PrototypeChooseTokenMain.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/06/2022.
//

import UIKit

class PrototypeChooseTokenMain: UIViewController {
	
	@IBOutlet weak var balancesButton: UIButton!
	@IBOutlet weak var collectiblesButton: UIButton!
	@IBOutlet weak var balancesContainer: UIView!
	@IBOutlet weak var collectiblesContainer: UIView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		collectiblesContainer.isHidden = true
		
		let appearance = UINavigationBarAppearance()
		appearance.configureWithOpaqueBackground()
		appearance.backgroundColor = UIColor(named: "primary-button-background")
		appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
		//appearance.shadowColor = .clear
		
		self.navigationController?.navigationBar.standardAppearance = appearance;
		self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
	}
	
	@IBAction func balancesTapped(_ sender: Any) {
		balancesContainer.isHidden = false
		collectiblesContainer.isHidden = true
		
		balancesButton.backgroundColor = UIColor.white
		balancesButton.setTitleColor(UIColor.black, for: .normal)
		
		collectiblesButton.backgroundColor = .clear
		collectiblesButton.setTitleColor(UIColor.white, for: .normal)
	}
	
	@IBAction func collectiblesTapped(_ sender: Any) {
		balancesContainer.isHidden = true
		collectiblesContainer.isHidden = false
		
		collectiblesButton.backgroundColor = UIColor.white
		collectiblesButton.setTitleColor(UIColor.black, for: .normal)
		
		balancesButton.backgroundColor = .clear
		balancesButton.setTitleColor(UIColor.white, for: .normal)
	}
}
