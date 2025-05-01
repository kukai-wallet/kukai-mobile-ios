//
//  UnstakeReminderViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2024.
//

import UIKit
import KukaiCoreSwift
import EventKit

class UnstakeReminderViewController: UIViewController {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var createButton: CustomisableButton!
	@IBOutlet weak var cancelButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		GradientView.add(toView: containerView, withType: .modalBackground)
		createButton.customButtonType = .primary
		cancelButton.customButtonType = .secondary
		
		titleLabel.accessibilityIdentifier = "create-unstake-reminder-title"
		messageLabel.text = "Your unstake request has been submitted to the blockchain successfully. This will take ~\(UnstakeReminderViewController.numberOfDaysToUnstakeFormatted()) days to process, after which you must \"Finalise\" the request. \n\nWould you like to add a reminder to your calendar to alert you when this is ready?"
		
		createButton.accessibilityIdentifier = "create-button"
		cancelButton.accessibilityIdentifier = "cancel-button"
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		TransactionService.shared.didUnstake = false
	}
	
	@IBAction func createTapped(_ sender: Any) {
		self.showLoadingView()
		UnstakeReminderViewController.createUnstakeReminder { [weak self] error in
			self?.hideLoadingView()
			
			if let err = error {
				self?.windowError(withTitle: "error".localized(), description: err.description)
				
			} else {
				self?.dismiss(animated: true)
			}
		}
	}
	
	@IBAction func cancelTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
	
	public static func secondsToUnstake() -> Double {
		let secondsPerBlock = DependencyManager.shared.tezosNodeClient.networkConstants?.secondsBetweenBlocks() ?? 8
		let blocksPerCycle = DependencyManager.shared.tezosNodeClient.networkConstants?.blocks_per_cycle ?? 10800
		let unstakeCycleDelay = DependencyManager.shared.tezosNodeClient.networkConstants?.unstake_finalization_delay ?? 3
		
		return Double((blocksPerCycle * secondsPerBlock) * unstakeCycleDelay)
	}
	
	public static func numberOfDaysToUnstake() -> Double {
		return secondsToUnstake() / 60 / 60 / 24
	}
	
	public static func numberOfDaysToUnstakeFormatted() -> String {
		let rounded = Decimal(numberOfDaysToUnstake()).rounded(scale: 0, roundingMode: .bankers)
		return rounded.description
	}
	
	public static func createUnstakeReminder(completion: @escaping ((KukaiError?) -> Void)) {
		DependencyManager.shared.tzktClient.cycles { result in
			guard let res = try? result.get() else {
				DispatchQueue.main.async { completion(result.getFailure()) }
				return
			}
			
			let now = Date()
			var currentCycle: TzKTCycle? = nil
			
			for cycle in res {
				if (cycle.stateDate ?? now) < now && (cycle.endDate ?? now) > now {
					currentCycle = cycle
					break
				}
			}
			
			guard let current = currentCycle else {
				DispatchQueue.main.async { completion(KukaiError.internalApplicationError(error: AccountViewModelError.networkError)) }
				return
			}
			
			let secondsRemainingInCurrentCycle = current.endDate?.timeIntervalSince(now) ?? 0
			let secondsUntilReadyToFinalise = (secondsToUnstake()  * 1.05) + secondsRemainingInCurrentCycle
			var readyToFinaliseDate = Date(timeIntervalSinceNow: secondsUntilReadyToFinalise)
			let hourOfDay = Calendar.current.component(.hour, from: readyToFinaliseDate)
			var hoursToAdjust = 0
			
			// Adjust up/down so that it doesn't set an alert for too early/late e.g. 1am
			if hourOfDay < 9 {
				hoursToAdjust = 9 - hourOfDay
				
			} else if hourOfDay > 21 {
				hoursToAdjust = 12
			}
			
			readyToFinaliseDate.addTimeInterval( (Double(hoursToAdjust) * 60 * 60) )
			
			
			// Request only write access so long as its available, otherwise request full access
			let eventStore = EKEventStore()
			if #available(iOS 17.0, *) {
				eventStore.requestWriteOnlyAccessToEvents { (granted, error) in
					UnstakeReminderViewController.createEvent(readyToFinaliseDate: readyToFinaliseDate, eventStore: eventStore, granted: granted, error: error, completion: completion)
				}
			} else {
				eventStore.requestAccess(to: .event) { (granted, error) in
					UnstakeReminderViewController.createEvent(readyToFinaliseDate: readyToFinaliseDate, eventStore: eventStore, granted: granted, error: error, completion: completion)
				}
			}
		}
	}
	
	private static func createEvent(readyToFinaliseDate: Date, eventStore: EKEventStore, granted: Bool, error: Error?, completion: @escaping ((KukaiError?) -> Void)) {
		guard granted, error == nil else {
			DispatchQueue.main.async { completion(KukaiError.internalApplicationError(error: error ?? AccountViewModelError.calendarAccessError)) }
			return
		}
		
		let event = EKEvent(eventStore: eventStore)
		event.title = "Unstake ready to be finalised"
		event.startDate = readyToFinaliseDate
		event.endDate = readyToFinaliseDate.addingTimeInterval(60 * 60)
		event.notes = "Your recent unstake should now be ready to finalise. Open Kukai, tap on your XTZ balance, scroll down and tap \"Finalise\" to have your funds returned to your available balance"
		event.calendar = eventStore.defaultCalendarForNewEvents
		event.addAlarm(EKAlarm(absoluteDate: readyToFinaliseDate))
		
		do {
			try eventStore.save(event, span: .thisEvent)
			TransactionService.shared.didUnstake = false
			DispatchQueue.main.async { completion(nil) }
			
		} catch let error {
			DispatchQueue.main.async { completion(KukaiError.internalApplicationError(error: error)) }
		}
	}
}
