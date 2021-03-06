//
//  JKExpandTableView.m
//  ExpandTableView
//
//  Created by Jack Kwok on 7/5/13.
//  Copyright (c) 2013 Jack Kwok. All rights reserved.
//

#import "JKExpandTableView.h"
#import "JKParentTableViewCell.h"
#import "JKMultiSelectSubTableViewCell.h"
#import "JKSingleSelectSubTableViewCell.h"

@interface JKExpandTableView ()
@property(nonatomic, strong) NSMutableArray *expansionStates;
@end

@implementation JKExpandTableView

#define HEIGHT_FOR_CELL 44.0

- (id)initWithFrame:(CGRect)frame dataSource:dataDelegate tableViewDelegate:tableDelegate {
	self = [super initWithFrame:frame style:UITableViewStylePlain];
	// self = [super initWithFrame:frame style:UITableViewStyleGrouped];
	if (self) {
		// Initialization code
		[self initialize];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		// Initialization code
		[self initialize];
	}
	return self;
}

- (void)initialize
{
	[self setDataSource:self];
	[self setDelegate:self];
	self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	// Trick to hide UITableView Empty Cell Separator Lines (stuff below last nonempty cell)
	UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
	self.tableFooterView = footer;
}

- (void)setDataSourceDelegate:(id<JKExpandTableViewDataSource>)dataSourceDelegate
{
	_dataSourceDelegate = dataSourceDelegate;
	[self initExpansionStates];
}

- (void)initExpansionStates
{
	// all collapsed initially
	self.expansionStates = [[NSMutableArray alloc] initWithCapacity:[self.dataSourceDelegate numberOfParentCells]];
	for (NSInteger i = 0; i < [self.dataSourceDelegate numberOfParentCells]; i++) {
		[self.expansionStates addObject:@"NO"];
	}
}

- (void)expandForParentAtRow:(NSInteger)row
{
	NSUInteger parentIndex = [self parentIndexForRow:row];
    
	if ([self isParentExpandedAtIndex:parentIndex]) {
		return;
	}
	// update expansionStates so backing data is ready before calling insertRowsAtIndexPaths
	[self.expansionStates replaceObjectAtIndex:parentIndex withObject:@"YES"];
    
	[self insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:(row + 1) inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)collapseForParentAtRow:(NSInteger)row
{
	NSUInteger parentIndex = [self parentIndexForRow:row];
    
	if (![self isParentExpandedAtIndex:parentIndex]) {
		return;
	}
	// update expansionStates so backing data is ready before calling deleteRowsAtIndexPaths
	[self.expansionStates replaceObjectAtIndex:parentIndex withObject:@"NO"];
    
	[self deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:(row + 1) inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)animateParentCellIconExpand:(BOOL)expand forCell:(JKParentTableViewCell *)cell
{
	if ([self.dataSourceDelegate respondsToSelector:@selector(shouldRotateIconForParentOnToggle)] &&
		([self.dataSourceDelegate shouldRotateIconForParentOnToggle] == NO))
	{
	} else {
		if (expand) {
			[cell rotateIconToExpanded];
		} else {
			[cell rotateIconToCollapsed];
		}
	}
}

- (NSUInteger)rowForParentIndex:(NSUInteger)parentIndex
{
	NSUInteger row = 0;
	NSUInteger currentParentIndex = 0;
    
	if (parentIndex == 0) {
		return 0;
	}
    
	while (currentParentIndex < parentIndex) {
		BOOL expanded = [self isParentExpandedAtIndex:currentParentIndex];
		if (expanded) {
			row++;
		}
		currentParentIndex++;
		row++;
	}
	return row;
}

- (NSUInteger)parentIndexForRow:(NSUInteger)row
{
	NSUInteger parentIndex = -1;
    
	NSUInteger i = 0;
    
	while (i <= row) {
		parentIndex++;
		i++;
		if ([self isParentExpandedAtIndex:parentIndex]) {
			i++;
		}
	}
	return parentIndex;
}

- (BOOL)isExpansionCell:(NSUInteger)row
{
	if (row < 1) {
		return NO;
	}
	NSUInteger parentIndex = [self parentIndexForRow:row];
	NSUInteger parentIndex2 = [self parentIndexForRow:(row - 1)];
	return (parentIndex == parentIndex2);
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// returns sum of parent cells and expanded cells
	NSInteger parentCount = [self.dataSourceDelegate numberOfParentCells];
	NSCountedSet *countedSet = [[NSCountedSet alloc] initWithArray:self.expansionStates];
	NSUInteger expandedParentCount = [countedSet countForObject:@"YES"];
    
	return parentCount + expandedParentCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier_Parent = @"CellReuseId_Parent";
	static NSString *CellIdentifier_MultiSelect = @"CellReuseId_MultiSelectExpand";
	static NSString *CellIdentifier_SingleSelect = @"CellReuseId_SingleSelectExpand";
    
	NSInteger row = indexPath.row;
	NSUInteger parentIndex = [self parentIndexForRow:row];
	BOOL isExpansionCell = [self isExpansionCell:row];
    
	if (isExpansionCell) {
		BOOL isMultiSelect = [self.tableViewDelegate shouldSupportMultipleSelectableChildrenAtParentIndex:parentIndex];
		if (isMultiSelect) {
			JKMultiSelectSubTableViewCell *cell = (JKMultiSelectSubTableViewCell *)[self dequeueReusableCellWithIdentifier:CellIdentifier_MultiSelect];
			if (cell == nil) {
				cell = [[JKMultiSelectSubTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_MultiSelect];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(backgroundColor)]) {
				UIColor *bgColor = [self.tableViewDelegate backgroundColor];
				[cell setSubTableBackgroundColor:bgColor];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(foregroundColor)]) {
				UIColor *fgColor = [self.tableViewDelegate foregroundColor];
				[cell setSubTableForegroundColor:fgColor];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(selectionOnIndicatorIcon)]) {
				[cell setSelectionOnIndicatorImg:[self.tableViewDelegate selectionOnIndicatorIcon]];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(selectionOffIndicatorIcon)]) {
				[cell setSelectionOffIndicatorImg:[self.tableViewDelegate selectionOffIndicatorIcon]];
			}
            
			[cell setParentIndex:parentIndex];
			[cell setDelegate:self];
			[cell reload];
			return cell;
		} else {
			JKSingleSelectSubTableViewCell *cell = (JKSingleSelectSubTableViewCell *)[self dequeueReusableCellWithIdentifier:CellIdentifier_SingleSelect];
			if (cell == nil) {
				cell = [[JKSingleSelectSubTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_SingleSelect];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(backgroundColor)]) {
				UIColor *bgColor = [self.tableViewDelegate backgroundColor];
				[cell setSubTableBackgroundColor:bgColor];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(foregroundColor)]) {
				UIColor *fgColor = [self.tableViewDelegate foregroundColor];
				[cell setSubTableForegroundColor:fgColor];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(selectionOnIndicatorIcon)]) {
				[cell setSelectionOnIndicatorImg:[self.tableViewDelegate selectionOnIndicatorIcon]];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(selectionOffIndicatorIcon)]) {
				[cell setSelectionOffIndicatorImg:[self.tableViewDelegate selectionOffIndicatorIcon]];
			}
            
			if ([self.tableViewDelegate respondsToSelector:@selector(fontForChildren)]) {
				UIFont *font = [self.tableViewDelegate fontForChildren];
				[cell setSubTableFont:font];
			}
            
			[cell setParentIndex:parentIndex];
			[cell setDelegate:self];
			[cell reload];
			return cell;
		}
	} else {
		// regular parent cell
		JKParentTableViewCell *cell = (JKParentTableViewCell *)[self dequeueReusableCellWithIdentifier:CellIdentifier_Parent];
		if (cell == nil) {
			cell = [[JKParentTableViewCell alloc] initWithReuseIdentifier:CellIdentifier_Parent];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(backgroundColor)]) {
			UIColor *bgColor = [self.tableViewDelegate backgroundColor];
			[cell setCellBackgroundColor:bgColor];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(foregroundColor)]) {
			UIColor *fgColor = [self.tableViewDelegate foregroundColor];
			[cell setCellForegroundColor:fgColor];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(displaysPartialSelectionIndicator)]) {
			[cell setDisplaysPartialSelectionIndicator:[self.tableViewDelegate displaysPartialSelectionIndicator]];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(partialSelectionIndicatorIcon)]) {
			[cell setPartialSelectionIndicatorImg:[self.tableViewDelegate partialSelectionIndicatorIcon]];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(selectionOnIndicatorIcon)]) {
			[cell setSelectionIndicatorImg:[self.tableViewDelegate selectionOnIndicatorIcon]];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(fontForParents)]) {
			UIFont *font = [self.tableViewDelegate fontForParents];
			[cell.label setFont:font];
		}
        
		NSString *labelStr = [self.dataSourceDelegate labelForParentCellAtIndex:parentIndex];
		[[cell label] setText:labelStr];
        
		if ([self.dataSourceDelegate respondsToSelector:@selector(iconForParentCellAtIndex:)]) {
			UIImage *icon = [self.dataSourceDelegate iconForParentCellAtIndex:parentIndex];
			[[cell iconImage] setImage:icon];
		}
        
		[cell setParentIndex:parentIndex];
		[cell setSelectionIndicatorState:[self hasSelectedChild:parentIndex]];
        
		[cell.selectionIndicatorImgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(parentCellSelectionIndicatorWasTapped:)]];
		cell.selectionIndicatorImgView.userInteractionEnabled = YES;
        
		// [cell setupDisplay];
        
		return cell;
	}
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
    
	// if cell is expanded, the cell height would be a multiple of the number of child cells
	BOOL isExpansionCell = [self isExpansionCell:row];
	if (isExpansionCell) {
		NSInteger parentIndex = [self parentIndexForRow:row];
		NSInteger numberOfChildren = [self.dataSourceDelegate numberOfChildCellsUnderParentIndex:parentIndex];
		return HEIGHT_FOR_CELL * numberOfChildren;
	} else {
		return HEIGHT_FOR_CELL;
	}
}

- (void)parentCellSelectionIndicatorWasTapped:(UITapGestureRecognizer *)gesture
{
	if (gesture.state != UIGestureRecognizerStateRecognized) {
		return;
	}
    
	UIView *aView = gesture.view;
	while (aView && ![aView isKindOfClass:[JKParentTableViewCell class]])
		aView = aView.superview;
    
	if ([aView isKindOfClass:[JKParentTableViewCell class]]) {
		JKParentTableViewCell *pCell = (JKParentTableViewCell *)aView;
        
		if ([self.tableViewDelegate respondsToSelector:@selector(tableView:handleParentCellSelectionIndicatotTapAtIndex:)]) {
			if ([self.tableViewDelegate tableView:self handleParentCellSelectionIndicatotTapAtIndex:[pCell parentIndex]]) {
				return;
			}
		}
        
		// else, if not handled or doesn't respond to:
		[self tableView:self didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:[self rowForParentIndex:[pCell parentIndex]] inSection:0]];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// if parent , expand/collpase then notify delegate (always check respond to selector)
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
	if ([selectedCell isKindOfClass:[JKParentTableViewCell class]]) {
		JKParentTableViewCell *pCell = (JKParentTableViewCell *)selectedCell;
        
		if ([self isParentExpandedAtIndex:[pCell parentIndex]]) {
			[self collapseForParentAtRow:indexPath.row];
			[self animateParentCellIconExpand:NO forCell:pCell];              // TODO handle the case where there is no child.
		} else {
			[self expandForParentAtRow:indexPath.row];
			[self animateParentCellIconExpand:YES forCell:pCell];
		}
        
		if ([self.tableViewDelegate respondsToSelector:@selector(tableView:didSelectParentCellAtIndex:)]) {
			[self.tableViewDelegate tableView:tableView didSelectParentCellAtIndex:[pCell parentIndex]];
		}
	} else {
		// ignore clicks on child because the sub table should handle it.
	}
}

#pragma mark - JKMultiSelectSubTableViewCellDelegate
- (NSInteger)numberOfChildrenUnderParentIndex:(NSInteger)parentIndex
{
	return [self.dataSourceDelegate numberOfChildCellsUnderParentIndex:parentIndex];
}

- (BOOL)isSelectedForChildIndex:(NSInteger)childIndex underParentIndex:(NSInteger)parentIndex
{
	return [self.dataSourceDelegate shouldDisplaySelectedStateForCellAtChildIndex:childIndex withinParentCellIndex:parentIndex];
}

- (void)didSelectRowAtChildIndex:(NSInteger)childIndex
						selected:(BOOL)isSwitchedOn
				underParentIndex:(NSInteger)parentIndex
{
	// check if at least one child is selected.  if yes, set the parent checkmark to indicate at least one chlid selected
    
	if (isSwitchedOn &&
		[self.tableViewDelegate respondsToSelector:@selector(tableView:didSelectCellAtChildIndex:withInParentCellIndex:)])
	{
		[self.tableViewDelegate tableView:self didSelectCellAtChildIndex:childIndex withInParentCellIndex:parentIndex];
	}
    
	if (!isSwitchedOn &&
		[self.tableViewDelegate respondsToSelector:@selector(tableView:didDeselectCellAtChildIndex:withInParentCellIndex:)])
	{
		[self.tableViewDelegate tableView:self didDeselectCellAtChildIndex:childIndex withInParentCellIndex:parentIndex];
	}
    
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self rowForParentIndex:parentIndex] inSection:0];
	UITableViewCell *selectedCell = [self cellForRowAtIndexPath:indexPath];
	if ([selectedCell isKindOfClass:[JKParentTableViewCell class]]) {
		JKParentTableViewCell *pCell = (JKParentTableViewCell *)selectedCell;
		[pCell setSelectionIndicatorState:[self hasSelectedChild:parentIndex]];
	}
}

- (NSString *)labelForChildIndex:(NSInteger)childIndex underParentIndex:(NSInteger)parentIndex
{
	return [self.dataSourceDelegate labelForCellAtChildIndex:childIndex withinParentCellIndex:parentIndex];
}

- (UIImage *)iconForChildIndex:(NSInteger)childIndex underParentIndex:(NSInteger)parentIndex
{
	if ([self.dataSourceDelegate respondsToSelector:@selector(iconForCellAtChildIndex:withinParentCellIndex:)]) {
		return [self.dataSourceDelegate iconForCellAtChildIndex:childIndex withinParentCellIndex:parentIndex];
	} else {
		return nil;
	}
}
- (CGFloat)indentForChildren
{
    if ([self.tableViewDelegate respondsToSelector:@selector(indentForChildren)]) {
        return [self.tableViewDelegate indentForChildren];
    }
    return -1;
}
@end

@implementation JKExpandTableView (CurrentStatus)
- (BOOL)isParentExpandedAtIndex:(NSInteger)parentIndex
{
    if (parentIndex < 0 || parentIndex >= self.expansionStates.count) {
        return NO;
    }
    return [self.expansionStates[parentIndex] boolValue];
}

- (JKExpandedTableSelectionIndicatorState)hasSelectedChild:(NSInteger)parentIndex
{
	NSInteger numberOfChildren = [self.dataSourceDelegate numberOfChildCellsUnderParentIndex:parentIndex];
	NSInteger numberOfSelectedChildren = 0;
    
	for (NSInteger i = 0; i < numberOfChildren; i++) {
		if ([self.dataSourceDelegate shouldDisplaySelectedStateForCellAtChildIndex:i withinParentCellIndex:parentIndex]) {
			++numberOfSelectedChildren;
            
			if (![self.tableViewDelegate respondsToSelector:@selector(displaysPartialSelectionIndicator)] || ![self.tableViewDelegate displaysPartialSelectionIndicator]) {
				return JKExpandedTableSelectionIndicatorAll;
			}
		}
	}
	if (numberOfSelectedChildren == 0) {
		return JKExpandedTableSelectionIndicatorNone;
	}
	if (numberOfSelectedChildren == numberOfChildren) {
		return JKExpandedTableSelectionIndicatorAll;
	}
	return JKExpandedTableSelectionIndicatorPartial;
}

- (void)toggleSelectionForParentAtIndex:(NSInteger)parentIndex
{
    BOOL target = YES;
    if ([self hasSelectedChild:parentIndex] == JKExpandedTableSelectionIndicatorAll) {
        target = NO;
    }
    for (NSInteger childIndex = 0; childIndex < [self.dataSourceDelegate numberOfChildCellsUnderParentIndex:parentIndex]; childIndex++) {
        if (target) {
            if ([self.tableViewDelegate respondsToSelector:@selector(tableView:didSelectCellAtChildIndex:withInParentCellIndex:)]) {
                [self.tableViewDelegate tableView:self didSelectCellAtChildIndex:childIndex withInParentCellIndex:parentIndex];
            }
            
        } else {
            if ([self.tableViewDelegate respondsToSelector:@selector(tableView:didDeselectCellAtChildIndex:withInParentCellIndex:)]) {
                [self.tableViewDelegate tableView:self didDeselectCellAtChildIndex:childIndex withInParentCellIndex:parentIndex];
            }
        }
    }
}
@end

@implementation JKExpandTableView (StoreAndRetrieve)
- (NSString*)_strip:(NSString*)string
{
    NSString *allowed = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-0123456789";
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:allowed] invertedSet];
    return [[string componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
}
- (void)storeCurrentExpandedParentsInto:(NSUserDefaults*)userDefaults
{
    for (NSInteger i = 0; i < [self.dataSourceDelegate numberOfParentCells]; i++) {
        NSString * label = [self.dataSourceDelegate labelForParentCellAtIndex:i];
        if (label) {
            label = [NSString stringWithFormat:@"com.jkexpandedtableview.storedstate.%@", [self _strip:label]];
            BOOL expand = [self isParentExpandedAtIndex:i];
            [userDefaults setBool:expand forKey:label];
        }
    }
}
- (void)restoreCurrentExpandedParentsFrom:(NSUserDefaults*)userDefaults
                                  default:(BOOL)expanded
{
    for (NSInteger i = 0; i < [self.dataSourceDelegate numberOfParentCells]; i++) {
        NSString * label = [self.dataSourceDelegate labelForParentCellAtIndex:i];
        if (label) {
            label = [NSString stringWithFormat:@"com.jkexpandedtableview.storedstate.%@", [self _strip:label]];
            BOOL expandThis = expanded;
            NSNumber * expandValue = [userDefaults valueForKey:label];
            if (expandValue) {
                expandThis = [expandValue boolValue];
            }
            if (expandThis) {
                NSInteger cellIndex = [self rowForParentIndex:i];
                [self expandForParentAtRow:cellIndex];
                UITableViewCell *selectedCell = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:cellIndex inSection:0]];
                
                if ([selectedCell isKindOfClass:[JKParentTableViewCell class]]) {
                    JKParentTableViewCell *pCell = (JKParentTableViewCell *)selectedCell;
                    
                    [self animateParentCellIconExpand:YES forCell:pCell];
                    
                }
            }
        }
    }
}
@end
