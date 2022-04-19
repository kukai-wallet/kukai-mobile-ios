//
//  ThemePickerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/04/2022.
//

import UIKit

public class ThemePickerViewController: UITableViewController {
	
	private var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		selectedIndex = index(forTheme: ThemeSelector.shared.selectedTheme)
		self.tableView.cellForRow(at: selectedIndex)?.accessoryType = .checkmark
	}
	
	public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.cellForRow(at: selectedIndex)?.accessoryType = .none
		self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		
		selectedIndex = indexPath
		ThemeSelector.shared.selectedTheme = theme(forIndex: indexPath)
		
		self.navigationController?.popToRootViewController(animated: true)
	}
	
	private func index(forTheme theme: ThemeSelector.Theme) -> IndexPath {
		switch ThemeSelector.shared.selectedTheme {
			case .light:
				return IndexPath(row: 0, section: 0)
				
			case .dark:
				return IndexPath(row: 1, section: 0)
				
			case .red:
				return IndexPath(row: 2, section: 0)
				
			case .blue:
				return IndexPath(row: 3, section: 0)
		}
	}
	
	private func theme(forIndex index: IndexPath) -> ThemeSelector.Theme {
		switch index.row {
			case 0:
				return .light
				
			case 1:
				return .dark
				
			case 2:
				return .red
				
			case 3:
				return .blue
			
			default:
				return .light
		}
	}
}
