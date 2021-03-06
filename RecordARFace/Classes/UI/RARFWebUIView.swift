//
//  RARFWebUIView.swift
//  RecordARFace
//
//  Created by 永田大祐 on 2019/04/29.
//

import UIKit
import WebKit

final class RARFWebUIView: UIView {

    @IBOutlet weak var goBt: UIButton!
    @IBOutlet weak var forwardBt: UIButton!


    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    func loadNib() {
        let bundle = Bundle(for: RARFWebUIView.self)
        let view = bundle.loadNibNamed("RARFWebUIView", owner: self, options: nil)?.first as! UIView
        view.frame.size.width = UIScreen.main.bounds.width
        self.addSubview(view)
    }

    func originTextField(rect: CGRect, rARFObject: RARFWebObject) {

        if goBt.frame.contains(rect) {
            rARFObject.webFlg = false
            rARFObject.webBack()
        }

        if forwardBt.frame.contains(rect) {
            rARFObject.webFlg = false
            rARFObject.webForward()
        }
    }
}
