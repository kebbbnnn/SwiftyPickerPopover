//
//  StringPickerPopoverViewController.swift
//  SwiftyPickerPopover
//
//  Created by Yuta Hoshino on 2016/09/14.
//  Copyright © 2016 Yuta Hoshino. All rights reserved.
//

public class StringPickerPopoverViewController: AbstractPickerPopoverViewController {

    // MARK: Types
    
    /// Popover type
    public typealias PopoverType = StringPickerPopover
    
    // MARK: Properties

    /// Popover
    private var popover: PopoverType! { return anyPopover as? PopoverType }
    
    @IBOutlet weak private var cancelButton: UIBarButtonItem!
    @IBOutlet weak private var doneButton: UIBarButtonItem!
    //@IBOutlet weak private var picker: UIPickerView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak private var clearButton: UIButton!

    override public func viewDidLoad() {
        super.viewDidLoad()
        //picker.delegate = self
        table.delegate = self
        table.dataSource = self
        table.isScrollEnabled = false
        
        if popover.choices.count < 2 {
            table.separatorStyle = .none
        }
        
        table.register(StringPickerTableViewCell.self, forCellReuseIdentifier: "StringPickerTableViewCell")
    }

    /// Make the popover properties reflect on this view controller
    override func refrectPopoverProperties(){
        super.refrectPopoverProperties()
        // Select row if needed
        //picker?.selectRow(popover.selectedRow, inComponent: 0, animated: true)
        table.selectRow(at: IndexPath(row: popover!.selectedRow, section: 1), animated: true, scrollPosition: .none)

        // Set up cancel button
        if #available(iOS 11.0, *) { }
        else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        }

        cancelButton.title = popover.cancelButton.title
        if let font = popover.cancelButton.font {
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        }
        cancelButton.tintColor = popover.cancelButton.color ?? popover.tintColor
        navigationItem.setLeftBarButton(cancelButton, animated: false)
        
        doneButton.title = popover.doneButton.title
        if let font = popover.doneButton.font {
            doneButton.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        }
        doneButton.tintColor = popover.doneButton.color ?? popover.tintColor
        navigationItem.setRightBarButton(doneButton, animated: false)

        clearButton.setTitle(popover.clearButton.title, for: .normal)
        if let font = popover.clearButton.font {
            clearButton.titleLabel?.font = font
        }
        clearButton.tintColor = popover.clearButton.color ?? popover.tintColor
        clearButton.isHidden = popover.clearButton.action == nil
        enableClearButtonIfNeeded()
    }
    
    private func enableClearButtonIfNeeded() {
        guard !clearButton.isHidden else {
            return
        }
        clearButton.isEnabled = false
        if let selectedRow = table.indexPathForSelectedRow?.row, let selectedValue = popover.choices[safe: selectedRow] {
            clearButton.isEnabled = selectedValue != popover.kValueForCleared
        }
//        if let selectedRow = picker?.selectedRow(inComponent: 0),
//            let selectedValue = popover.choices[safe: selectedRow] {
//            clearButton.isEnabled = selectedValue != popover.kValueForCleared
//        }
    }
    
    /// Action when tapping done button
    ///
    /// - Parameter sender: Done button
    @IBAction func tappedDone(_ sender: AnyObject? = nil) {
        tapped(button: popover.doneButton)
    }
    
    /// Action when tapping cancel button
    ///
    /// - Parameter sender: Cancel button
    @IBAction func tappedCancel(_ sender: AnyObject? = nil) {
        tapped(button: popover.cancelButton)
    }
    
    private func tapped(button: StringPickerPopover.ButtonParameterType?) {
//        let selectedRow = picker.selectedRow(inComponent: 0)
//        if let selectedValue = popover.choices[safe: selectedRow] {
//            button?.action?(popover, selectedRow, selectedValue)
//        }
        if let selectedRow = table.indexPathForSelectedRow?.row, let selectedValue = popover.choices[safe: selectedRow] {
            button?.action?(popover, selectedRow, selectedValue)
        }
        popover.removeDimmedView()
        dismiss(animated: false)
    }

    /// Action when tapping clear button
    ///
    /// - Parameter sender: Clear button
    @IBAction func tappedClear(_ sender: AnyObject? = nil) {
        let kTargetRow = 0
//        picker.selectRow(kTargetRow, inComponent: 0, animated: true)
        table.selectRow(at: IndexPath(row: kTargetRow, section: 1), animated: true, scrollPosition: .none)
        enableClearButtonIfNeeded()
        if let selectedValue = popover.choices[safe: kTargetRow] {
            popover.clearButton.action?(popover, kTargetRow, selectedValue)
        }
        popover.redoDisappearAutomatically()
    }
    
    /// Action to be executed after the popover disappears
    ///
    /// - Parameter popoverPresentationController: UIPopoverPresentationController
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        tappedCancel()
    }
}

extension StringPickerPopoverViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return popover.choices.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StringPickerTableViewCell", for: indexPath) as! StringPickerTableViewCell
        cell.setPopover(popover, at: indexPath.row)
        return cell
    }
}

extension StringPickerPopoverViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return popover.rowHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        enableClearButtonIfNeeded()
        popover.valueChangeAction?(popover, row, popover.choices[row])
        popover.redoDisappearAutomatically()
    }
}

class StringPickerTableViewCell: UITableViewCell {
    
    private var popover: StringPickerPopoverViewController.PopoverType?
    
    func setPopover(_ popover: StringPickerPopoverViewController.PopoverType, at row: Int) {
        self.popover = popover
        
        let value: String = popover.choices[row]
        let adjustedValue: String = popover.displayStringFor?(value) ?? value
        let label = UILabel()
        
        let parentFrame = self.contentView.frame
        let margin: CGFloat = parentFrame.size.width * (popover.marginPercentage / 100.0)
        let labelX = parentFrame.origin.x + margin
        let labelY = parentFrame.origin.y
        
        let labelWidth = parentFrame.size.width - (margin * 2)
        let labelHeight = parentFrame.size.height
        
        let frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        
        label.frame = frame
        label.text = adjustedValue
        label.attributedText = getAttributedText(image: popover.images?[row], text: adjustedValue)
        label.textAlignment = margin > 0 ? .left : .center
        
        self.addSubview(label)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        //contentView.backgroundColor = .orange
    }
    
//    init(value: String, adjustedValue: String, image: UIImage?, popover: StringPickerPopoverViewController.PopoverType) {
//        super.init(style: .default, reuseIdentifier: "StringPickerTableViewCell")
//
//        self.popover = popover
//
//        let label = UILabel()
//        label.text = adjustedValue
//        label.attributedText = getAttributedText(image: image, text: adjustedValue)
//        label.textAlignment = .center
//
//        addSubview(label)
//    }
    
    private func getAttributedText(image: UIImage?, text: String?) -> NSAttributedString? {
        let result: NSMutableAttributedString = NSMutableAttributedString()
        if let attributedImage = getAttributedImage(image), let space = getAttributedText(" ") {
            result.append(attributedImage)
            result.append(space)
        }
        if let attributedText = getAttributedText(text) {
            result.append(attributedText)
        }
        return result
    }
    
    private func getAttributedText(_ text: String?) -> NSAttributedString? {
        guard let text = text else {
            return nil
        }
        let font: UIFont = {
            if let f = popover?.font {
                if let size = popover?.fontSize {
                    return UIFont(name: f.fontName, size: size)!
                }
                return UIFont(name: f.fontName, size: f.pointSize)!
            }
            let size = popover?.fontSize ?? popover!.kDefaultFontSize
            return UIFont.systemFont(ofSize: size)
        }()
        let color: UIColor = popover!.fontColor
        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }
    
    private func getAttributedImage(_ image: UIImage?) -> NSAttributedString? {
        guard let image = image else {
            return nil
        }
        let imageAttachment = TextAttachment()
        imageAttachment.image = image
        return NSAttributedString(attachment: imageAttachment)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIPickerViewDataSource
//extension StringPickerPopoverViewController: UIPickerViewDataSource {
//    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return 1
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return popover.choices.count
//    }
//}

// MARK: - UIPickerViewDelegate
//extension StringPickerPopoverViewController: UIPickerViewDelegate {
//    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        let value: String = popover.choices[row]
//        return popover.displayStringFor?(value) ?? value
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        let value: String = popover.choices[row]
//        let adjustedValue: String = popover.displayStringFor?(value) ?? value
//        let label: UILabel = view as? UILabel ?? UILabel()
//        label.text = adjustedValue
//        label.attributedText = getAttributedText(image: popover.images?[row], text: adjustedValue)
//        label.textAlignment = .center
//        return label
//    }
//
//    private func getAttributedText(image: UIImage?, text: String?) -> NSAttributedString? {
//        let result: NSMutableAttributedString = NSMutableAttributedString()
//        if let attributedImage = getAttributedImage(image), let space = getAttributedText(" ") {
//            result.append(attributedImage)
//            result.append(space)
//        }
//        if let attributedText = getAttributedText(text) {
//            result.append(attributedText)
//        }
//        return result
//    }
//
//    private func getAttributedText(_ text: String?) -> NSAttributedString? {
//        guard let text = text else {
//            return nil
//        }
//        let font: UIFont = {
//            if let f = popover.font {
//                if let size = popover.fontSize {
//                    return UIFont(name: f.fontName, size: size)!
//                }
//                return UIFont(name: f.fontName, size: f.pointSize)!
//            }
//            let size = popover.fontSize ?? popover.kDefaultFontSize
//            return UIFont.systemFont(ofSize: size)
//        }()
//        let color: UIColor = popover.fontColor
//        return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
//    }
//
//    private func getAttributedImage(_ image: UIImage?) -> NSAttributedString? {
//        guard let image = image else {
//            return nil
//        }
//        let imageAttachment = TextAttachment()
//        imageAttachment.image = image
//        return NSAttributedString(attachment: imageAttachment)
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//        let attributedResult = NSMutableAttributedString()
//
//        if let image = popover.images?[row] {
//            let imageAttachment = TextAttachment()
//            imageAttachment.image = image
//            let attributedImage = NSAttributedString(attachment: imageAttachment)
//            attributedResult.append(attributedImage)
//
//            let AttributedMargin = NSAttributedString(string: " ")
//            attributedResult.append(AttributedMargin)
//        }
//
//        let value: String = popover.choices[row]
//        let title: String = popover.displayStringFor?(value) ?? value
//        let font: UIFont = {
//            if let f = popover.font {
//                if let fontSize = popover.fontSize {
//                    return UIFont(name: f.fontName, size: fontSize)!
//                }
//                return UIFont(name: f.fontName, size: f.pointSize)!
//            }
//            let fontSize = popover.fontSize ?? popover.kDefaultFontSize
//            return UIFont.systemFont(ofSize: fontSize)
//        }()
//        let attributedTitle: NSAttributedString = NSAttributedString(string: title, attributes: [.font: font, .foregroundColor: popover.fontColor])
//
//        attributedResult.append(attributedTitle)
//        return attributedResult
//    }
//
//    public func pickerView(_ pickerView: UIPickerView,
//                           rowHeightForComponent component: Int) -> CGFloat {
//        return popover.rowHeight
//    }
//
//    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        enableClearButtonIfNeeded()
//        popover.valueChangeAction?(popover, row, popover.choices[row])
//        popover.redoDisappearAutomatically()
//    }
//}

class TextAttachment: NSTextAttachment {
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let y = ceil(abs((lineFrag.size.height - self.image!.size.height) / 2.0))
        var bounds = CGRect()
        bounds.origin = .init(x: 0.0, y: y * -1)
        bounds.size = self.image!.size
        return bounds
    }
}
