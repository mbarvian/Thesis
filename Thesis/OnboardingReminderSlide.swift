//
//  OnboardingReminderController.swift
//  Thesis
//
//  Created by Maxwell Barvian on 2/22/15.
//  Copyright (c) 2015 Maxwell Barvian. All rights reserved.
//

import UIKit

@objc protocol OnboardingReminderSlideDelegate {
	optional func onboardingReminderSlide(onboardingReminderSlide: OnboardingReminderSlide, didChangeTimePicker timePicker: UIDatePicker!)
}

class OnboardingReminderSlide: OnboardingSlide {
	
	weak var delegate: OnboardingReminderSlideDelegate?
	
	private(set) lazy var timePicker: UIDatePicker = {
		let picker = UIDatePicker()
		picker.setTranslatesAutoresizingMaskIntoConstraints(false)
		picker.datePickerMode = .Time
		picker.date = NSDate.applicationDefaultRelaxationReminderTime()
		picker.addTarget(self, action: "didChangeTimePicker:", forControlEvents: .ValueChanged)
		
		return picker
	}()
	
	override init(header: String, subheader: String) {
		super.init(header: header, subheader: subheader)
		
		addSubview(timePicker)
	}
	
	convenience init() {
		self.init(header: "Daily Relaxation Reminders", subheader: "You may find it helpful to set aside time to practice deep relaxation every day. Early mornings are great, but the best time is one that you can stick to most days.")
	}

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: Constraints
	
	private var _didSetupConstraints = false
	
	override func updateConstraints() {if !_didSetupConstraints {
			let views: [NSObject: AnyObject] = [
				"timePicker": timePicker
			]
			
			let margin: CGFloat = 26
			let metrics = [
				"margin": margin
			]
			
			subheaderBottomConstraint = NSLayoutConstraint(item: subheaderLabel, attribute: .Bottom, relatedBy: .Equal, toItem: timePicker, attribute: .Top, multiplier: 1, constant: -margin)
			addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[timePicker]|", options: nil, metrics: metrics, views: views))
			addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[timePicker]|", options: nil, metrics: metrics, views: views))
			
			_didSetupConstraints = true
		}
		
		super.updateConstraints()
	}
	
	// MARK: Handlers
	
	func didChangeTimePicker(picker: UIDatePicker!) {
		delegate?.onboardingReminderSlide?(self, didChangeTimePicker: timePicker)
	}
	
}
