//
//  RWTournamentBattleView.swift
//  RobowarsClient
//
//  Created by Oleksiy Zhuk on 19.11.2021.
//

import UIKit

fileprivate struct Colors {
    static let ship: UIColor = .blue
    static let miss: UIColor = .red
    static let hit: UIColor = .black
    static let textMiss: UIColor = .black
    static let textHit: UIColor = .white
}

protocol RWTournamentBattleViewDelegate: AnyObject {
    func onFooterButtonPressed()
    func onResetButtonPressed()
}

class RWTournamentBattleView: UIView, NibLoadable {
    @IBOutlet private weak var leftTopContainer: UIView!
    @IBOutlet private weak var leftMidContainer: UIView!
    @IBOutlet private weak var rightTopContainer: UIView!
    @IBOutlet private weak var rightMidContainer: UIView!
    @IBOutlet private weak var bottomContainer: UIView!
    @IBOutlet private weak var resetButton: UIButton!
    
    private var leftFieldView: FieldView?
    private var rightFieldView: FieldView?
    
    private var gameSpeed: Int = 2
    
    weak var delegate: RWTournamentBattleViewDelegate?
    
    private let leftHeaderView: RWTournamentHeaderView = .fromNib()
    private let rightHeaderView: RWTournamentHeaderView = .fromNib()
    private let footerView: RWTournamentFooterView = .fromNib()
    
    var sliderValue: Float { footerView.sliderValue }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        leftHeaderView.frame = leftTopContainer.bounds
        leftHeaderView.translatesAutoresizingMaskIntoConstraints = false
        leftTopContainer.addSubview(leftHeaderView)
        leftHeaderView.fillSuperview()
        
        rightHeaderView.frame = rightTopContainer.bounds
        rightHeaderView.translatesAutoresizingMaskIntoConstraints = false
        rightTopContainer.addSubview(rightHeaderView)
        rightHeaderView.fillSuperview()
        
        footerView.frame = bottomContainer.bounds
        footerView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(footerView)
        footerView.fillSuperview()
        footerView.delegate = self
    }
    
    func setupEmptyFields(withSize squareSize: Int) {
        // left
        leftFieldView?.removeFromSuperview()
        let leftFieldView = FieldView(squareSize: squareSize, frame: .zero)
        leftMidContainer.addSubview(leftFieldView)
        leftFieldView.fillSuperview()
        self.leftFieldView = leftFieldView
        // right
        rightFieldView?.removeFromSuperview()
        let rightFieldView = FieldView(squareSize: squareSize, frame: .zero)
        rightMidContainer.addSubview(rightFieldView)
        rightFieldView.fillSuperview()
        self.rightFieldView = rightFieldView
    }
    
    func updateParticipantMessage(_ message: String, for side: FieldSide){
        switch side {
        case .right: rightHeaderView.updateMessage(message)
        case .left: leftHeaderView.updateMessage(message)
        }
    }
    
    func updateParticipantName(_ name: String, for side: FieldSide){
        switch side {
        case .right: rightHeaderView.updateName(name)
        case .left: leftHeaderView.updateName(name)
        }
    }
    
    func placeShoot(at point: CGPoint, onField field: FieldSide, isHit: Bool) {
        let fieldView = field == .left ? leftFieldView : rightFieldView
        fieldView?.update(point: point,
                          with: isHit ? Colors.hit : Colors.miss,
                          textColor: isHit ? Colors.textHit : Colors.textMiss)
    }
    
    func placeShips(withRects rects: [CGRect], onField field: FieldSide) {
        let fieldView = field == .left ? leftFieldView : rightFieldView
        fieldView?.place(rects: rects, color: Colors.ship, shouldReset: true)
    }
    
    func show(completion: (() -> Void)?) {
        completion?()
    }
    
    func updateFooter(buttonText: String, showSlider: Bool) {
        footerView.updateButtonText(buttonText)
        footerView.showSlider(showSlider)
        resetButton.isHidden = !showSlider
    }
    
    func updateFooterMessages(left: String?, right: String?) {
        footerView.updateMessages(left: left, right: right)
    }
    
    func updateGameSpeedInfo() {
        let newSpeed = Int(footerView.sliderValue)
        guard gameSpeed != newSpeed else { return }
        gameSpeed = newSpeed
        let interval = 1.0 / TimeInterval(1<<gameSpeed)
        footerView.updateMessages(left: "Game Speed: \(gameSpeed)", right: "Time Interval: \(interval)")
    }
    
    @IBAction func onResetButton(_ sender: UIButton) {
        delegate?.onResetButtonPressed()
    }
}

extension RWTournamentBattleView: RWTournamentFooterViewDelegate {
    func onFooterButtonPressed() {
        delegate?.onFooterButtonPressed()
    }
    
    func onSliderChange() {
        updateGameSpeedInfo()
    }
}
