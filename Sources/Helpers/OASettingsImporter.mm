//
//  OASettingsImporter.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsImporter.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OASettingsHelper.h"
#import "Localization.h"

#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/ResourcesManager.h>

#define kTmpProfileFolder @"tmpProfileData"

#define kVersion 1


#pragma mark - OASettingsImporter

@implementation OASettingsImporter
{
    OsmAndAppInstance _app;
    
    NSString *_tmpFilesDir;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _tmpFilesDir = NSTemporaryDirectory();
        _tmpFilesDir = [_tmpFilesDir stringByAppendingPathComponent:kTmpProfileFolder];
    }
    return self;
}

- (NSMutableArray<OASettingsItem *> *) collectItems:(NSString *)file
{
    return [self processItems:file items:nil];
}

- (void) importItems:(NSString *)file items:(NSMutableArray<OASettingsItem *> *)items
{
    [self processItems:file items:items];
}

- (NSMutableArray<OASettingsItem *> *) processItems:(NSString *)file items:(NSMutableArray<OASettingsItem *> *)items
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL collecting = items == nil;
    if (collecting)
        items = [self getItemsFromJson:file];
    else if ([items count] == 0)
    {
        NSLog(@"No items");
        return nil;
    }

    OsmAnd::ArchiveReader archive(QString::fromNSString(file));
    bool ok = false;
    const auto archiveItems = archive.getItems(&ok, false);
    if (!ok)
    {
        NSLog(@"Error reading zip file");
        return items;
    }

    for (const auto& archiveItem : constOf(archiveItems))
    {
        if (!archiveItem.isValid())
            continue;
        
        QString filename = [self checkEntryName:archiveItem.name];
        OASettingsItem *item = nil;
        for (OASettingsItem *settingsItem in items)
        {
            if ([settingsItem applyFileName:filename.toNSString()])
            {
                item = settingsItem;
                break;
            }
        }
        
        if (item && ((collecting && item.shouldReadOnCollecting) || (!collecting && !item.shouldReadOnCollecting)))
        {
            OASettingsItemReader *reader = item.getReader;
            NSError *err = nil;
            if (reader)
            {
                NSString *tmpFileName = [_tmpFilesDir stringByAppendingPathComponent:archiveItem.name.toNSString()];
                if (!archive.extractItemToFile(archiveItem.name, QString::fromNSString(tmpFileName)))
                {
                    [fileManager removeItemAtPath:_tmpFilesDir error:nil];
                    NSLog(@"Error processing items");
                    continue;
                }
                [reader readFromFile:tmpFileName error:&err];
            }
            
            if (err)
                [item.warnings addObject:[NSString stringWithFormat:OALocalizedString(@"err_profile_import"), item.name]];
        }
    }
    
    [fileManager removeItemAtPath:_tmpFilesDir error:nil];
    
    return items;
}

- (NSMutableArray<OASettingsItem *> *) getItemsFromJson:(NSString *)file
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSMutableArray<OASettingsItem *> *items = [NSMutableArray new];
    OsmAnd::ArchiveReader archive(QString::fromNSString(file));
    
    bool ok = false;
    const auto archiveItems = archive.getItems(&ok, false);
    if (!ok)
    {
        NSLog(@"Error reading zip file");
        return items;
    }

    for (const auto& archiveItem : constOf(archiveItems))
    {
        if (!archiveItem.isValid())
            continue;
        
        if (archiveItem.name.compare(QStringLiteral("items.json")) == 0)
        {
            NSString *tmpFileName = [_tmpFilesDir stringByAppendingPathComponent:@"items.json"];
            if (!archive.extractItemToFile(archiveItem.name, QString::fromNSString(tmpFileName)))
            {
                [fileManager removeItemAtPath:_tmpFilesDir error:nil];
                NSLog(@"Error reading items.json");
                return items;
            }
            NSString *itemsJson = [NSString stringWithContentsOfFile:tmpFileName encoding:NSUTF8StringEncoding error:nil];
            OASettingsItemsFactory *factory = [[OASettingsItemsFactory alloc] initWithJSON:itemsJson];
            [items addObjectsFromArray:factory.getItems];
            [fileManager removeItemAtPath:_tmpFilesDir error:nil];
            break;
        }
    }
    return items;
}

- (QString) checkEntryName:(QString)entryName
{
    QString fileExt = QStringLiteral(".osf").append("/");
    int index = entryName.indexOf(fileExt);
    if (index != -1)
        entryName = entryName.mid(index + fileExt.length());
    
    return entryName;
}

@end


#pragma mark - OASettingsItemsFactory

@interface OASettingsItemsFactory()

@property(nonatomic, retain) NSMutableArray<OASettingsItem *> * items;

@end

@implementation OASettingsItemsFactory
{
    OsmAndAppInstance _app;
}

- (instancetype) initWithJSON:(NSString*)jsonStr
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        [self collectItems:jsonStr];
    }
    return self;
}

- (void) collectItems:(NSString *)jsonStr
{
    NSError *jsonError;
    NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
    if (jsonError)
    {
        NSLog(@"Error reading json");
        return;
    }
    
    NSInteger version = json[@"version"] ? [json[@"version"] integerValue] : 1;
    if (version > kVersion)
    {
        NSLog(@"Error: unsupported version");
        return;
    }
    
    NSArray* itemsJson = json[@"items"];
    NSMutableDictionary *pluginItems = [NSMutableDictionary new];
    
    for (NSDictionary* item in itemsJson)
    {
        OASettingsItem *settingsItem = [[OASettingsItem alloc] init];
        settingsItem = [self createItem:json];
        [self.items addObject:settingsItem];
    }
    if ([self.items count] == 0)
        NSLog(@"No items");
}

- (NSArray<OASettingsItem *> *) getItems
{
    return self.items;
}

- (OASettingsItem *) getItemByFileName:(NSString*)fileName
{
    for (OASettingsItem * item in self.items)
    {
        if ([item.fileName isEqualToString:fileName])
            return item;
    }
    return nil;
}

- (OASettingsItem *) createItem:(NSDictionary *)json
{
    OASettingsItem * item = nil;
    NSError *parseError;
    EOASettingsItemType type = [OASettingsItem parseItemType:json error:&parseError];
    if (parseError)
        return nil;
    
    NSError *error;
    switch (type)
    {
        case EOASettingsItemTypeGlobal:
            item = [[OAGlobalSettingsItem alloc] init];
            break;
        case EOASettingsItemTypeProfile:
            item = [[OAProfileSettingsItem alloc] initWithJSON:json];
            break;
        case EOASettingsItemTypePlugin:
            item = [[OAPluginSettingsItem alloc] initWithJSON:json error:&error];
            break;
        case EOASettingsItemTypeData:
            item = [[OADataSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeFile:
            item = [[OAFileSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeQuickActions:
            item = [[OAQuickActionsSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypePoiUIFilters:
            item = [[OAPoiUiFilterSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeMapSources:
            item = [[OAMapSourcesSettingsItem alloc] initWithJson:json error:&error];
            break;
        case EOASettingsItemTypeAvoidRoads:
            item = [[OAAvoidRoadsSettingsItem alloc] initWithJson:json error:&error];
            break;
        default:
            item = nil;
            break;
    }
    if (error)
        return nil;

    return item;
}

@end

#pragma mark - OAImportAsyncTask

@interface OAImportAsyncTask()

@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *latestChanges;
@property (nonatomic, assign) NSInteger version;
@property (nonatomic, assign) EOAImportType importType;
@property (nonatomic) NSMutableArray<OASettingsItem *> *items;
@property (nonatomic) NSMutableArray<OASettingsItem *> *selectedItems;
@property (nonatomic) NSMutableArray<OASettingsItem *> *duplicates;
@property (weak, nonatomic) id<OASettingsCollectDelegate> settingsCollectDelegate;
@property (weak, nonatomic) id<OACheckDuplicatesDelegate> checkDuplicatesDelegate;
@property (weak, nonatomic) id<OASettingsImportDelegate> settingsImportDelegate;

@end

@implementation OAImportAsyncTask
{
    BOOL _importDone;
    OASettingsHelper *_settingsHelper;
    OASettingsImporter *_importer;
    OASettingsCollect *_collectListener;
    OACheckDuplicates *_duplicatesListener;
    OASettingsImport *_importListener;
}

- (instancetype) initWithFile:(NSString *)filePath latestChanges:(NSString *)latestChanges version:(NSInteger)version collectListener:(OASettingsCollect *)collectListener
{
    _settingsHelper = [OASettingsHelper sharedInstance];
    _filePath = filePath;
    _collectListener = collectListener;
    _latestChanges = latestChanges;
    _version = version;
    _importer = [[OASettingsImporter alloc] initWithApp];
    _importType = EOAImportTypeCollect;
    return self;
}

- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items latestChanges:(NSString *)latestChanges version:(NSInteger)version importListener:(OASettingsImport *)importListener
{
    _settingsHelper = [OASettingsHelper sharedInstance];
    _filePath = filePath;
    _importListener = importListener;
    _items = items;
    _latestChanges = latestChanges;
    _version = version;
    _importer = [[OASettingsImporter alloc] initWithApp];
    _importType = EOAImportTypeImport;
    return self;
}

- (instancetype) initWithFile:(NSString *)filePath items:(NSArray<OASettingsItem *> *)items selectedItems:(NSArray<OASettingsItem *> *)selectedItems duplicatesListener:(OACheckDuplicates *)duplicatesListener
 {
     _settingsHelper = [OASettingsHelper sharedInstance];
     _filePath = filePath;
     _items = items;
     _duplicatesListener = duplicatesListener;
     _selectedItems = selectedItems;
     _importer = [[OASettingsImporter alloc] initWithApp];
     _importType = EOAImportTypeCheckDuplicates;
     return self;
 }

- (void) executeParameters
{
    [self onPreExecute];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<OASettingsItem *> *items = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:items];
        });
    });
}

- (void) onPreExecute
{
    OAImportAsyncTask* importTask = _settingsHelper.importTask;
    if (importTask != NULL && ![importTask isImportDone])
    {
        [_settingsHelper finishImport:_importListener success:false items:_items];
    }
    _settingsHelper.importTask = self;
}
 
- (NSMutableArray<OASettingsItem *> *) doInBackground
{
    switch (_importType) {
        case EOAImportTypeCollect:
            @try {
                return [_importer collectItems:_filePath];
            } @catch (NSException *exception) {
                NSLog(@"Failed to collect items from: %@ %@", _filePath, exception);
            }
            break;
        case EOAImportTypeCheckDuplicates:
            _duplicates = [self getDuplicatesData:_selectedItems];
            return _selectedItems;
        case EOAImportTypeImport:
            return _items;
    }
    return nil;
}

- (void) onPostExecute:(NSMutableArray<OASettingsItem *> *)items
{
    if (items != NULL && _importType != EOAImportTypeCheckDuplicates)
        _items = items;
    else
        _selectedItems = items;
    switch (_importType) {
        case EOAImportTypeCollect:
            _importDone = YES;
            if (_settingsCollectDelegate)
                [_settingsCollectDelegate onSettingsCollectFinished:YES empty:NO items:_items];
            break;
        case EOAImportTypeCheckDuplicates:
            _importDone = YES;
            if (_duplicatesListener != NULL) {
                if (_checkDuplicatesDelegate)
                    [_checkDuplicatesDelegate onDuplicatesChecked:_duplicates items:_selectedItems];
            }
            break;
        case EOAImportTypeImport:
            if (items != NULL && [items count] > 0)
            {
                for (OASettingsItem *item in items)
                    [item apply];
                
                dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 [[[OAImportItemsAsyncTask alloc] initWithFile:_filePath listener:_importListener items:_items] executeParameters];
                });
            }
            break;
    }
}

- (NSMutableArray<OASettingsItem *> *) getItems
{
    return _items;
}

- (NSString *) getFile
{
    return _filePath;
}

- (void) setImportListener:(OASettingsImport*)importListener
{
    _importListener = importListener;
}
 
- (void) setDuplicatesListener:(OACheckDuplicates*)duplicatesListener
{
    _duplicatesListener = duplicatesListener;
}

- (EOAImportType) getImportType
{
    return _importType;
}

- (BOOL) isImportDone
{
    return _importDone;
}
 
- (NSMutableArray<OASettingsItem *> *) getDuplicates
{
    return _duplicates;
}
 
- (NSMutableArray<OASettingsItem *> *) getSelectedItems
{
    return _selectedItems;
}
 
- (NSArray<id>*) getDuplicatesData:(NSMutableArray<OASettingsItem *> *)items
{
    NSMutableArray<id>* duplicateItems = [NSMutableArray alloc];
    for (OASettingsItem *item in items)
    {
//        if ([item isKindOfClass:ProfileSettingsItem]) {
//            if ([item exists])
//                [duplicateItems addObject:[(ProfileSettingsItem*)item getModeBean];];
//        } else
//        if ([item isKindOfClass:OACollectionSettingsItem.class])
//        {
//            NSArray *duplicates = [(OACollectionSettingsItem *)item excludeDuplicateItems];
//            if (!duplicates.count)
//                [duplicateItems addObjectsFromArray:duplicates];
//        }
//        else if ([item isKindOfClass:OAFileSettingsItem.class])
//        {
//            if ([item exists])
//                [duplicateItems addObject:[(OAFileSettingsItem *)item getFileName]];
//        }
    }
    return duplicateItems;
}

@end

#pragma mark - OAImportItemsAsyncTask

@interface OAImportItemsAsyncTask()

@property (nonatomic) NSString *file;
@property (nonatomic) NSMutableArray<OASettingsItem *> *items;
@property (weak, nonatomic) id<OASettingsImportDelegate> settingsImportDelegate;

@end

@implementation OAImportItemsAsyncTask
{
    OASettingsHelper *_settingsHelper;
    OASettingsImporter *_importer;
    OASettingsImport *_importListener;
}

- (instancetype) initWithFile:(NSString *)file listener:(OASettingsImport *)listener items:(NSArray<OASettingsItem *> *)items
{
    _importer = [[OASettingsImporter alloc] initWithApp];
    _settingsHelper = [OASettingsHelper sharedInstance];
    _file = file;
    _importListener = listener;
    _items = items;
    return self;
}

- (void) executeParameters
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:YES];
        });
    });
}

- (BOOL) doInBackground
{
    @try {
        [_importer importItems:_file items:_items];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"Failed to import items from: %@", exception);
    }
    return NO;
}
 
- (void) onPostExecute:(BOOL)success
{
    [_settingsHelper finishImport:_importListener success:success items:_items];
}

@end
