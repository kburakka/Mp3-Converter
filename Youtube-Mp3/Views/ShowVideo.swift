//
//  ShowVideo.swift
//  Youtube-Mp3
//
//  Created by burak kaya on 22/11/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import WebKit

class ShowVideo: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var download: UIButton!
    @IBOutlet weak var close: UIButton!
    override init(frame: CGRect){
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit(){
        Bundle.main.loadNibNamed("ShowVideo", owner:self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}
