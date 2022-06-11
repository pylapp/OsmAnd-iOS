//
//  OAPlanTypeCardRow.mm
//  OsmAnd
//
//  Created by Skalii on 20.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlanTypeCardRow.h"
#import "OAProducts.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OAChoosePlanHelper.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAPlanTypeCardRow ()

@property (weak, nonatomic) IBOutlet UIImageView *imageViewLeftIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewRightIcon;
@property (weak, nonatomic) IBOutlet UIView *badgeViewContainer;
@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tertiaryDescrLabel;

@end

@implementation OAPlanTypeCardRow
{
    OAPlanTypeCardRowType _type;
    OAProduct *_subscription;

    UITapGestureRecognizer *_tapRecognizer;
    UILongPressGestureRecognizer *_longPressRecognizer;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPlanTypeCardRow class]])
        {
            self = (OAPlanTypeCardRow *)v;
            break;
        }

    if (self)
        self.frame = CGRectMake(0, 0, 200, 100);

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPlanTypeCardRow class]])
        {
            self = (OAPlanTypeCardRow *)v;
            break;
        }

    if (self)
        self.frame = frame;

    return self;
}

- (instancetype)initWithType:(OAPlanTypeCardRowType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
        [self commonInit];
        [self updateType];
    }
    return self;
}

- (void)commonInit
{
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapped:)];
    [self addGestureRecognizer:_tapRecognizer];
    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
    _longPressRecognizer.minimumPressDuration = .2;
    [self addGestureRecognizer:_longPressRecognizer];
    self.layer.cornerRadius = 9.;
}

- (void)updateType
{
    switch (_type)
    {
        case EOAPlanTypeChoosePlan:
        {
            self.backgroundColor = UIColorFromARGB(color_primary_purple_10);
            self.imageViewLeftIcon.hidden = NO;
            self.imageViewRightIcon.hidden = YES;
            self.labelTitle.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
            self.labelDescription.font = [UIFont systemFontOfSize:15.];
            self.labelTitle.textColor = UIColorFromRGB(color_primary_purple);
            self.labelDescription.textColor = UIColorFromRGB(color_primary_purple);
            self.labelTitle.textAlignment = NSTextAlignmentLeft;
            self.labelDescription.textAlignment = NSTextAlignmentLeft;
            break;
        }
        case EOAPlanTypeChooseSubscription:
        {
            self.backgroundColor = UIColor.whiteColor;
            self.imageViewLeftIcon.hidden = YES;
            self.imageViewRightIcon.hidden = NO;
            self.labelTitle.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            self.labelDescription.font = [UIFont systemFontOfSize:15.];
            self.labelTitle.textColor = UIColorFromRGB(color_primary_purple);
            self.labelDescription.textColor = UIColor.blackColor;
            self.labelTitle.textAlignment = NSTextAlignmentLeft;
            self.labelDescription.textAlignment = NSTextAlignmentLeft;
            break;
        }
        case EOAPlanTypePurchase:
        {
            self.backgroundColor = UIColorFromRGB(color_primary_purple);
            self.imageViewLeftIcon.hidden = YES;
            self.imageViewRightIcon.hidden = YES;
            self.labelTitle.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            self.labelDescription.font = [UIFont systemFontOfSize:15.];
            self.labelTitle.textColor = UIColor.whiteColor;
            self.labelDescription.textColor = UIColor.whiteColor;
            self.labelTitle.textAlignment = NSTextAlignmentCenter;
            self.labelDescription.textAlignment = NSTextAlignmentCenter;
            break;
        }
    }
}

- (void)updateSelected:(BOOL)selected
{
    if (_type == EOAPlanTypeChooseSubscription)
    {
        self.layer.borderWidth = selected ? 2. : 0.;
        self.layer.borderColor = selected ? UIColorFromRGB(color_primary_purple).CGColor : UIColor.whiteColor.CGColor;
        self.imageViewRightIcon.image = selected ? [UIImage imageNamed:@"ic_system_checkbox_selected"] : nil;
        self.backgroundColor = selected ? UIColorFromARGB(color_primary_purple_10) : UIColor.whiteColor;
    }
}

- (OAProductDiscount *)getDiscountOffer
{
    OAProductDiscount *discountOffer = nil;
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (settings.eligibleForIntroductoryPrice)
    {
        discountOffer = _subscription.introductoryPrice;
    }
    else if (settings.eligibleForSubscriptionOffer)
    {
        if (_subscription.discounts && _subscription.discounts.count > 0)
            discountOffer = _subscription.discounts[0];
    }
    return discountOffer;
}

- (void)updateInfo:(OAProduct *)subscription selectedFeature:(OAFeature *)selectedFeature selected:(BOOL)selected
{
    _subscription = subscription;
    switch (_type)
    {
        case EOAPlanTypeChoosePlan:
        {
            BOOL isMaps = [OAIAPHelper isFullVersion:subscription] || ([subscription isKindOfClass:OASubscription.class] && [OAIAPHelper isMapsSubscription:(OASubscription *) subscription]);
            BOOL mapsPlusPurchased = [OAIAPHelper isSubscribedToMaps] || [OAIAPHelper isFullVersionPurchased];
            BOOL osmAndProPurchased = [OAIAPHelper isOsmAndProAvailable];
            BOOL isPurchased = (isMaps && mapsPlusPurchased) || osmAndProPurchased;
            BOOL available = ((isMaps && [selectedFeature isAvailableInMapsPlus]) || !isMaps) && !isPurchased;
            NSString *patternPlanAvailable = OALocalizedString(available ? @"continue_with" : @"not_available_with");
            self.labelTitle.text = isPurchased
                    ? OALocalizedString(@"shared_string_purchased")
                    : [NSString stringWithFormat:patternPlanAvailable, _subscription.localizedTitle];

            self.labelDescription.text = isPurchased
                    ? @""
                    : [NSString stringWithFormat:@"%@ %@",
                            [OAUtilities capitalizeFirstLetter:OALocalizedString(@"shared_string_from")],
                            _subscription.formattedPrice];

            NSString *iconName = [_subscription productIconName];
            UIImage *icon;
            if (!available)
                icon = [UIImage imageNamed:[iconName stringByAppendingString:@"_bw"]];
            if (!icon)
                icon = [UIImage imageNamed:iconName];
            self.imageViewLeftIcon.image = icon;
            self.imageViewRightIcon.image = nil;
            self.backgroundColor = available && !isPurchased ? UIColorFromARGB(color_primary_purple_10) : UIColorFromRGB(color_route_button_inactive);
            self.labelTitle.textColor = available && !isPurchased ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer);
            self.labelDescription.textColor = available && !isPurchased ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_icon_inactive);
            self.userInteractionEnabled = available && !isPurchased;
            self.layer.borderWidth = 0.;
            break;
        }
        case EOAPlanTypeChooseSubscription:
        {
            OAProductDiscount * discountOffer = [self getDiscountOffer];
            
            BOOL hasSpecialOffer = discountOffer != nil;
            
            NSAttributedString *purchaseDescr = [_subscription getDescription:15.0];
            NSMutableAttributedString *descr = [[NSMutableAttributedString alloc] initWithString:@""];
            if (hasSpecialOffer)
            {
                [descr appendAttributedString:[[NSAttributedString alloc]
                                                                 initWithString:discountOffer.getDescriptionTitle
                                                                 attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]}]];
            }
            else if (purchaseDescr)
            {
                [descr appendAttributedString:purchaseDescr];
            }
            
            if (descr.length > 0)
            {
                _badgeViewContainer.hidden = NO;
                _badgeViewContainer.backgroundColor = hasSpecialOffer ? UIColorFromRGB(color_disount_offer) : UIColorFromRGB(color_discount_save);
                _badgeLabel.attributedText = descr;
            }
            
            self.labelTitle.text = [_subscription getTitle:17.].string;
            if (hasSpecialOffer)
            {
                if (descr.length > 0)
                {
                    NSArray<NSString *> *priceComps = [discountOffer.getFormattedDescription.string componentsSeparatedByString:@"\n"];
                    if (priceComps.count == 2)
                    {
                        self.labelDescription.text = priceComps.firstObject;
                        self.tertiaryDescrLabel.text = priceComps.lastObject;
                    }
                    else
                    {
                        self.labelDescription.text = discountOffer.getFormattedDescription.string;
                    }
                    self.tertiaryDescrLabel.hidden = self.tertiaryDescrLabel.text.length == 0;
                }
                else
                {
                    self.labelDescription.text = discountOffer.getFormattedDescription.string;
                }
            }
            else
            {
                self.labelDescription.text = _subscription.formattedPrice;
            }
            
            self.imageViewLeftIcon.image = nil;
            self.labelTitle.textColor = UIColorFromRGB(color_primary_purple);
            self.labelDescription.textColor = UIColor.blackColor;
            [self updateSelected:selected];
            self.userInteractionEnabled = YES;
            break;
        }
        case EOAPlanTypePurchase:
        {
            self.labelTitle.text = OALocalizedString(@"complete_purchase");
            OAProductDiscount *discount = [self getDiscountOffer];
            NSString *price = discount ? discount.getFormattedDescription.string : _subscription.formattedPrice;
            self.labelDescription.text = price;

            self.layer.borderWidth = 0.;
            self.imageViewLeftIcon.image = nil;
            self.imageViewRightIcon.image = nil;
            self.backgroundColor = UIColorFromRGB(color_primary_purple);
            self.labelTitle.textColor = UIColor.whiteColor;
            self.labelDescription.textColor = UIColor.whiteColor;
            self.userInteractionEnabled = YES;
            break;
        }
    }
}

- (CGFloat)updateLayout:(CGFloat)y
{
    CGFloat width = DeviceScreenWidth - kSpaceMargin * 2 - [OAUtilities getLeftMargin] * 2;
    CGFloat textVerticalOffset = 12.;
    CGFloat leftSideOffset = _type == EOAPlanTypeChoosePlan ? 12. : kSpaceMargin;
    CGFloat rightSideOffset = _type == EOAPlanTypePurchase ? kSpaceMargin : 12.;
    CGFloat iconMargin = kIconSize + kSpaceMargin;
    CGFloat textWidth = width - leftSideOffset - rightSideOffset;
    if (_type != EOAPlanTypePurchase)
        textWidth -= iconMargin;

    CGSize titleSize = [OAUtilities calculateTextBounds:self.labelTitle.text
                                                  width:textWidth
                                                   font:self.labelTitle.font];
    self.labelTitle.frame = CGRectMake(
            leftSideOffset + (_type == EOAPlanTypeChoosePlan ? iconMargin : 0.),
            textVerticalOffset,
            textWidth,
            titleSize.height
    );
    
    BOOL hasBadge = !_badgeViewContainer.isHidden && _badgeLabel.attributedText.length > 0;
    CGSize discountSize = !hasBadge ? CGSizeZero : [OAUtilities calculateTextBounds:_badgeLabel.text width:textWidth / 2 font:_badgeLabel.font];

    CGSize descriptionSize = [OAUtilities calculateTextBounds:self.labelDescription.text
                                                        width:textWidth - (hasBadge ? discountSize.width + 8. : 0.)
                                                         font:self.labelDescription.font];
    self.labelDescription.frame = CGRectMake(
            self.labelTitle.frame.origin.x + (hasBadge ? discountSize.width + 20. : 0.),
            CGRectGetMaxY(self.labelTitle.frame) + (_type == EOAPlanTypeChooseSubscription ? 8. : 0.),
            self.labelTitle.frame.size.width,
            descriptionSize.height
    );
    
    CGFloat badgeY = self.labelDescription.frame.origin.y + ((self.labelDescription.frame.size.height - (discountSize.height + 4.)) / 2);
    
    self.badgeViewContainer.frame = CGRectMake(self.labelTitle.frame.origin.x, badgeY, discountSize.width + 12., discountSize.height + 4.);
    
    BOOL hasTertiaryDescr = !_tertiaryDescrLabel.isHidden && _tertiaryDescrLabel.text.length > 0;
    
    CGSize tertiaryDescrSize = hasTertiaryDescr ? [OAUtilities calculateTextBounds:self.tertiaryDescrLabel.text
                                                        width:textWidth
                                                         font:self.tertiaryDescrLabel.font] : CGSizeZero;
    
    self.tertiaryDescrLabel.frame = CGRectMake(
                                               self.labelTitle.frame.origin.x,
                                               CGRectGetMaxY(hasBadge ? self.badgeViewContainer.frame : self.labelDescription.frame) + 1.,
                                               textWidth,
                                               tertiaryDescrSize.height
                                               );

    self.frame = CGRectMake(
            kSpaceMargin + [OAUtilities getLeftMargin],
            y,
            width,
            self.labelDescription.frame.origin.y + self.labelDescription.frame.size.height + (hasTertiaryDescr ? self.tertiaryDescrLabel.frame.size.height + 1. : 0) + textVerticalOffset
    );

    self.imageViewLeftIcon.frame = CGRectMake(
            leftSideOffset,
            self.frame.size.height - self.frame.size.height / 2 - kIconSize / 2,
            kIconSize,
            kIconSize
    );

    self.imageViewRightIcon.frame = CGRectMake(
            width - rightSideOffset - kIconSize,
            self.labelTitle.frame.origin.y + titleSize.height - titleSize.height / 2 - kIconSize / 2,
            kIconSize,
            kIconSize
    );

    return self.frame.size.height;
}

- (void)onTapped:(UIGestureRecognizer *)recognizer
{
    if (self.delegate)
        [self.delegate onPlanTypeSelected:self.tag type:_type state:recognizer.state subscription:_subscription];
}

- (void)onLongPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate)
        [self.delegate onPlanTypeSelected:self.tag type:_type state:recognizer.state subscription:_subscription];
}

@end