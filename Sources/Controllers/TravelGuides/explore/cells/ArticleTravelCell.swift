//
//  ArticleTravelCell.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 18.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class ArticleTravelCell: UITableViewCell {
    

    @IBOutlet weak var arcticleTitle: UILabel!
    @IBOutlet weak var arcticleDescription: UILabel!
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var imagePreview: UIImageView!
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var leftButtonLabel: UILabel!
    @IBOutlet weak var leftButtonIcon: UIImageView!
    
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var rightButtonLabel: UILabel!
    @IBOutlet weak var rightButtonIcon: UIImageView!
    
    
    @IBAction func leftButtonTapped(_ sender: Any) {
        print("leftButtonTapped")
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
        print("rightButtonTapped")
    }
}
