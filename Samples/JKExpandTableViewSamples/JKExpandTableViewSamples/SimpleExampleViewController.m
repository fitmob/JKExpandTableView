//
//  SimpleExampleViewController.m
//  ExpandTableView
//
//  Created by Jack Kwok on 7/6/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import "SimpleExampleViewController.h"

@interface SimpleExampleViewController ()

@end

@implementation SimpleExampleViewController
@synthesize expandTableView, dataModelArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
		[self initializeSampleDataModel];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
	[self.expandTableView setDataSourceDelegate:self];
	[self.expandTableView setTableViewDelegate:self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.expandTableView restoreCurrentExpandedParentsFrom:[NSUserDefaults standardUserDefaults]];
    });
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)initializeSampleDataModel
{
	self.dataModelArray = [[NSMutableArray alloc] initWithCapacity:3];

	NSMutableArray *parent0 = [NSMutableArray arrayWithObjects:
							   @(YES),
							   @(NO),
							   @(NO),
							   nil];
	NSMutableArray *parent1 = [NSMutableArray arrayWithObjects:
							   @(NO),
							   @(NO),
							   @(NO),
							   nil];
	NSMutableArray *parent2 = [NSMutableArray arrayWithObjects:
							   @(NO),
							   @(YES),
							   nil];
	NSMutableArray *parent3 = [NSMutableArray arrayWithObjects:
							   @(NO),
							   @(YES),
							   @(NO),
							   nil];
	[self.dataModelArray addObject:parent0];
	[self.dataModelArray addObject:parent1];
	[self.dataModelArray addObject:parent2];
	[self.dataModelArray addObject:parent3];
}

#pragma mark - JKExpandTableViewDelegate
// return YES if more than one child under this parent can be selected at the same time.  Otherwise, return NO.
// it is permissible to have a mix of multi-selectables and non-multi-selectables.
- (BOOL)shouldSupportMultipleSelectableChildrenAtParentIndex:(NSInteger)parentIndex
{
	if ((parentIndex % 2) == 0) {
		return NO;
	} else {
		return YES;
	}
}

- (void)tableView:(UITableView *)tableView didSelectCellAtChildIndex:(NSInteger)childIndex withInParentCellIndex:(NSInteger)parentIndex
{
    self.dataModelArray[parentIndex][childIndex] = @(YES);
	NSLog(@"data array: %@", self.dataModelArray);
}

- (void)tableView:(UITableView *)tableView didDeselectCellAtChildIndex:(NSInteger)childIndex withInParentCellIndex:(NSInteger)parentIndex
{
    self.dataModelArray[parentIndex][childIndex] = @(NO);
	NSLog(@"data array: %@", self.dataModelArray);
}

- (void)tableView:(UITableView *)tableView didSelectParentCellAtIndex:(NSInteger)parentIndex
{
	NSLog(@"Parent selected: data array");
    
    [self.expandTableView storeCurrentExpandedParentsInto:[NSUserDefaults standardUserDefaults]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)tableView:(UITableView *)tableView handleParentCellSelectionIndicatotTapAtIndex:(NSInteger)parentIndex
{
	if ([expandTableView isParentExpandedAtIndex:parentIndex]) {
        
        BOOL target = YES;
        if ([expandTableView hasSelectedChild:parentIndex] == JKExpandedTableSelectionIndicatorAll) {
            target = NO;
        }
        for (NSInteger childIndex = 0; childIndex < [[self.dataModelArray objectAtIndex:parentIndex] count]; childIndex++) {
            self.dataModelArray[parentIndex][childIndex] = @(target);
        }
        [expandTableView reloadData];
        return YES;
    }
    return NO;
}

/*
   - (UIColor *) foregroundColor {
    return [UIColor darkTextColor];
   }

   - (UIColor *) backgroundColor {
    return [UIColor grayColor];
   }
 */
- (UIFont *)fontForParents
{
	return [UIFont fontWithName:@"American Typewriter" size:18];
}

- (UIFont *)fontForChildren
{
	return [UIFont fontWithName:@"American Typewriter" size:18];
}

/*
   - (UIImage *) selectionIndicatorIcon {
    return [UIImage imageNamed:@"green_checkmark"];
   }
 */
#pragma mark - JKExpandTableViewDataSource
- (NSInteger)numberOfParentCells
{
	return [self.dataModelArray count];
}

- (NSInteger)numberOfChildCellsUnderParentIndex:(NSInteger)parentIndex
{
	NSMutableArray *childArray = [self.dataModelArray objectAtIndex:parentIndex];

	return [childArray count];
}

- (NSString *)labelForParentCellAtIndex:(NSInteger)parentIndex
{
	return [NSString stringWithFormat:@"parent %d", parentIndex];
}

- (NSString *)labelForCellAtChildIndex:(NSInteger)childIndex withinParentCellIndex:(NSInteger)parentIndex
{
	return [NSString stringWithFormat:@"child %d of parent %d", childIndex, parentIndex];
}

- (BOOL)shouldDisplaySelectedStateForCellAtChildIndex:(NSInteger)childIndex withinParentCellIndex:(NSInteger)parentIndex
{
	NSMutableArray *childArray = [self.dataModelArray objectAtIndex:parentIndex];

	return [[childArray objectAtIndex:childIndex] boolValue];
}

- (UIImage *)iconForParentCellAtIndex:(NSInteger)parentIndex
{
	return [UIImage imageNamed:@"arrow-icon"];
}

- (UIImage *)iconForCellAtChildIndex:(NSInteger)childIndex withinParentCellIndex:(NSInteger)parentIndex
{
	if (((childIndex + parentIndex) % 3) == 0) {
		return [UIImage imageNamed:@"heart"];
	} else if ((childIndex % 2) == 0) {
		return [UIImage imageNamed:@"cat"];
	} else {
		return [UIImage imageNamed:@"dog"];
	}
}

- (BOOL)shouldRotateIconForParentOnToggle
{
	return YES;
}

- (BOOL)displaysPartialSelectionIndicator
{
	return YES;
}

@end
