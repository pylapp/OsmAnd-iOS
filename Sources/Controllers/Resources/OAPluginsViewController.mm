//
//  OAPluginsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPluginsViewController.h"
#import "OAIAPHelper.h"
#import "OAInAppCell.h"
#import <StoreKit/StoreKit.h>
#import "OALog.h"
#import "OAResourcesBaseViewController.h"
#import "OAPurchasesViewController.h"
#import "OsmAndApp.h"
#include "Localization.h"
#import "OAUtilities.h"
#import "OAPluginDetailsViewController.h"
#import "OAPluginPopupViewController.h"
#import <Reachability.h>
#import <MBProgressHUD.h>
#import "OASizes.h"
#import "OAOsmLiveBannerView.h"
#import "OAChoosePlanHelper.h"

@interface OAPluginsViewController ()<UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, OAOsmLiveBannerViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *titlePanelView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAPluginsViewController
{
    OAIAPHelper *_iapHelper;
    NSNumberFormatter *_numberFormatter;
    MBProgressHUD* _loadProductsProgressHUD;
    OAOsmLiveBannerView *_osmLiveBanner;
    
    CALayer *_horizontalLine;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"plugins");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    
    [_btnToolbarMaps setTitle:OALocalizedString(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedString(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPlugins];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _iapHelper = [OAIAPHelper sharedInstance];
    
    _loadProductsProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    //_loadProductsProgressHUD.dimBackground = YES;
    _loadProductsProgressHUD.minShowTime = .5f;
    
    [self.view addSubview:_loadProductsProgressHUD];
    
    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.toolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.toolbarView.layer addSublayer:_horizontalLine];
    
    if (!_iapHelper.subscribedToLiveUpdates)
    {
        NSArray<OASubscription *> *subscriptions = [_iapHelper.liveUpdates getVisibleSubscriptions];
        OASubscription *cheapest = nil;
        for (OASubscription *subscription in subscriptions)
        {
            if (!cheapest || subscription.monthlyPrice.doubleValue < cheapest.monthlyPrice.doubleValue)
                cheapest = subscription;
        }
        if (cheapest && cheapest.formattedPrice)
        {
            NSString *minPriceStr = [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_month_cost_descr"), cheapest.formattedMonthlyPrice];
            _osmLiveBanner = [OAOsmLiveBannerView bannerWithType:EOAOsmLiveBannerUnlockAll minPriceStr:minPriceStr];
            _osmLiveBanner.delegate = self;
            [_osmLiveBanner updateFrame:self.tableView.frame.size.width margin:[OAUtilities getLeftMargin]];
        }
        self.tableView.tableHeaderView = _osmLiveBanner;
    }
        
    if (self.openFromSplash)
    {
        self.backButton.hidden = YES;
        self.doneButton.hidden = NO;
    }
    
    if (self.openFromCustomPlace)
    {
        [_toolbarView removeFromSuperview];
        _tableView.frame = CGRectMake(_tableView.frame.origin.x, _tableView.frame.origin.y, _tableView.frame.size.width, _tableView.frame.size.height + _toolbarView.frame.size.height);
    }
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    [_osmLiveBanner updateFrame:self.tableView.frame.size.width margin:[OAUtilities getLeftMargin]];
}

- (UIView *) getTopView
{
    return _titlePanelView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (UIView *) getBottomView
{
    return _toolbarView;
}

- (CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}


- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRestored:) name:OAIAPProductsRestoredNotification object:nil];
    
    if (![_iapHelper productsLoaded])
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [self loadProducts];
        else
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    [self applySafeAreaMargins];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) reachabilityChanged:(NSNotification *)notification
{
    if (![_iapHelper productsLoaded] &&
        [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        [self loadProducts];
    }
}

- (void) loadProducts
{
    [_loadProductsProgressHUD show:YES];
    
    [_iapHelper requestProductsWithCompletionHandler:^(BOOL success) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
            {
                [self.tableView reloadData];
                CATransition *animation = [CATransition animation];
                [animation setType:kCATransitionPush];
                [animation setSubtype:kCATransitionFromBottom];
                [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
                [animation setFillMode:kCAFillModeBoth];
                [animation setDuration:.3];
                [[self.tableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
            }
            
            [_loadProductsProgressHUD hide:YES];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _iapHelper.inAppAddons.count;
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const inAppCellIdentifier = @"OAInAppCell";
    
    OAInAppCell* cell;
    cell = (OAInAppCell *)[tableView dequeueReusableCellWithIdentifier:inAppCellIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAInAppCell" owner:self options:nil];
        cell = (OAInAppCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [UIView performWithoutAnimation:^{
            [cell.btnPrice removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            cell.btnPrice.tag = indexPath.row;
            [cell.btnPrice addTarget:self action:@selector(buttonPurchaseClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            OAProduct *product = _iapHelper.inAppAddons[indexPath.row];

            BOOL purchased = [product isPurchased];
            BOOL disabled = product.disabled;
            
            UIImage *imgTitle = [UIImage imageNamed:[product productIconName]];
            if (!imgTitle)
                imgTitle = [UIImage imageNamed:@"img_app_purchase_2.png"];
            
            cell.imgIconBackground.hidden = NO;
            
            NSString *title = product.localizedTitle;
            NSString *desc = product.localizedDescription;
            NSString *price;
            if (product.price)
            {
                [_numberFormatter setLocale:product.priceLocale];
                price = [_numberFormatter stringFromNumber:product.price];
            }
            else
            {
                price = [OALocalizedString(@"shared_string_buy") uppercaseStringWithLocale:[NSLocale currentLocale]];
            }
            
            [cell.imgIcon setImage:imgTitle];
            [cell.lbTitle setText:title];
            [cell.lbDescription setText:desc];
            [cell.btnPrice setTitle:price forState:UIControlStateNormal];
            
            [cell setPurchased:purchased disabled:disabled];
            [cell.btnPrice layoutIfNeeded];
        }];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OAProduct *product = _iapHelper.inAppAddons[indexPath.row];
    if (product)
    {
        OAPluginDetailsViewController *pluginDetails = [[OAPluginDetailsViewController alloc] initWithProduct:product];
        pluginDetails.openFromSplash = self.openFromSplash;
        pluginDetails.openFromCustomPlace = self.openFromCustomPlace;
        [self.navigationController pushViewController:pluginDetails animated:YES];
    }
}

- (IBAction) buttonPurchaseClicked:(id)sender
{
    UIButton *btn = sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:btn.tag inSection:0];
    
    OAProduct *product = _iapHelper.inAppAddons[indexPath.row];
    
    BOOL purchased = [product isPurchased];
    BOOL disabled = product.disabled;
    
    if (purchased)
    {
        if (disabled)
        {
            [_iapHelper enableProduct:product.productIdentifier];
            [OAPluginPopupViewController showProductAlert:product afterPurchase:NO];
        }
        else
        {
            [_iapHelper disableProduct:product.productIdentifier];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
        return;
    }
    
    [_loadProductsProgressHUD show:YES];
    
    [[OAIAPHelper sharedInstance] buyProduct:product];
}

- (void) productPurchased:(NSNotification *)notification {
    
    NSString * identifier = notification.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];
        
        [self.tableView reloadData];
        
        OAProduct *product = [_iapHelper product:identifier];
        if (product)
            [OAPluginPopupViewController showProductAlert:product afterPurchase:YES];
    });
}

- (void) productPurchaseFailed:(NSNotification *)notification
{
    NSString * identifier = notification.object;
    OAProduct *product = [_iapHelper product:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];
        
        if (product)
        {
            NSString *text = [NSString stringWithFormat:OALocalizedString(@"prch_failed"), product.localizedTitle];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (void) productsRestored:(NSNotification *)notification
{
    NSNumber *errorsCountObj = notification.object;
    int errorsCount = errorsCountObj.intValue;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_loadProductsProgressHUD hide:YES];
        
        if (errorsCount > 0)
        {
            NSString *text = [NSString stringWithFormat:@"%d %@", errorsCount, OALocalizedString(@"prch_items_failed")];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
    
}

- (void) backButtonClicked:(id)sender
{
    if (self.openFromCustomPlace)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction) btnToolbarMapsClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction) btnToolbarPurchasesClicked:(id)sender
{
    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = _openFromSplash;

    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [controllers removeObject:self];
    [controllers addObject:purchasesViewController];
    [self.navigationController setViewControllers:controllers];
}

#pragma mark OAOsmLiveBannerViewDelegate

- (void) osmLiveBannerPressed
{
    [OAChoosePlanHelper showChoosePlanScreenWithProduct:nil navController:self.navigationController];
}

@end
