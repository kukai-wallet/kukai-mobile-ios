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
	var previewLayer: AVCaptureVideoPreviewLayer!
	
	let titleLabel = UILabel()
	let blurEffectView = UIVisualEffectView()
	let transparentView = UIView()
	let modalBackButton = UIButton()
	
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
				modalBackButton.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor, constant: 24),
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

		captureSession.startRunning()
		
		view.setNeedsLayout()
	}
	
	func setupOutlineView() {
		transparentView.backgroundColor = .clear
		transparentView.translatesAutoresizingMaskIntoConstraints = false
		transparentView.layer.cornerRadius = 10
		self.view.addSubview(transparentView)
		
		NSLayoutConstraint.activate([
			transparentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 24),
			transparentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -24),
			transparentView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.4),
			transparentView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
		])
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
			captureSession.startRunning()
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
		delegate?.scannedQRCode(code: code)
		
		
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
