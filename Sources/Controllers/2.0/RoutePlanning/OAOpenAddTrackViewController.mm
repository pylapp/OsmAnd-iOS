//
//  OAOpenAddTrackViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAOpenAddTrackViewController.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDatabase.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OsmAndApp.h"
#import "OAGPXTrackCell.h"
#import "OASegmentTableViewCell.h"
#import "OARoutePlanningHudViewController.h"
#import "OASaveTrackBottomSheetViewController.h"
#import "OAUtilities.h"
#import "OAFoldersCell.h"

#define kGPXTrackCell @"OAGPXTrackCell"
#define kCellTypeSegment @"OASegmentTableViewCell"
#define kFoldersCell @"OAFoldersCell"
#define kAllFoldersKey @"kAllFoldersKey"
#define kFolderKey @"kFolderKey"
#define kAllFoldersIndex 0
#define kVerticalMargin 16.
#define kHorizontalMargin 16.
#define kGPXCellTextLeftOffset 62.

typedef NS_ENUM(NSInteger, EOASortingMode) {
    EOAModifiedDate = 0,
    EOANameAscending,
    EOANameDescending
};

@interface OAOpenAddTrackViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, OAFoldersCellDelegate>

@end

@implementation OAOpenAddTrackViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    EOASortingMode _sortingMode;
    EOAPlanningTrackScreenType _screenType;
    int _selectedFolderIndex;
    NSArray<NSString *> *_allFolders;
}

- (instancetype) initWithScreenType:(EOAPlanningTrackScreenType)screenType
{
    self = [super initWithNibName:@"OABaseTableViewController"
                           bundle:nil];
    if (self)
    {
        _screenType = screenType;
        [self commonInit];
        [self generateData];
    }
    return self;
}

- (void) commonInit
{
    _selectedFolderIndex = kAllFoldersIndex;
    [self updateAllFoldersList];
}

- (void) updateAllFoldersList
{
    NSMutableArray<NSString *> *allFoldersNames = [NSMutableArray new];
    [allFoldersNames addObject:OALocalizedString(@"tracks")];
    NSArray* filesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:OsmAndApp.instance.gpxPath error:nil];
    for (NSString *name in filesList)
    {
        if (![name hasPrefix:@"."] && ![name.lowerCase hasSuffix:@".gpx"])
            [allFoldersNames addObject:name];
    }
    NSArray<NSString *> *sortedAllFolderNames = [allFoldersNames sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    _allFolders = sortedAllFolderNames;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _sortingMode = EOAModifiedDate;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.tableView.contentInset = UIEdgeInsetsMake(-16, 0, 0, 0);
    if (_screenType == EOAAddToATrack)
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"route_between_points_add_track_desc") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = _screenType == EOAOpenExistingTrack ? OALocalizedString(@"plan_route_open_existing_track") : OALocalizedString(@"add_to_track");
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (_screenType == EOAAddToATrack)
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"route_between_points_add_track_desc") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
            [self.tableView reloadData];
        } completion:nil];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSMutableArray *existingTracksSection = [NSMutableArray new];
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    NSArray *filteredData = [self filterData:db.gpxList];
    NSArray *gpxList = [NSMutableArray arrayWithArray:[self sortData:filteredData]];
    
    [existingTracksSection addObject:@{
        @"type" : kFoldersCell,
        @"selectedValue" : [NSNumber numberWithInt:_selectedFolderIndex],
        @"values" : [self getFoldersList]
    }];
    
    [existingTracksSection addObject:@{
        @"type" : kCellTypeSegment,
        @"title0" : OALocalizedString(@"osm_modified"),
        @"title1" : OALocalizedString(@"shared_a_z"),
        @"title2" : OALocalizedString(@"shared_z_a"),
        @"key" : @"segment_control"
    }];
    
    OsmAndAppInstance app = OsmAndApp.instance;
    
    /*if ([self isShowCurrentGpx])
    {
        [existingTracksSection addObject:@{
                @"type" : kGPXTrackCell,
                @"title" : OALocalizedString(@"track_recording_name"),
                @"distance" : [app getFormattedDistance:0],
                @"time" : [app getFormattedTimeInterval:0 shortFormat:YES],
                @"wpt" : [NSString stringWithFormat:@"%d", 0],
                @"key" : @"gpx_route"
            }];
    }*/
    
    for (OAGPX *gpx in gpxList)
    {
        [existingTracksSection addObject:@{
                @"type" : kGPXTrackCell,
                @"track" : gpx,
                @"title" : [gpx getNiceTitle],
                @"distance" : [app getFormattedDistance:gpx.totalDistance],
                @"time" : [app getFormattedTimeInterval:gpx.timeSpan shortFormat:YES],
                @"wpt" : [NSString stringWithFormat:@"%d", gpx.wptPoints],
                @"key" : @"gpx_route"
            }];
    }
    [data addObject:existingTracksSection];
    _data = data;
}

- (NSArray<NSDictionary *> *) getFoldersList
{
    NSArray *folderNames = _allFolders;
    
    NSMutableArray *folderButtonsData = [NSMutableArray new];
    [folderButtonsData addObject:@{
        @"title" : OALocalizedString(@"shared_string_all"),
        @"img" : @"",
        @"type" : kAllFoldersKey}];
    
    for (int i = 0; i < folderNames.count; i++)
    {
        [folderButtonsData addObject:@{
            @"title" : folderNames[i],
            @"img" : @"ic_custom_folder",
            @"type" : kFolderKey}];
    }
    return folderButtonsData;
}

- (NSArray *) filterData:(NSArray *)data
{
    if (_selectedFolderIndex == kAllFoldersIndex)
    {
        return data;
    }
    else
    {
        NSString *selectedFolderName = _allFolders[_selectedFolderIndex - 1];
        if ([selectedFolderName isEqualToString:OALocalizedString(@"tracks")])
            selectedFolderName = @"";
        
        return[data filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OAGPX *object, NSDictionary *bindings) {
            NSString *folderName = object.gpxFilePath.stringByDeletingLastPathComponent;
            return [folderName isEqualToString:selectedFolderName];
        }]];
    }
}

- (NSArray *) sortData:(NSArray *)data
{
    NSArray *sortedData = [data sortedArrayUsingComparator:^NSComparisonResult(OAGPX *obj1, OAGPX *obj2) {
        switch (_sortingMode) {
            case EOAModifiedDate:
            {
                NSDate *time1 = [OAUtilities getFileLastModificationDate:obj1.gpxFilePath];
                NSDate *time2 = [OAUtilities getFileLastModificationDate:obj2.gpxFilePath];
                return [time2 compare:time1];
            }
            case EOANameAscending:
                return [obj1.gpxTitle compare:obj2.gpxTitle options:NSCaseInsensitiveSearch];
            case EOANameDescending:
                return  [obj2.gpxTitle compare:obj1.gpxTitle options:NSCaseInsensitiveSearch];
            default:
                break;
        }
    }];
    return sortedData;
}

- (BOOL) isShowCurrentGpx
{
    return _screenType == EOAAddToATrack;
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kCellTypeSegment])
    {
        static NSString* const identifierCell = @"OASegmentTableViewCell";
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASegmentTableViewCell" owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
            [cell.segmentControl insertSegmentWithTitle:item[@"title2"] atIndex:2 animated:NO];
        }
        if (cell)
        {
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
        }
        return cell;
    }
    else if ([type isEqualToString:kGPXTrackCell])
    {
        static NSString* const identifierCell = kGPXTrackCell;
        OAGPXTrackCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kGPXTrackCell owner:self options:nil];
            cell = (OAGPXTrackCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0, self.tableView.safeAreaInsets.left + kGPXCellTextLeftOffset, 0, 0);
            cell.separatorView.hidden = YES;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.distanceLabel.text = item[@"distance"];
            cell.timeLabel.text = item[@"time"];
            cell.wptLabel.text = item[@"wpt"];
            cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
            cell.distanceImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.timeImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.wptImageView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    else if ([type isEqualToString:kFoldersCell])
    {
        static NSString* const identifierCell = kFoldersCell;
        OAFoldersCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAFoldersCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.collectionView.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.delegate = self;
            [cell setValues:item[@"values"] withSelectedIndex:(int)[item[@"selectedValue"] intValue]];
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    OAGPX* track = item[@"track"];
    if (_screenType == EOAOpenExistingTrack && track)
    {
        if (self.delegate)
            [self.delegate closeBottomSheet];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] initWithFileName:track.gpxFilePath]];
        return;
    }
    else
    {
        OAGPX* track = item[@"track"];
        NSString *filename = nil;
        if (track)
            filename = track.gpxFilePath;
        if (self.delegate)
            [self.delegate onFileSelected:track.gpxFilePath];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    return;
}

- (void) segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl*)sender;
    if (segment)
    {
        if (segment.selectedSegmentIndex == 0)
            _sortingMode = EOAModifiedDate;
        else if (segment.selectedSegmentIndex == 1)
            _sortingMode = EOANameAscending;
        else if (segment.selectedSegmentIndex == 2)
            _sortingMode = EOANameDescending;
        [self generateData];
        
        NSMutableArray *pathsToReload = [NSMutableArray arrayWithArray:self.tableView.indexPathsForVisibleRows];
        [pathsToReload removeObjectAtIndex:0];
        [self.tableView reloadRowsAtIndexPaths:pathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - OAFoldersCellDelegate

- (void) onItemSelected:(int)index type:(NSString *)type
{
    _selectedFolderIndex = index;
    [self generateData];
    [self.tableView reloadData];
}

@end
