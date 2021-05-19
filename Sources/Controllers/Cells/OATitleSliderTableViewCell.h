//
//  OATitleSliderTableViewCell.h
//  OsmAnd Maps
//
//  Created by igor on 17.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleSliderTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;


@end

