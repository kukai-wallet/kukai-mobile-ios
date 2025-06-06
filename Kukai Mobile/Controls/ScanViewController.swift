//
//  ScanViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/08/2021.
//

// Modified from: https://www.hackingwithswift.com/example-code/media/how-to-scan-a-qr-code

import AVFoundation
import KukaiCryptoSwift
import UIKit
import Combine
import os.log

protocol ScanViewControllerDelegate: AnyObject {
	func scannedQRCode(code: String)
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	var captureSession: AVCaptureSession?
	var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
	
	let scrollView = AutoScrollView()
	let titleLabel = UILabel()
	let previewContainerView = UIView()
	let blurEffectView = UIVisualEffectView()
	let blurEffectMaskLayer = CAShapeLayer()
	let transparentView = UIView()
	let modalBackButton = CustomisableButton()
	private var isOnMac = ProcessInfo.processInfo.isiOSAppOnMac
	
	public var withTextField: Bool = false
	let textfield = ValidatorTextField()
	let pasteButton = CustomisableButton(configuration: .plain(), primaryAction: nil)
	
	weak var delegate: ScanViewControllerDelegate?
	
	private var bag = [AnyCancellable]()
	private var previousString = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		if UIDevice.current.userInterfaceIdiom == .pad {
			self.preferredContentSize = CGSize(width: 400, height: 600)
		}
		
		setupNav()
		setupPreviewView()
		setupClearBox()
		setupOutlineView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		textfield.text = nil
		
		guard !isOnMac else { return }
		
		let status = AVCaptureDevice.authorizationStatus(for: .video)
		if status == .authorized {
			setupCaptureSession()
			setupPreviewLayer()
			startCaptureSessionIfNeeded()
			
		} else if status == .notDetermined {
			AVCaptureDevice.requestAccess(for: .video) { [weak self] (response) in
				DispatchQueue.main.async {
					if response {
						self?.setupCaptureSession()
						self?.setupPreviewLayer()
						self?.startCaptureSessionIfNeeded()
					} else {
						self?.failed()
					}
				}
			}
		} else {
			self.failed()
		}
		
		scrollView.setupAutoScroll(focusView: textfield, parentView: self.view)
		scrollView.autoScrollDelegate = self
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		scrollView.stopAutoScroll()
		
		if (captureSession?.isRunning == true) {
			DispatchQueue.global(qos: .background).async { [weak self] in
				self?.captureSession?.stopRunning()
			}
		}
	}
	
	@objc func back() {
		self.dismiss(animated: true, completion: nil)
	}
	
	func startCaptureSessionIfNeeded() {
		if (captureSession?.isRunning == false) {
			// Xcode warning, should be run on a background thread in order to avoid hanging UI thread
			DispatchQueue.global(qos: .background).async { [weak self] in
				self?.captureSession?.startRunning()
			}
		}
	}
	
	@objc func textFieldDone() {
		checkForBeaconAndReport(stringToCheck: textfield.text ?? "")
	}
	
	func setupNav() {
		titleLabel.text = "Scan QR Code"
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.textColor = .colorNamed("Txt2")
		titleLabel.numberOfLines = 0
		titleLabel.textAlignment = .center
		titleLabel.font = .custom(ofType: .bold, andSize: 20)
		self.view.addSubview(titleLabel)
		
		modalBackButton.imageWidth = 18
		modalBackButton.imageHeight = 18
		modalBackButton.customImage = UIImage(named: "Close") ?? UIImage()
		modalBackButton.customImageTint = .colorNamed("BGB4")
		modalBackButton.tintColor = .colorNamed("BGB4")
		modalBackButton.translatesAutoresizingMaskIntoConstraints = false
		modalBackButton.addTarget(self, action: #selector(back), for: .touchUpInside)
		self.view.addSubview(modalBackButton)
		
		scrollView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(scrollView)
		
		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24),
			titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
			titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
			titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
			
			modalBackButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -24),
			modalBackButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
			modalBackButton.heightAnchor.constraint(equalToConstant: 44),
			modalBackButton.widthAnchor.constraint(equalToConstant: 44),
			
			scrollView.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 16),
			scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
			scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
			scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
		])
	}
	
	func setupPreviewView() {
		previewContainerView.translatesAutoresizingMaskIntoConstraints = false
		scrollView.addSubview(previewContainerView)
		
		blurEffectView.translatesAutoresizingMaskIntoConstraints = false
		blurEffectView.frame = previewContainerView.bounds
		blurEffectView.effect = UIBlurEffect(style: UIBlurEffect.Style.light)
		blurEffectView.alpha = 0.8
		previewContainerView.addSubview(blurEffectView)
		
		NSLayoutConstraint.activate([
			previewContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
			previewContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
			previewContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
			previewContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			previewContainerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			previewContainerView.heightAnchor.constraint(equalTo: previewContainerView.widthAnchor),
			
			blurEffectView.topAnchor.constraint(equalTo: previewContainerView.topAnchor),
			blurEffectView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor),
			blurEffectView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor),
			blurEffectView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor)
		])
		
		
		if withTextField {
			let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
			paddingView.backgroundColor = .clear
			
			textfield.backgroundColor = .colorNamed("BG4")
			textfield.translatesAutoresizingMaskIntoConstraints = false
			textfield.customCornerRadius = 8
			textfield.placeholder = "Paste Code Here"
			textfield.placeholderColor = .colorNamed("Txt10")
			textfield.addDoneToolbar(onDone: (target: self, action: #selector(textFieldDone)))
			textfield.autocorrectionType = .no
			textfield.textContentType = .none
			textfield.autocapitalizationType = .none
			textfield.spellCheckingType = .no
			textfield.isEnabled = true
			textfield.leftViewMode = .always
			textfield.leftView = paddingView
			textfield.font = .custom(ofType: .bold, andSize: 14)
			textfield.textColor = .colorNamed("Txt2")
			scrollView.addSubview(textfield)
			
			pasteButton.translatesAutoresizingMaskIntoConstraints = false
			pasteButton.accessibilityIdentifier = "paste-button"
			pasteButton.imageWidth = 26
			pasteButton.imageHeight = 26
			pasteButton.customImage = UIImage(named: "Paste") ?? UIImage()
			pasteButton.customImageTint = .colorNamed("BGB4")
			//pasteButton.borderColor = .colorNamed("BtnStrokeSec1")
			//pasteButton.borderWidth = 1
			//pasteButton.customCornerRadius = 8
			//pasteButton.configuration?.imagePlacement = .trailing
			//pasteButton.configuration?.imagePadding = 6
			pasteButton.configuration?.baseBackgroundColor = .colorNamed("BtnSec1")
			/*pasteButton.configuration?.attributedTitle = AttributedString("Paste", attributes: AttributeContainer( [
			 NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 14) as Any,
			 NSAttributedString.Key.foregroundColor: UIColor.colorNamed("TxtBtnSec1") as Any
			 ] ))*/
			
			pasteButton.addAction(UIAction(handler: { [weak self] _ in
				DispatchQueue.global(qos: .background).async {
					guard let paste = UIPasteboard.general.string else {
						return
					}
					
					DispatchQueue.main.async {
						self?.textfield.text = paste
						self?.textFieldDone()
					}
				}
			}), for: .touchUpInside)
			
			scrollView.addSubview(pasteButton)
			
			NSLayoutConstraint.activate([
				textfield.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
				textfield.trailingAnchor.constraint(equalTo: self.pasteButton.leadingAnchor, constant: -16),
				textfield.topAnchor.constraint(equalTo: self.previewContainerView.bottomAnchor, constant: 24),
				textfield.heightAnchor.constraint(equalToConstant: 36),
				
				textfield.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -24),
				
				pasteButton.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
				pasteButton.centerYAnchor.constraint(equalTo: self.textfield.centerYAnchor, constant: 0),
				pasteButton.widthAnchor.constraint(equalToConstant: 36),
				pasteButton.heightAnchor.constraint(equalToConstant: 36),
			])
		}
	}
	
	func setupClearBox() {
		blurEffectMaskLayer.removeFromSuperlayer()
		
		let path = UIBezierPath(roundedRect: blurEffectView.frame, cornerRadius: 0)
		let clearBoxPath = CGPath(roundedRect: blurEffectView.frame.insetBy(dx: 35, dy: 35), cornerWidth: 12, cornerHeight: 12, transform: nil)
		path.append(UIBezierPath(cgPath: clearBoxPath))
		path.usesEvenOddFillRule = true
		 
		blurEffectMaskLayer.path = path.cgPath
		blurEffectMaskLayer.fillRule = CAShapeLayerFillRule.evenOdd
		blurEffectView.layer.mask = blurEffectMaskLayer
	}
	
	func setupOutlineView() {
		transparentView.backgroundColor = .clear
		transparentView.borderWidth = 3
		transparentView.borderColor = .white
		transparentView.translatesAutoresizingMaskIntoConstraints = false
		transparentView.customCornerRadius = 12
		blurEffectView.contentView.addSubview(transparentView)
		 
		NSLayoutConstraint.activate([
			transparentView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor, constant: 32),
			transparentView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor, constant: -32),
			transparentView.topAnchor.constraint(equalTo: previewContainerView.topAnchor, constant: 32),
			transparentView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor, constant: -32)
		])
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		previewLayer.frame = previewContainerView.bounds
		setupClearBox()
	}
	
	func setupCaptureSession() {
		captureSession = AVCaptureSession()
		
		guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch {
			return
		}
		
		if captureSession?.canAddInput(videoInput) == true {
			captureSession?.addInput(videoInput)
		} else {
			failed()
			return
		}
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if captureSession?.canAddOutput(metadataOutput) == true {
			captureSession?.addOutput(metadataOutput)
			
			metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			metadataOutput.metadataObjectTypes = [.qr]
		} else {
			failed()
			return
		}
	}
	
	func setupPreviewLayer() {
		guard let session = captureSession else {
			return
		}
		
		if previewLayer.superlayer != nil {
			previewLayer.removeFromSuperlayer()
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: session)
		previewLayer.frame = previewContainerView.bounds
		previewLayer.videoGravity = .resizeAspectFill
		previewContainerView.layer.insertSublayer(previewLayer, at: 0)
		
		view.setNeedsLayout()
	}
	
	func failed() {
		let permissionsDenied = AVCaptureDevice.authorizationStatus(for: .video) == .denied
		var alertController: UIAlertController? = nil
		
		if permissionsDenied {
			os_log(.error, log: .default, "User revoked camera permissions")
			alertController = UIAlertController(title: "error".localized(), message: "This app does not have permission to access the camera. If you wish to scan a QRCode, please go to settings and enable camera access", preferredStyle: .alert)
			
			let systemSettingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
				guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
					return
				}
				
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: nil)
				}
			}
			
			alertController?.addAction(UIAlertAction(title: "Cancel", style: .default))
			alertController?.addAction(systemSettingsAction)
			
		} else {
			os_log(.error, log: .default, "Unable to scan on this device")
			alertController = UIAlertController(title: "error".localized(), message: "Unbale to setup camera at this time. Please check camera access is enabled in settings", preferredStyle: .alert)
			alertController?.addAction(UIAlertAction(title: "Ok", style: .default))
		}
		
		if let ac = alertController {
			self.present(ac, animated: true, completion: nil)
		}
		captureSession = nil
	}
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		
		if let metadataObject = metadataObjects.first {
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
			guard let stringValue = readableObject.stringValue else { return }
			
			if previousString != stringValue {
				AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
				previousString = stringValue
				checkForBeaconAndReport(stringToCheck: stringValue)
			}
		}
	}
	
	private func checkForBeaconAndReport(stringToCheck: String) {
		
		if stringToCheck.prefix(8) == "tezos://" {
			self.windowError(withTitle: "error".localized(), description: "error-beacon-not-supported".localized())
			self.textfield.text = ""
			
		} else if let data = Base58Check.decode(stringToCheck), let json = try? JSONSerialization.jsonObject(with: data) as? [String: String], let _ = json["relayServer"], let _ = json["publicKey"] {
			self.windowError(withTitle: "error".localized(), description: "error-beacon-not-supported".localized())
			self.textfield.text = ""
			
		} else {
			found(code: stringToCheck)
		}
	}
	
	func found(code: String) {
		os_log(.debug, log: .default, "Scanned QR code: %@", code)
		
		if self.isModal {
			self.dismiss(animated: true) { [weak self] in
				self?.delegate?.scannedQRCode(code: code)
			}
		} else {
			delegate?.scannedQRCode(code: code)
			self.navigationController?.popViewController(animated: true)
		}
	}
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
	
	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}
}

extension ScanViewController: AutoScrollViewDelegate {
	
	func keyboardWillShow() {
		//self.topSectionContainer.alpha = 0.2
		//self.topSectionContainer.isUserInteractionEnabled = false
	}
	
	func keyboardWillHide() {
		//self.topSectionContainer.alpha = 1
		//self.topSectionContainer.isUserInteractionEnabled = true
	}
}
