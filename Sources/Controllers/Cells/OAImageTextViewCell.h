//
//  OAImageDescBTableViewCell.h
//  OsmAnd
//
//  Created by igor on 24.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAImageTextViewCell : UITableViewCell


@property (strong, nonatomic) IBOutlet UITextView *descView;
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconViewHeight;

@end

