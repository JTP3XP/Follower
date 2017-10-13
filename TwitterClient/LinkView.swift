//
//  LinkView.swift
//  TwitterClient
//
//  Created by John Patton on 9/24/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit

class LinkView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var linkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    // based on https://medium.com/@brianclouser/swift-3-creating-a-custom-view-from-a-xib-ecdfe5b3a960
    
    override init(frame: CGRect) { // for using view in code
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) { // for using view in IB
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("LinkView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    
}
