//
//  VideoViewCell.swift
//  Youtube-Mp3
//
//  Created by burak kaya on 25/11/2019.
//  Copyright © 2019 burak kaya. All rights reserved.
//

import UIKit
import MarqueeLabel

class VideoViewCell: UITableViewCell {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var title: MarqueeLabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configure(with : VideoCell?){
        if let video = with{
            title.text = video.title
            thumbnail.image = video.image?.image
        }
    }
}
