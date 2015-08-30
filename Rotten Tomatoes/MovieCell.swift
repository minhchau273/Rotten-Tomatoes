//
//  MovieCell.swift
//  Rotten Tomatoes
//
//  Created by Dave Vo on 8/27/15.
//  Copyright (c) 2015 Chau Vo. All rights reserved.
//

import UIKit

class MovieCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var posterView: UIImageView!
    
    @IBOutlet weak var mpaaRatingLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var emojiView: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        mpaaRatingLabel.layer.borderWidth = 0.5
        mpaaRatingLabel.layer.borderColor = UIColor(red: 0/255, green: 79/255, blue: 0/255, alpha: 1.0).CGColor
        mpaaRatingLabel.layer.cornerRadius = 3
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
