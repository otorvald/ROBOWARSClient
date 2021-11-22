//
//  RWTournamentFooterView.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 22.11.2021.
//

import UIKit

protocol RWTournamentFooterViewDelegate: AnyObject {
    func onFooterButtonPressed()
    func onSliderChange()
}

class RWTournamentFooterView: UIView, NibLoadable {
    @IBOutlet private weak var MidButton: UIButton!
    @IBOutlet private weak var leftLabel: UILabel!
    @IBOutlet private weak var rightLabel: UILabel!
    @IBOutlet private weak var slider: UISlider!
    
    weak var delegate: RWTournamentFooterViewDelegate?
    
    func updateMessages(left: String?, right: String?) {
        leftLabel.text = left
        rightLabel.text = right
    }
    
    func updateButtonText(_ text: String) {
        MidButton.setTitle(text, for: .normal)
    }
    
    func showSlider(_ show: Bool) {
        slider.isHidden = !show
    }
    
    var sliderValue: Float { slider.value }
    
    @IBAction func onButtonPressed(_ sender: Any) {
        delegate?.onFooterButtonPressed()
    }
    
    @IBAction func onSliderChange(_ sender: Any) {
        delegate?.onSliderChange()
    }
}
