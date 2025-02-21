//
//  CalmingScenesViewController.swift
//  Thesis
//
//  Created by Maxwell Barvian on 2/11/15.
//  Copyright (c) 2015 Maxwell Barvian. All rights reserved.
//

import UIKit
import CoreMotion
import SDCloudUserDefaults
import Async

public let scenesPath = NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("Scenes")
public let scenes: [String]? = {
	var error: NSError? = nil
	let files = NSFileManager.defaultManager().contentsOfDirectoryAtPath(scenesPath, error: &error) as? [String]
	
	return files
}()

class CalmingScenesViewController: SlidingViewController, FullScreenViewController, RelaxationViewController, CalmingSceneViewControllerDelegate {
	
	weak var relaxationDelegate: RelaxationViewControllerDelegate?
	
	let tintColor = UIColor.whiteColor()
	let backgroundColor = UIColor.blackColor()
	let tabColor = UIColor.clearColor()
	let selectedTabColor = UIColor.clearColor()
	
	let navigationBarHidden = true
	let navigationBarTranslucent = true
	
	private(set) var showingInstructions = true
	
	private(set) lazy var vignetteView: UIImageView = {
		let vignette = UIImageView(image: UIImage(named: "Vignette"))
		vignette.contentMode = .ScaleToFill
		vignette.setTranslatesAutoresizingMaskIntoConstraints(false)
		
		return vignette
	}()
	
	private(set) lazy var titleLabel: UILabel = {
		let label = UILabel.applicationHeaderLabel()
		label.text = "Calming Scene Meditation"
		label.setTranslatesAutoresizingMaskIntoConstraints(false)
		label.textColor = UIColor.whiteColor()
		
		return label
	}()
	
	private(set) lazy var instructionsLabel: UILabel = {
		let label = UILabel.applicationSubheaderLabel()
		label.text = "Gently place your attention in the scene, allowing other thoughts to come and go with little effort."
		label.setTranslatesAutoresizingMaskIntoConstraints(false)
		label.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
		
		return label
	}()
	
	private(set) lazy var progressButton: UIButton = {
		let button = UIButton.applicationTextButton()
		button.tintColor = UIColor.whiteColor()
		
		button.addTarget(self, action: "didTapProgressButton:", forControlEvents: .TouchUpInside)
		
		return button
	}()
	
	override func prefersStatusBarHidden() -> Bool {
		return !showingInstructions
	}
	
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}
	
	convenience init() {
		self.init(spacing: 46.0)
		
		title = "Calming Scenes"
		let motionManager = CMMotionManager()
		viewControllers = scenes?.map {
			let sceneController = CalmingSceneViewController(scene: $0, motionManager: motionManager)
			sceneController.delegate = self
			
			return sceneController
		}
		selectedIndex = SDCloudUserDefaults.previousCalmingScene
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.addSubview(vignetteView)
		view.addSubview(titleLabel)
		view.addSubview(instructionsLabel)
		view.addSubview(progressButton)
		
		setupFullScreenControllerView(self, statusBarCover: false)
		
		view.setNeedsUpdateConstraints() // bootstrap AutoLayout
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		shouldUpdateProgressButton()
		
		updateFullScreenControllerColors(self, animated: false)
		hideFullScreenControllerNavigationBar(self, animated: false)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		self.toggleInstructions(true, timer: 3.5)
	}
	
	// MARK: API
	
	private var _hideBlock: Async?
	
	func toggleInstructions(_ state: Bool? = nil, timer: Double? = nil) {
		showingInstructions = state != nil ? state! : !showingInstructions
		let alpha: CGFloat = showingInstructions ? 1.0 : 0.0
		
		UIView.animateWithDuration(0.33) {
			self.vignetteView.alpha = alpha
			self.titleLabel.alpha = alpha
			self.instructionsLabel.alpha = alpha
			self.progressButton.alpha = alpha
			self.setNeedsStatusBarAppearanceUpdate()
		}
		
		_hideBlock?.cancel()
		if showingInstructions && timer != nil {
			_hideBlock = Async.main(after: timer!) {
				self.toggleInstructions(false)
			}
		}
	}
	
	// MARK: Constraints
	
	private var _didSetupConstraints = false
	
	override func updateViewConstraints() {
		if !_didSetupConstraints {
			setupFullScreenControllerViewConstraints(self)
			
			let views: [NSObject: AnyObject] = [
				"vignetteView": vignetteView,
				"titleLabel": titleLabel,
				"instructionsLabel": instructionsLabel,
				"progressButton": progressButton,
				"bottomLayoutGuide": bottomLayoutGuide
			]
			
			let vMargin: CGFloat = 34, hMargin: CGFloat = 26
			let metrics = [
				"vMargin": vMargin,
				"hMargin": hMargin
			]
			
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[vignetteView]|", options: nil, metrics: metrics, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[vignetteView]|", options: nil, metrics: metrics, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(54)-[titleLabel]-[instructionsLabel]", options: nil, metrics: metrics, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[progressButton]-(vMargin)-[bottomLayoutGuide]", options: nil, metrics: metrics, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(hMargin)-[titleLabel]-(hMargin)-|", options: nil, metrics: metrics, views: views))
			view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(hMargin)-[instructionsLabel]-(hMargin)-|", options: nil, metrics: metrics, views: views))
			for (_, subview) in views {
				view.addConstraint(NSLayoutConstraint(item: subview, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
			}
			
			_didSetupConstraints = true
		}
		
		super.updateViewConstraints()
	}
	
	// MARK: Handlers
	
	func didTapProgressButton(button: UIButton!) {
		SDCloudUserDefaults.previousCalmingScene = selectedIndex
		relaxationDelegate?.relaxationViewControllerDidTapProgressButton?(self)
	}
 
	// MARK: CalmingSceneViewControllerDelegate
	
	func calmingSceneViewController(calmingSceneViewController: CalmingSceneViewController, didEndTouches touches: Set<NSObject>, withEvent event: UIEvent) {
		toggleInstructions(timer: 5)
	}
	
	// MARK: RelaxationViewControllerDelegate
	
	func shouldUpdateProgressButton() {
		relaxationViewController(self, shouldUpdateProgressButton: progressButton)
	}
	
	// MARK: Deinitializers
	
	deinit {
		_hideBlock?.cancel()
	}
	
}