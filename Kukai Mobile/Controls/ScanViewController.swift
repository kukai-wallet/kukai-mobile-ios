//
//  ScanViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/08/2021.
//

// Modified from: https://www.hackingwithswift.com/example-code/media/how-to-scan-a-qr-code

import AVFoundation
import UIKit
import os.log

protocol ScanViewControllerDelegate: AnyObject {
	func scannedQRCode(code: String)
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	var captureSession: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer! = AVCaptureVideoPreviewLayer()
	
	let titleLabel = UILabel()
	let previewContainerView = UIView()
	let blurEffectView = UIVisualEffectView()
	let blurEffectMaskLayer = CAShapeLayer()
	let transparentView = UIView()
	let modalBackButton = CustomisableButton()
	
	public var withTextField: Bool = false
	let textfield = UITextField()
	let pasteButton = CustomisableButton(configuration: .plain(), primaryAction: nil)
	
	weak var delegate: ScanViewControllerDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		setupNav()
		setupPreviewView()
		setupClearBox()
		setupOutlineView()
		
		AVCaptureDevice.requestAccess(for: .video) { [weak self] (response) in
			DispatchQueue.main.async {
				if response {
					self?.setupVideoPreview()
				} else {
					self?.failed()
				}
			}
		}
	}
	
	@objc func back() {
		self.dismiss(animated: true, completion: nil)
	}
	
	@objc func textFieldDone() {
		found(code: textfield.text ?? "")
	}
	
	@objc func pasteButtonTapped() {
		self.textfield.text = UIPasteboard.general.string
		self.textFieldDone()
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
		
		NSLayoutConstraint.activate([
			titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 24),
			titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
			titleLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
			titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
			
			modalBackButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -24),
			modalBackButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
			modalBackButton.heightAnchor.constraint(equalToConstant: 44),
			modalBackButton.widthAnchor.constraint(equalToConstant: 44)
		])
	}
	
	func setupPreviewView() {
		previewContainerView.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(previewContainerView)
		
		blurEffectView.translatesAutoresizingMaskIntoConstraints = false
		blurEffectView.frame = previewContainerView.bounds
		blurEffectView.effect = UIBlurEffect(style: UIBlurEffect.Style.light)
		blurEffectView.alpha = 0.8
		previewContainerView.addSubview(blurEffectView)
		
		NSLayoutConstraint.activate([
			previewContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
			previewContainerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			previewContainerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			previewContainerView.heightAnchor.constraint(equalTo: previewContainerView.widthAnchor),
			
			blurEffectView.topAnchor.constraint(equalTo: previewContainerView.topAnchor),
			blurEffectView.leadingAnchor.constraint(equalTo: previewContainerView.leadingAnchor),
			blurEffectView.trailingAnchor.constraint(equalTo: previewContainerView.trailingAnchor),
			blurEffectView.bottomAnchor.constraint(equalTo: previewContainerView.bottomAnchor)
		])
		
		
		if withTextField {
			textfield.backgroundColor = .colorNamed("BG4")
			textfield.translatesAutoresizingMaskIntoConstraints = false
			textfield.customCornerRadius = 8
			textfield.placeholder = "... or paste"
			textfield.addDoneToolbar(onDone: (target: self, action: #selector(textFieldDone)))
			textfield.autocorrectionType = .no
			textfield.textContentType = .none
			textfield.autocapitalizationType = .none
			textfield.spellCheckingType = .no
			textfield.isEnabled = false
			self.view.addSubview(textfield)
			
			pasteButton.translatesAutoresizingMaskIntoConstraints = false
			pasteButton.imageWidth = 14
			pasteButton.imageHeight = 14
			pasteButton.customImage = UIImage(named: "Paste") ?? UIImage()
			pasteButton.customImageTint = .colorNamed("BGB4")
			pasteButton.borderColor = .colorNamed("BtnStrokeSec1")
			pasteButton.borderWidth = 1
			pasteButton.customCornerRadius = 8
			pasteButton.configuration?.imagePlacement = .trailing
			pasteButton.configuration?.imagePadding = 6
			pasteButton.configuration?.baseBackgroundColor = .colorNamed("BtnSec1")
			pasteButton.configuration?.attributedTitle = AttributedString("Paste", attributes: AttributeContainer( [
				NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 14) as Any,
				NSAttributedString.Key.foregroundColor: UIColor.colorNamed("TxtBtnSec1") as Any
			] ))
			
			pasteButton.addTarget(self, action: #selector(pasteButtonTapped), for: .touchUpInside)
			self.view.addSubview(pasteButton)
			
			NSLayoutConstraint.activate([
				textfield.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
				textfield.trailingAnchor.constraint(equalTo: self.pasteButton.leadingAnchor, constant: -16),
				textfield.topAnchor.constraint(equalTo: self.previewContainerView.bottomAnchor, constant: 24),
				textfield.heightAnchor.constraint(equalToConstant: 36),
				
				pasteButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
				pasteButton.centerYAnchor.constraint(equalTo: self.textfield.centerYAnchor, constant: 0),
				pasteButton.widthAnchor.constraint(equalToConstant: 90),
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
	
	func setupVideoPreview() {
		captureSession = AVCaptureSession()
		
		guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch {
			return
		}
		
		if (captureSession.canAddInput(videoInput)) {
			captureSession.addInput(videoInput)
		} else {
			failed()
			return
		}
		
		let metadataOutput = AVCaptureMetadataOutput()
		
		if (captureSession.canAddOutput(metadataOutput)) {
			captureSession.addOutput(metadataOutput)
			
			metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			metadataOutput.metadataObjectTypes = [.qr]
		} else {
			failed()
			return
		}
		
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.frame = previewContainerView.bounds
		previewLayer.videoGravity = .resizeAspectFill
		previewContainerView.layer.insertSublayer(previewLayer, at: 0)
		
		// Xcode warning, should be run on a background thread in order to avoid hanging UI thread
		DispatchQueue.global(qos: .background).async { [weak self] in
			self?.captureSession.startRunning()
		}
		
		view.setNeedsLayout()
	}
	
	func failed() {
		let permissionsDenied = AVCaptureDevice.authorizationStatus(for: .video) == .denied
		var alertController: UIAlertController? = nil
		
		if permissionsDenied {
			os_log(.error, log: .default, "User revoked camera permissions")
			alertController = UIAlertController(title: "error", message: "NSCameraUsageDescription", preferredStyle: .alert)
			
			let systemSettingsAction = UIAlertAction(title: "wlt_navigation_settings", style: .default) { (action) in
				guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
					return
				}
				
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: nil)
				}
			}
			
			alertController?.addAction(UIAlertAction(title: "cancel", style: .default))
			alertController?.addAction(systemSettingsAction)
			
		} else {
			os_log(.error, log: .default, "Unable to scan on this device")
			alertController = UIAlertController(title: "error", message: "error_cant_scan", preferredStyle: .alert)
			alertController?.addAction(UIAlertAction(title: "ok", style: .default))
		}
		
		if let ac = alertController {
			self.present(ac, animated: true, completion: nil)
		}
		captureSession = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		textfield.text = nil
		
		if (captureSession?.isRunning == false) {
			// Xcode warning, should be run on a background thread in order to avoid hanging UI thread
			DispatchQueue.global(qos: .background).async { [weak self] in
				self?.captureSession.startRunning()
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if (captureSession?.isRunning == true) {
			captureSession.stopRunning()
		}
	}
	
	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		captureSession.stopRunning()
		
		if let metadataObject = metadataObjects.first {
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
			guard let stringValue = readableObject.stringValue else { return }
			AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			found(code: stringValue)
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























/*

import AVFoundation
import UIKit
import os.log

protocol ScanViewControllerDelegate: AnyObject {
	func scannedQRCode(code: String)
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
	var captureSession: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	let titleLabel = UILabel()
	let blurEffectView = UIVisualEffectView()
	let transparentView = UIView()
	let modalBackButton = UIButton()
	
	public var withTextField: Bool = false
	let textfield = UITextField()
	let pasteButton = UIButton()
	
	weak var delegate: ScanViewControllerDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if self.isModal {
			modalBackButton.setImage(UIImage(systemName: "xmark"), for: .normal)
			modalBackButton.tintColor = UIColor.white
			modalBackButton.translatesAutoresizingMaskIntoConstraints = false
			modalBackButton.addTarget(self, action: #selector(back), for: .touchUpInside)
			
			blurEffectView.contentView.addSubview(modalBackButton)
			
			NSLayoutConstraint.activate([
				modalBackButton.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor, constant: -24),
				modalBackButton.topAnchor.constraint(equalTo: blurEffectView.topAnchor, constant: 24),
				modalBackButton.heightAnchor.constraint(equalToConstant: 44),
				modalBackButton.widthAnchor.constraint(equalToConstant: 44)
			])
		}
		
		AVCaptureDevice.requestAccess(for: .video) { [weak self] (response) in
			DispatchQueue.main.async {
				if response {
					self?.setupVideoPreview()
				} else {
					self?.failed()
				}
			}
		}
	}
	
	@objc func back() {
		self.dismiss(animated: true, completion: nil)
	}
	
	func setupVideoPreview() {
		view.backgroundColor = UIColor.black
		captureSession = AVCaptureSession()

		guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
		let videoInput: AVCaptureDeviceInput
		
		do {
			videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
		} catch {
			return
		}

		if (captureSession.canAddInput(videoInput)) {
			captureSession.addInput(videoInput)
		} else {
			failed()
			return
		}

		let metadataOutput = AVCaptureMetadataOutput()

		if (captureSession.canAddOutput(metadataOutput)) {
			captureSession.addOutput(metadataOutput)

			metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
			metadataOutput.metadataObjectTypes = [.qr]
		} else {
			failed()
			return
		}

		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		previewLayer.frame = view.layer.bounds
		previewLayer.videoGravity = .resizeAspectFill
		view.layer.addSublayer(previewLayer)
		
		// Xcode warning, should be run on a background thread in order to avoid hanging UI thread
		DispatchQueue.global(qos: .background).async { [weak self] in
			self?.captureSession.startRunning()
		}
		
		view.setNeedsLayout()
	}
	
	func setupOutlineView() {
		transparentView.backgroundColor = .clear
		transparentView.translatesAutoresizingMaskIntoConstraints = false
		transparentView.customCornerRadius = 10
		self.view.addSubview(transparentView)
		
		NSLayoutConstraint.activate([
			transparentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 24),
			transparentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -24),
			transparentView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: !withTextField ? 0.4 : 0.3),
			transparentView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: !withTextField ? 0 : ((self.view.frame.height * 0.3) * 0.75) * -1 )
		])
	}
	
	@objc func textFieldDone() {
		found(code: textfield.text ?? "")
	}
	
	func setupBlurView() {
		titleLabel.text = "Scan QR Code"
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.textColor = .white
		titleLabel.numberOfLines = 0
		titleLabel.textAlignment = .center
		
		blurEffectView.translatesAutoresizingMaskIntoConstraints = false
		blurEffectView.frame = view.frame
		blurEffectView.effect = UIBlurEffect(style: UIBlurEffect.Style.dark)
		blurEffectView.alpha = 0.8
		self.view.addSubview(blurEffectView)
		
		let path = UIBezierPath(roundedRect: blurEffectView.frame, cornerRadius: 0)
		let clearBoxPath = CGPath(roundedRect: transparentView.frame.insetBy(dx: 5, dy: 5), cornerWidth: 10, cornerHeight: 10, transform: nil)
		path.append(UIBezierPath(cgPath: clearBoxPath))
		path.usesEvenOddFillRule = true
		
		let maskLayer = CAShapeLayer()
		maskLayer.path = path.cgPath
		maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
		
		blurEffectView.layer.mask = maskLayer
		blurEffectView.contentView.addSubview(titleLabel)
		
		NSLayoutConstraint.activate([
			blurEffectView.topAnchor.constraint(equalTo: self.view.topAnchor),
			blurEffectView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			blurEffectView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			blurEffectView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			
			titleLabel.bottomAnchor.constraint(equalTo: transparentView.topAnchor, constant: -36),
			titleLabel.widthAnchor.constraint(equalToConstant: 214),
			titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
		])
		
		if withTextField {
			textfield.backgroundColor = .white
			textfield.translatesAutoresizingMaskIntoConstraints = false
			textfield.customCornerRadius = 10
			textfield.placeholder = "or enter data ..."
			textfield.addDoneToolbar(onDone: (target: self, action: #selector(textFieldDone)))
			textfield.autocorrectionType = .no
			textfield.textContentType = .none
			textfield.autocapitalizationType = .none
			textfield.spellCheckingType = .no
			self.blurEffectView.contentView.addSubview(textfield)
			
			pasteButton.setTitle("Paste", for: .normal)
			pasteButton.translatesAutoresizingMaskIntoConstraints = false
			pasteButton.backgroundColor = .white
			pasteButton.setTitleColor(.black, for: .normal)
			pasteButton.customCornerRadius = 10
			pasteButton.addTarget(self, action: #selector(pasteButtonTapped), for: .touchUpInside)
			pasteButton.setContentHuggingPriority(.required, for: .horizontal)
			self.blurEffectView.contentView.addSubview(pasteButton)
			
			NSLayoutConstraint.activate([
				textfield.leadingAnchor.constraint(equalTo: self.transparentView.leadingAnchor, constant: 0),
				textfield.trailingAnchor.constraint(equalTo: self.pasteButton.leadingAnchor, constant: -16),
				textfield.topAnchor.constraint(equalTo: self.transparentView.bottomAnchor, constant: 16),
				textfield.heightAnchor.constraint(equalToConstant: 40),
				
				pasteButton.trailingAnchor.constraint(equalTo: self.transparentView.trailingAnchor, constant: 0),
				pasteButton.topAnchor.constraint(equalTo: self.transparentView.bottomAnchor, constant: 16),
				pasteButton.heightAnchor.constraint(equalToConstant: 40),
			])
		}
	}
	
	@objc func pasteButtonTapped() {
		self.textfield.text = UIPasteboard.general.string
		self.textFieldDone()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		setupOutlineView()
		setupBlurView()
	}

	func failed() {
		let permissionsDenied = AVCaptureDevice.authorizationStatus(for: .video) == .denied
		var alertController: UIAlertController? = nil
		
		if permissionsDenied {
			os_log(.error, log: .default, "User revoked camera permissions")
			alertController = UIAlertController(title: "error", message: "NSCameraUsageDescription", preferredStyle: .alert)
			
			let systemSettingsAction = UIAlertAction(title: "wlt_navigation_settings", style: .default) { (action) in
				guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
					return
				}
				
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: nil)
				}
			}
			
			alertController?.addAction(UIAlertAction(title: "cancel", style: .default))
			alertController?.addAction(systemSettingsAction)
			
		} else {
			os_log(.error, log: .default, "Unable to scan on this device")
			alertController = UIAlertController(title: "error", message: "error_cant_scan", preferredStyle: .alert)
			alertController?.addAction(UIAlertAction(title: "ok", style: .default))
		}
		
		if let ac = alertController {
			self.present(ac, animated: true, completion: nil)
		}
		captureSession = nil
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if (captureSession?.isRunning == false) {
			// Xcode warning, should be run on a background thread in order to avoid hanging UI thread
			DispatchQueue.global(qos: .background).async { [weak self] in
				self?.captureSession.startRunning()
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		if (captureSession?.isRunning == true) {
			captureSession.stopRunning()
		}
	}

	func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		captureSession.stopRunning()

		if let metadataObject = metadataObjects.first {
			guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
			guard let stringValue = readableObject.stringValue else { return }
			AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			found(code: stringValue)
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
*/
