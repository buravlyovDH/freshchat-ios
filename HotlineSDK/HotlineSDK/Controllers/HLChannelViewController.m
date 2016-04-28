//
//  HLChannelViewController.m
//  HotlineSDK
//
//  Created by user on 04/11/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "HLChannelViewController.h"
#import "HLMacros.h"
#import "HLTheme.h"
#import "FDLocalNotification.h"
#import "FDChannelUpdater.h"
#import "HLChannel.h"
#import "HLContainerController.h"
#import "FDMessageController.h"
#import "KonotorMessage.h"
#import "KonotorConversation.h"
#import "FDDateUtil.h"
#import "FDUtilities.h"
#import "HLLocalization.h"
#import "FDNotificationBanner.h"
#import "FDBarButtonItem.h"
#import "HLEmptyResultView.h"
#import "FDCell.h"
#import "FDAutolayoutHelper.h"

@interface HLChannelViewController ()

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) HLEmptyResultView *emptyResultView;

@end

@implementation HLChannelViewController

-(void)willMoveToParentViewController:(UIViewController *)parent{
    [super willMoveToParentViewController:parent];
    parent.navigationItem.title = HLLocalizedString(LOC_CHANNELS_TITLE_TEXT);
    HLTheme *theme = [HLTheme sharedInstance];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [theme channelTitleFontColor],
                                                           NSFontAttributeName: [theme channelTitleFont]
                                                           }];
    self.navigationController.navigationBar.barTintColor = [theme navigationBarBackgroundColor];
    self.navigationController.navigationBar.titleTextAttributes = @{
                                                                    NSForegroundColorAttributeName: [theme navigationBarTitleColor],
                                                                    NSFontAttributeName: [theme navigationBarTitleFont]
                                                                    };
    self.channels = [[NSMutableArray alloc] init];
    [self setNavigationItem];
    [self localNotificationSubscription];
}

-(BOOL)canDisplayFooterView{
    return NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self fetchUpdates];
    self.footerView.hidden = YES;
}

-(void)fetchUpdates{
    [self updateChannels];
    FDChannelUpdater *updater = [[FDChannelUpdater alloc]init];
    [[KonotorDataManager sharedInstance]areChannelsEmpty:^(BOOL isEmpty) {
        if(isEmpty)[updater resetTime];
        ShowNetworkActivityIndicator();
        [updater fetchWithCompletion:^(BOOL isFetchPerformed, NSError *error) {
            HideNetworkActivityIndicator();
        }];
    }];
}

-(void)updateChannels{
    [[KonotorDataManager sharedInstance]fetchAllVisibleChannels:^(NSArray *channels, NSError *error) {
        if (!error) {
            NSMutableArray *messages = [NSMutableArray array];
            for(HLChannel *channel in channels){
                KonotorMessage *lastMessage = [self getLastMessageInChannel:channel];
                [messages addObject:lastMessage];
            }
            
            id sort = [NSSortDescriptor sortDescriptorWithKey:@"createdMillis" ascending:NO];
            messages = [[messages sortedArrayUsingDescriptors:@[sort]] mutableCopy];
            
            NSMutableArray *sortedChannel = [[NSMutableArray alloc] init];
            for(KonotorMessage *message in messages){
                [sortedChannel addObject:message.belongsToChannel];
            }
            
            self.channels = sortedChannel;
            if(!self.channels.count){
                HLTheme *theme = [HLTheme sharedInstance];
                self.emptyResultView = [[HLEmptyResultView alloc]initWithImage:[theme getImageWithKey:IMAGE_CHANNEL_ICON] andText:HLLocalizedString(LOC_EMPTY_CHANNEL_TEXT)];
                self.emptyResultView.translatesAutoresizingMaskIntoConstraints = NO;
                [self.view addSubview:self.emptyResultView];
                
                [FDAutolayoutHelper center:self.emptyResultView onView:self.view];
                
            }
            else{
                [self.emptyResultView removeFromSuperview];
            }
            [self.tableView reloadData];
        }
    }];
}

-(void)setNavigationItem{
    UIBarButtonItem *closeButton = [[FDBarButtonItem alloc]initWithTitle:HLLocalizedString(LOC_CHANNELS_CLOSE_BUTTON_TEXT) style:UIBarButtonItemStylePlain target:self action:@selector(closeButton:)];

    if (!self.embedded) {
        self.parentViewController.navigationItem.leftBarButtonItem = closeButton;
    }
    else {
        [self configureBackButtonWithGestureDelegate:nil];
    }
}

-(void)localNotificationSubscription{
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter]addObserverForName:HOTLINE_MESSAGES_DOWNLOADED object:nil queue:nil usingBlock:^(NSNotification *note) {
        HideNetworkActivityIndicator();
        [weakSelf updateChannels];
    }];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"HLChannelsCell";
    
    FDCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[FDCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier isChannelCell:YES];
    }
    
    //Update cell properties
    
    if (indexPath.row < self.channels.count) {
        HLChannel *channel =  self.channels[indexPath.row];

        KonotorMessage *lastMessage = [self getLastMessageInChannel:channel];
        
        cell.titleLabel.text  = channel.name;

        NSDate* date=[NSDate dateWithTimeIntervalSince1970:lastMessage.createdMillis.longLongValue/1000];
        cell.lastUpdatedLabel.text= [FDDateUtil getStringFromDate:date];

        cell.detailLabel.text = [self getDetailDescriptionForMessage:lastMessage];


        NSInteger *unreadCount = [KonotorMessage getUnreadMessagesCountForChannel:channel];
        
        [cell.badgeView updateBadgeCount:unreadCount];

        FDSecureStore *store = [FDSecureStore sharedInstance];
        BOOL showChannelThumbnail = [store boolValueForKey:HOTLINE_DEFAULTS_SHOW_CHANNEL_THUMBNAIL];

        if(showChannelThumbnail){
            if (channel.icon) {
                cell.imgView.image = [UIImage imageWithData:channel.icon];
            }
            else{
                UIImage *placeholderImage = [FDCell generateImageForLabel:channel.name];
                if(channel.iconURL){
                    NSURL *iconURL = [[NSURL alloc]initWithString:channel.iconURL];
                    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:iconURL];
                    __weak FDCell *weakCell = cell;
                    [cell.imgView setImageWithURLRequest:request placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        weakCell.imgView.image = image;
                        channel.icon = UIImagePNGRepresentation(image);
                        [[KonotorDataManager sharedInstance]save];
                    } failure:nil];
                }
                else{
                    cell.imgView.image = placeholderImage;
                }
            }
        }

    }
    
    
    
    [cell adjustPadding];

    return cell;
}

-(NSString *)getDetailDescriptionForMessage:(KonotorMessage *)message{
    
    NSString *description = nil;

    NSInteger messageType = message.messageType.integerValue;
    
    switch (messageType) {
        case KonotorMessageTypeText:
            description = message.text;
            break;
            
        case KonotorMessageTypeAudio:
            description = HLLocalizedString(LOC_AUDIO_MSG_TITLE);
            break;
            
        case KonotorMessageTypePicture:
        case KonotorMessageTypePictureV2:{
            if (message.text) {
                description = message.text;
            }else{
                description = HLLocalizedString(LOC_PICTURE_MSG_TITLE);
            }
            break;
        }
            
        default:
            description = message.text;
            break;
    }
    
    return description;
}

-(KonotorMessage *)getLastMessageInChannel:(HLChannel *)channel{
    NSSortDescriptor *sortDesc =[[NSSortDescriptor alloc] initWithKey:@"createdMillis" ascending:YES];
    NSArray *messages = channel.messages.allObjects;
    return [messages sortedArrayUsingDescriptors:@[sortDesc]].lastObject;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)sectionIndex{
    return self.channels.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < self.channels.count) {
        HLChannel *channel = self.channels[indexPath.row];
        FDMessageController *conversationController = [[FDMessageController alloc]initWithChannel:channel andPresentModally:NO];
        HLContainerController *container = [[HLContainerController alloc]initWithController:conversationController andEmbed:NO];
        [self.navigationController pushViewController:container animated:YES];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 72;
}

-(void)closeButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end