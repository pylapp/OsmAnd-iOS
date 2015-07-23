//
//  OAPluginDetailsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@interface OAPluginDetailsViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UIImageView *screenshot;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIView *detailsView;
@property (weak, nonatomic) IBOutlet UIButton *priceButton;
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UITextView *descTextView;

@property (nonatomic, readonly) NSString *productId;

- (instancetype)initWithProductId:(NSString *)productId;

@end
