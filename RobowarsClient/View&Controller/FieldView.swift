//
//  FieldView.swift
//  RobowarsClient
//
//  Created by Max Bystryk on 06.10.2021.
//

import UIKit

fileprivate struct ViewConfig {
    static let backgroundColor: UIColor = .black
    static let emptyCellColor: UIColor = .yellow
    static let cellSpacing: CGFloat = 2
}

class FieldView: UIView {
    private var fieldStackView = UIStackView()
    private var fieldRect: CGRect
    
    init(squareSize: Int, frame: CGRect) {
        fieldRect = CGRect(origin: CGPoint(x: 0, y: 0),
                           size: CGSize(width: squareSize, height: squareSize))
        super.init(frame: frame)
        setup(squareSize: squareSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func place(rects: [CGRect], color: UIColor, shouldReset: Bool = false) {
        if shouldReset { reset() }
        
        for rect in rects {
            place(rect: rect, color: color)
        }
    }
    
    func place(rect: CGRect, color: UIColor) {
        guard fieldRect.contains(rect) else { return }
        
        let initialColumn = Int(rect.origin.x)
        let initialRow = Int(rect.origin.y)
        let edgeColumn = Int(rect.maxX)
        let edgeRow = Int(rect.maxY)
        
        for row in initialRow..<edgeRow {
            for column in initialColumn..<edgeColumn {
                let cell = getCell(forRow: row, column: column)
                cell.backgroundColor = color
            }
        }
    }
    
    func remove(rect: CGRect) {
        
    }
    
    func update(point: CGPoint, with color: UIColor, textColor: UIColor, resetCounter: Bool = false) {
        let cell = getCell(forRow: Int(point.y), column: Int(point.x))
        if let label = cell as? UILabel {
            let tag = resetCounter ? 0 : label.tag + 1
            label.textColor = textColor
            label.text = tag > 1 ? tag.description : nil
            label.tag = tag
        }
        cell.backgroundColor = color
    }
    
    private func setup(squareSize: Int) {
        fieldStackView.spacing = ViewConfig.cellSpacing
        fieldStackView.backgroundColor = ViewConfig.backgroundColor
        fieldStackView.distribution = .fillEqually
        fieldStackView.axis = .vertical
        
        for _ in 0..<squareSize {
            let rowStackView = makeRowStackView()
            for _ in 0..<squareSize {
                let cellView = makeCellView()
                rowStackView.addArrangedSubview(cellView)
            }
            
            fieldStackView.addArrangedSubview(rowStackView)
        }
        
        addSubview(fieldStackView)
        fieldStackView.fillSuperview()
    }
    
    private func reset() {
        fieldStackView.arrangedSubviews.forEach { view in
            (view as! UIStackView).arrangedSubviews.forEach { view in
                view.backgroundColor = ViewConfig.emptyCellColor
                if let label = view as? UILabel {
                    label.text = nil
                    label.tag = 0
                }
            }
        }
    }

    private func makeRowStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = ViewConfig.cellSpacing
        stackView.distribution = .fillEqually
        return stackView
    }
    
    private func makeCellView() -> UIView {
        let view = UILabel(frame: .zero)
        view.textColor = .black
        view.font = .boldSystemFont(ofSize: 16)
        view.minimumScaleFactor = 0.3
        view.textAlignment = .center
        view.backgroundColor = ViewConfig.emptyCellColor
        return view
    }
    
    private func getCell(forRow row: Int, column: Int) -> UIView {
        let row = fieldStackView.arrangedSubviews[row] as! UIStackView
        let view = row.arrangedSubviews[column]
        
        return view
    }
}
