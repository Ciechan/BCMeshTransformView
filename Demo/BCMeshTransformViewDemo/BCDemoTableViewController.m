//
//  BCDemoTableViewController.m
//  BCMeshTransformViewDemo
//
//  Created by Bartosz Ciechanowski on 11/05/14.
//  Copyright (c) 2014 Bartosz Ciechanowski. All rights reserved.
//

#import "BCDemoTableViewController.h"

#import "BCZoomDemoViewController.h"
#import "BCCurtainDemoViewController.h"
#import "BCJellyDemoViewController.h"


static NSString * const BCNameKey = @"name";
static NSString * const BCClassKey = @"class";

static NSString * const BCCellReuseIdentifier = @"BCCellReuseIdentifier";

@interface BCDemoTableViewController ()

@property (nonatomic, strong) NSArray *demoViewControllersDicts;

@end


@implementation BCDemoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Demos";
        self.demoViewControllersDicts =
        @[
          @{BCNameKey: @"Curtain", BCClassKey : [BCCurtainDemoViewController class]},
          @{BCNameKey: @"Zoom", BCClassKey : [BCZoomDemoViewController class]},
          @{BCNameKey: @"Jelly",  BCClassKey : [BCJellyDemoViewController class]},
          ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:BCCellReuseIdentifier];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.demoViewControllersDicts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BCCellReuseIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = self.demoViewControllersDicts[indexPath.row][BCNameKey];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class class = self.demoViewControllersDicts[indexPath.row][BCClassKey];
    BCDemoViewController *demoController = [class new];
    demoController.title = self.demoViewControllersDicts[indexPath.row][BCNameKey];
    
    [self.navigationController pushViewController:demoController animated:YES];
}

@end
