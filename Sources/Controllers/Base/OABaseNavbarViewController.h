//
//  OABaseNavbarViewController.h
//  OsmAnd
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASuperViewController.h"

typedef NS_ENUM(NSInteger, EOABaseNavbarColorScheme)
{
    EOABaseNavbarColorSchemeOrange = 0,
    EOABaseNavbarColorSchemeGray,
    EOABaseNavbarColorSchemeWhite
};

typedef NS_ENUM(NSInteger, EOABaseNavbarStyle)
{
    EOABaseNavbarStyleSimple = 0,
    EOABaseNavbarStyleDescription,
    EOABaseNavbarStyleLargeTitle,
    EOABaseNavbarStyleCustomLargeTitle
};

@interface OABaseNavbarViewController : OASuperViewController<UIGestureRecognizerDelegate, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)commonInit;
- (void)postInit;

- (void)updateNavbar;
- (void)updateUI;
- (void)updateUIAnimated;

- (UIBarButtonItem *)createRightNavbarButton:(NSString *)title
                                    iconName:(NSString *)iconName
                                      action:(SEL)action
                                        menu:(UIMenu *)menu;

- (NSString *)getTitle;
- (NSString *)getSubtitle;
- (NSString *)getLeftNavbarButtonTitle;
- (UIImage *)getCustomIconForLeftNavbarButton;
- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons;
- (EOABaseNavbarColorScheme)getNavbarColorScheme;
- (BOOL)isNavbarBlurring;
- (BOOL)isNavbarSeparatorVisible;
- (UIImage *)getRightIconLargeTitle;
- (UIColor *)getRightIconTintColorLargeTitle;
- (EOABaseNavbarStyle)getNavbarStyle;
- (NSString *)getCustomTableViewDescription;
- (void)setupCustomLargeTitleView;
- (NSString *)getTableFooterText;

- (void)generateData;
- (BOOL)hideFirstHeader;
- (NSString *)getTitleForHeader:(NSInteger)section;
- (NSString *)getTitleForFooter:(NSInteger)section;
- (NSInteger)rowsCount:(NSInteger)section;
- (UITableViewCell *)getRow:(NSIndexPath *)indexPath;
- (NSInteger)sectionsCount;
- (CGFloat)getCustomHeightForHeader:(NSInteger)section;
- (CGFloat)getCustomHeightForFooter:(NSInteger)section;
- (UIView *)getCustomViewForHeader:(NSInteger)section;
- (UIView *)getCustomViewForFooter:(NSInteger)section;
- (void)onRowSelected:(NSIndexPath *)indexPath;
- (void)onRowDeselected:(NSIndexPath *)indexPath;

- (void)onRightNavbarButtonPressed;
- (void)onScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)onRotation;

@end
