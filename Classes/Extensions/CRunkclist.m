/* Copyright (c) 1996-2014 Clickteam
*
* This source code is part of the iOS exporter for Clickteam Multimedia Fusion 2
* and Clickteam Fusion 2.5.
* 
* Permission is hereby granted to any person obtaining a legal copy 
* of Clickteam Multimedia Fusion 2 or Clickteam Fusion 2.5 to use or modify this source 
* code for debugging, optimizing, or customizing applications created with 
* Clickteam Multimedia Fusion 2 and/or Clickteam Fusion 2.5. 
* Any other use of this source code is prohibited.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/
//
//  CRunkclist.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 1/10/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "CRunExtension.h"
#import "CExtension.h"
#import "CRun.h"
#import "CFile.h"
#import "CCreateObjectInfo.h"
#import "CBitmap.h"
#import "CMask.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CFontInfo.h"
#import "CRect.h"
#import "CImage.h"
#import "CValue.h"
#import "CRunkclist.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CServices.h"
#import "CArrayList.h"
#import "CRunView.h"

@implementation CRunkclist

// Flags
#define LIST_FREEFLAG 0x0001
#define LIST_VSCROLLBAR 0x0002
#define LIST_SORT 0x0004
#define LIST_BORDER 0x0008
#define LIST_HIDEONSTART 0x0010
#define LIST_SYSCOLOR 0x0020
#define LIST_3DLOOK 0x0040
#define LIST_SCROLLTONEWLINE 0x0080
#define LIST_JUSTCREATED 0x8000
// Condition identifiers
#define CND_VISIBLE 0
#define CND_ENABLE 1
#define CND_DOUBLECLICKED 2
#define CND_SELECTIONCHANGED 3
#define CND_HAVEFOCUS 4
#define CND_LAST 5
// Action identifiers
#define ACT_LOADLIST 0
#define ACT_LOADDRIVESLIST 1
#define ACT_LOADDIRECTORYLIST 2
#define ACT_LOADFILESLIST 3
#define ACT_SAVELIST 4
#define ACT_RESET 5
#define ACT_ADDLINE 6
#define ACT_INSERTLINE 7
#define ACT_DELLINE 8
#define ACT_SETCURRENTLINE 9
#define ACT_SHOW 10
#define ACT_HIDE 11
#define ACT_ACTIVATE 12
#define ACT_ENABLE 13
#define ACT_DISABLE 14
#define ACT_SETPOSITION 15
#define ACT_SETXPOSITION 16
#define ACT_SETYPOSITION 17
#define ACT_SETSIZE 18
#define ACT_SETXSIZE 19
#define ACT_SETYSIZE 20
#define ACT_DESACTIVATE 21
#define ACT_SCROLLTOTOP 22
#define ACT_SCROLLTOLINE 23
#define ACT_SCROLLTOEND 24
#define ACT_SETCOLOR 25
#define ACT_SETBKDCOLOR 26
#define ACT_LOADFONTSLIST 27
#define ACT_LOADFONTSIZESLIST 28
#define ACT_SETLINEDATA 29
#define ACT_CHANGELINE 30
#define ACT_LAST 31
// Expression identifiers
#define EXP_GETSELECTINDEX 0
#define EXP_GETSELECTTEXT 1
#define EXP_GETSELECTDIRECTORY 2
#define EXP_GETSELECTDRIVE 3
#define EXP_GETLINETEXT 4
#define EXP_GETLINEDIRECTORY 5
#define EXP_GETLINEDRIVE 6
#define EXP_GETNBLINE 7
#define EXP_GETXPOSITION 8
#define EXP_GETYPOSITION 9
#define EXP_GETXSIZE 10
#define EXP_GETYSIZE 11
#define EXP_GETCOLOR 12
#define EXP_GETBKDCOLOR 13
#define EXP_FINDSTRING 14
#define EXP_FINDSTRINGEXACT 15
#define EXP_GETLASTINDEX 16
#define EXP_GETLINEDATA 17
#define EXP_LAST 18


// List detail
#define LIST_IOS_LD    0x00030000 // mask
#define LIST_IOS_LD_NONE  0x00000000
#define LIST_IOS_LD_CHECKMARK 0x00010000
#define LIST_IOS_LD_DISCLOSUREINDICATOR 0x00020000
#define LIST_IOS_LD_DISCLOSUREBUTTON 0x00030000

// Detail mode
#define LIST_IOS_DM    0x000C0000 // mask
#define LIST_IOS_DM_ALL   0x00000000
#define LIST_IOS_DM_SELECTED 0x00040000
#define LIST_IOS_DM_LINEDATA 0x00080000

#define LIST_IOS_TABLE   0x00100000                                // flag = 1 if table view
#define LIST_IOS_NOTALWAYSFILLSCREEN 0x00200000    // flag = 0 if "always fill screen width"
#define LIST_IOS_GROUPED_STYLE 0x00400000                // flag = 1 if grouped style




-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	list = [[CArrayList alloc] init];
	
	selectionChangedIgnore = NO;
	ho->hoImgWidth = [file readAShort];
	ho->hoImgHeight = [file readAShort];
	oldWidth=ho->hoImgWidth;
	oldHeight=ho->hoImgHeight;

	pickerView = nil;
	tableView = nil;
	
	if(file->bUnicode)
		listFontInfo = [file readLogFont];
	else
		listFontInfo = [file readLogFont16];
	font = [listFontInfo createFont];
	
	listFontFore = [file readAColor];
	[file skipStringOfLength:40];
	[file skipBytes:16*4];
	
	listFontBack = [file readAColor];
	flags = [file readAInt];
	
	int lineNumbers = [file readAShort];
	
	// If TRUE, indexes are 1-based. So the index offset is -1 when true
	// (subtract one from value provided) and 0 when false (no modification)
	indexOffset = ([file readAInt] == 1) ? -1 : 0;
	
	// Skip three longs (lSecu)
	[file skipBytes:4*3];
	
	// Creates the list
	sort = ((flags & LIST_SORT) !=0 );
	scrollToNewLine = ((flags & LIST_SCROLLTONEWLINE) !=0 );
	hideOnStart = ((flags&LIST_HIDEONSTART)!=0);
	
	// Insert the strings
	BOOL selectLine = NO;
	while (lineNumbers > 0)
	{
		NSString* line = [file readAString];
		[self actAddLine:line];
		lineNumbers--;
		selectLine = YES;
	}
	
	doubleClickedEvent=-1;
	selectionChangedEvent=-1;
	lastIndex=0;
	runView = rh->rhApp->runView;
	
	headerTitle = @"";
	
	//New properties
	listType = ((flags & LIST_IOS_TABLE) != 0);
	tableStyle = ((flags & LIST_IOS_GROUPED_STYLE) != 0);
	fillWidth = !((flags & LIST_IOS_NOTALWAYSFILLSCREEN) != 0);
	
	switch (flags & LIST_IOS_DM) {
		case LIST_IOS_DM_ALL:
			detailMethod = 0;
			break;
		case LIST_IOS_DM_SELECTED:
			detailMethod = 1;
			break;
		case LIST_IOS_DM_LINEDATA:
			detailMethod = 2;
			break;
	}
		
	switch (flags & LIST_IOS_LD) {
		case LIST_IOS_LD_NONE:
			accessoryView = 0;
			break;
		case LIST_IOS_LD_CHECKMARK:
			accessoryView = 1;
			break;
		case LIST_IOS_LD_DISCLOSUREINDICATOR:
			accessoryView = 2;
			break;
		case LIST_IOS_LD_DISCLOSUREBUTTON :
			accessoryView = 3;
			break;
	}

	if(!hideOnStart)
		[self createListIfNessecary];

	return false;
}

-(void)createListIfNessecary
{
	if(pickerView != nil || tableView != nil)
		return;

	UIColor* backgroundColor = [UIColor colorWithRed:getR(listFontBack) green:getG(listFontBack) blue:getB(listFontBack) alpha:1.0];

	UIView* view = nil;
	if(listType == 0)
	{
		pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, 0)];
		pickerView.backgroundColor = backgroundColor;
		pickerView.hidden = hideOnStart;
		pickerView.showsSelectionIndicator = YES;
		pickerView.dataSource = self;
		pickerView.delegate = self;

		//Ignore vertical scaling of this control (as UIPickerViews are fixed height)
		ho->hoImgHeight = pickerView.frame.size.height;
		ho->controlScaleY = 1;
		view = pickerView;
	}
	else if(listType == 1)
	{
		UITableViewStyle style = ((tableStyle == 0) ? UITableViewStylePlain : UITableViewStyleGrouped);
		tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,1,1) style:style];
		tableView.backgroundColor = backgroundColor;
		tableView.hidden = hideOnStart;
		tableView.dataSource = self;
		tableView.delegate = self;
		view = tableView;

		UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
		doubleTap.numberOfTapsRequired = 2;
		doubleTap.numberOfTouchesRequired = 1;
		[tableView addGestureRecognizer:doubleTap];
	}

	if(fillWidth)
	{
		ho->hoX = 0;
		ho->hoImgWidth = ho->hoAdRunHeader->rhApp->runView.bounds.size.width;
	}
	[runView addSubview:view];
}

-(int)handleRunObject;
{
	return REFLAG_ONESHOT;
}

-(void)destroyRunObject:(BOOL)bFast;
{
	if(pickerView != nil)
	{
		pickerView.delegate = nil;
		pickerView.dataSource = nil;
		[pickerView removeFromSuperview];
		[pickerView release];
	}
	
	if(tableView != nil)
	{
		tableView.delegate = nil;
		tableView.dataSource = nil;
		[tableView removeFromSuperview];
		[tableView release];
	}
	
	[list clearRelease];
	[list release];
}

-(void)displayRunObject:(CRenderer*)renderer
{
	if(pickerView != nil)
		[rh->rhApp positionUIElement:pickerView withObject:ho];
	if(tableView != nil)
		[rh->rhApp positionUIElement:tableView withObject:ho];
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_VISIBLE:
			return isVisible;
		case CND_ENABLE:
			return isEnabled;
		case CND_DOUBLECLICKED:
			return true;
		case CND_SELECTIONCHANGED:
			return [self cndSelectionChanged];
		case CND_HAVEFOCUS:
			return hasFocus;
	}
	return false;
}


-(BOOL)cndSelectionChanged
{
	// This is a true event, so was pushed
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
		return YES;

	// Event occured this event loop
	if (selectionChangedEvent == [ho getEventCount])
		return YES;
	return NO;
}



-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_LOADLIST:
            [self actLoadList:act];
            break;
		case ACT_SAVELIST:
            [self actSaveList:act];
            break;
		case ACT_LOADDRIVESLIST:
		case ACT_LOADDIRECTORYLIST:
		case ACT_LOADFILESLIST:
		case ACT_ACTIVATE:
		case ACT_ENABLE:
		case ACT_DISABLE:
		case ACT_DESACTIVATE:
		case ACT_SETCOLOR:
		case ACT_SETBKDCOLOR:
			break;
			
		case ACT_RESET:
			[self actReset];
			break;
		case ACT_ADDLINE:
			[self actAddLine:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_INSERTLINE:
		{
			int index = [act getParamExpression:rh withNum:0];
			NSString* string = [act getParamExpString:rh withNum:1];
			[self actInsertLine:string atIndex:index];
			break;
		}
		case ACT_DELLINE:
			[self actDelLine:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETCURRENTLINE:
			[self actSetCurrentLine:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SHOW:
			[self createListIfNessecary];
			if(pickerView != nil)
				pickerView.hidden = NO;
			if(tableView != nil)
				tableView.hidden = NO;
			break;
		case ACT_HIDE:
			if(pickerView != nil)
				pickerView.hidden = YES;
			if(tableView != nil)
				tableView.hidden = YES;
			break;
		case ACT_SETPOSITION:
			ho->hoX = [act getParamExpression:rh withNum:0];
			ho->hoY = [act getParamExpression:rh withNum:1];
			break;
		case ACT_SETXPOSITION:
			ho->hoX = [act getParamExpression:rh withNum:0];
			break;
		case ACT_SETYPOSITION:
			ho->hoY = [act getParamExpression:rh withNum:0];
			break;
		case ACT_SETSIZE:
			ho->hoImgWidth = [act getParamExpression:rh withNum:0];
			ho->hoImgHeight = [act getParamExpression:rh withNum:0];
			break;
		case ACT_SETXSIZE:
			ho->hoImgWidth = [act getParamExpression:rh withNum:0];
			break;
		case ACT_SETYSIZE:
			ho->hoImgHeight = [act getParamExpression:rh withNum:0];
			break;
		case ACT_SCROLLTOTOP:
			if(pickerView != nil)
				[pickerView selectRow:0 inComponent:0 animated:YES];
			if(tableView != nil)
				[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
			break;
		case ACT_SCROLLTOLINE:
			if(pickerView != nil)
				[pickerView selectRow:[act getParamExpression:rh withNum:0] inComponent:0 animated:YES];
			if(tableView != nil)
				[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[act getParamExpression:rh withNum:0] inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
			break;
		case ACT_SCROLLTOEND:
			if(pickerView != nil)
				[pickerView selectRow:[list size]-1 inComponent:0 animated:YES];
			if(tableView != nil)
				[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[list size]-1 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionBottom];
			break;
		case ACT_LOADFONTSLIST:
		{
			NSArray* fontFamilyNames = [UIFont familyNames];
			for(NSString* familyName in fontFamilyNames)
				[self actAddLine:[familyName retain]];
			break;
		}
		case ACT_LOADFONTSIZESLIST:
			break;
		case ACT_SETLINEDATA:
		{
			int index = [act getParamExpression:rh withNum:0];
			int data = [act getParamExpression:rh withNum:1];
			[self actSetLineData:data forLine:index];
			break;
		}
		case ACT_CHANGELINE:
		{
			int index = [act getParamExpression:rh withNum:0];
			NSString* string = [act getParamExpString:rh withNum:1];
			[self actChangeLine:index toString:string];
			break;
		}
		default:
			NSLog(@"Invalid action in List object!");
			break;
	}
}

-(void)reloadData
{
	if(pickerView != nil)
		[pickerView reloadComponent:0];
	if(tableView != nil)
		[tableView reloadData];
}

-(void)actLoadList:(CActExtension*)act
{
    NSString* fileName=[act getParamFilename:rh withNum:0];
    NSData* myData = [rh->rhApp loadResourceData:fileName];
    if (myData != nil && [myData length]!=0)
    {
        [list clearRelease];
        currentLine = 0;

		NSData* myData = [rh->rhApp loadResourceData:fileName];
		if (myData != nil && [myData length]!=0)
		{
			NSString* guess = [rh->rhApp stringGuessingEncoding:myData];
			if(guess != nil)
			{
				NSArray* lines = [guess componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
				for(NSString* s in lines)
				{
					CListItem* item = [[CListItem alloc] initWithString:s andData:0];
					[list add:(void*)item];
					lastIndex = [list size]-1;
				}
			}
		}
        [self reloadData];
    }
}

-(void)actSaveList:(CActExtension*)act
{
    NSString* fileName=[act getParamFilename:rh withNum:0];
    
	//Fix for List object writing faulty data for some encodings
	int count = [list size];
	NSMutableArray* arr = [NSMutableArray arrayWithCapacity:count];
	for(int i=0; i<count; ++i)
	{
		CListItem* listItem = (CListItem*)[list get:i];
		[arr addObject:listItem->string];
	}
	NSString* fString = [arr componentsJoinedByString:@"\n"];
	NSString* path = [[CRunApp getRunApp] getPathForWriting:fileName];
	
	NSError* error = nil;
	[fString writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error];
	if(error != nil)
		NSLog(@"List file write error: %@", error);
}

-(void)actReset
{
	[list clearRelease];
	currentLine = 0;
	[self reloadData];
}

-(void)actAddLine:(NSString*)string
{
	CListItem* item = [[CListItem alloc] initWithString:string andData:0];
	[list add:(void*)item];
	lastIndex = [list size]-1;
	
	if(sort)
		[list sortCListItems];
	
	[self reloadData];
}

-(void)actInsertLine:(NSString*)string atIndex:(int)index
{
	index = clamp(index + indexOffset, 0, [list size]);
	CListItem* item = [[CListItem alloc] initWithString:string andData:0];
	[list addIndex:index object:(void*)item];
	lastIndex=index;
	
	if(sort)
		[list sortCListItems];
	
	[self reloadData];
}

-(void)actChangeLine:(int)index toString:(NSString*)string
{
	//Set tableView header title:
	if(index == -1 && listType == 1 && tableStyle == 1)
	{
		[headerTitle release];
		headerTitle = [string retain];
	}
	
	index += indexOffset;
	if (index >= 0 && index < [list size])
	{
		CListItem* item = (CListItem*)[list get:index];
		[item->string release];
		item->string = [[NSString alloc] initWithString:string];
		
		if(sort)
			[list sortCListItems];
	}
	[self reloadData];
}

-(void)actDelLine:(int)index
{
	index += indexOffset;
	if (index < 0 || index >= [list size])
		return;
	[list removeIndexRelease:index];
	[self reloadData];
}

-(void)setCurrentLine:(int)index
{
	oldLine = currentLine;
	currentLine = index;
	
	if(pickerView != nil)
		[pickerView selectRow:index inComponent:0 animated:NO];
	if(tableView != nil)
		[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
	
	//Reload data if method is to be based on the current line
	if(detailMethod == 1)
		[self reloadData];
}

-(void)actSetCurrentLine:(int)index
{
	index = clamp(index+indexOffset, 0, [list size]);
	[self setCurrentLine:index];
}


-(void)actSetLineData:(int)data forLine:(int)index
{
	index += indexOffset;
	if (index >= 0 && index <= [list size]-1)
	{
		CListItem* item = (CListItem*)[list get:index];
		item->data = data;
	}
	
	//Reload data if set to be based on the line data
	if(detailMethod == 2)
		[self reloadData];
}



-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETSELECTINDEX:
		{
			int selection = currentLine;
			if(selection >= 0)
				selection -= indexOffset;
			return [rh getTempValue:selection];
		}
		case EXP_GETSELECTTEXT:
		{
			if(currentLine < 0 || currentLine >= [list size])
				return [rh getTempString:@""];
			
			CListItem* item = (CListItem*)[list get:currentLine];
			return [rh getTempString:item->string];
		}
		case EXP_GETNBLINE:
			return [rh getTempValue:[list size]];
		case EXP_GETLINETEXT:
			return [self expGetLineText:[[ho getExpParam] getInt]];
		case EXP_GETXPOSITION:
			return [rh getTempValue:ho->hoX];
		case EXP_GETYPOSITION:
			return [rh getTempValue:ho->hoY];
		case EXP_GETXSIZE:
			return [rh getTempValue:ho->hoImgWidth];
		case EXP_GETYSIZE:
			return [rh getTempValue:ho->hoImgHeight];
		case EXP_GETCOLOR:
			return [rh getTempValue:listFontFore];
		case EXP_GETBKDCOLOR:
			return [rh getTempValue:listFontBack];
		case EXP_FINDSTRING:
		{
			NSString* searchString = [[ho getExpParam] getString];
			int startIndex = [[ho getExpParam] getInt];
			return [self expFindString:searchString startingAt:startIndex];
		}
		case EXP_FINDSTRINGEXACT:
		{
			NSString* searchString = [[ho getExpParam] getString];
			int startIndex = [[ho getExpParam] getInt];
			return [self expFindStringExact:searchString startingAt:startIndex];
		}
		case EXP_GETLASTINDEX:
			return [rh getTempValue:lastIndex-indexOffset];
		case EXP_GETLINEDATA:
			return [self expGetLineData:[[ho getExpParam] getInt]];
			
		case EXP_GETSELECTDIRECTORY:
		case EXP_GETSELECTDRIVE:
		case EXP_GETLINEDIRECTORY:
		case EXP_GETLINEDRIVE:
			break;
	}
	return [rh getTempString:@""];
}


-(CValue*)expGetLineText:(int)index
{
	index += indexOffset;
	if(index < 0 || index >= [list size])
		return [rh getTempString:@""];
	
	CListItem* item = (CListItem*)[list get:index];
	return [rh getTempString:item->string];
}

-(CValue*)expFindString:(NSString*)string startingAt:(int)startIndex
{
	if (startIndex > -1)
		startIndex += indexOffset;
	if ((startIndex < 0) || (startIndex >= [list size]))
		startIndex = 0;
	NSInteger ret = [list findString:string startingAt:startIndex];
	if (ret>=0)
		ret-=indexOffset;
	return [rh getTempValue:(int)ret];
}

-(CValue*)expFindStringExact:(NSString*)string startingAt:(int)startIndex
{
	if (startIndex > -1)
		startIndex += indexOffset;
	if ((startIndex < 0) || (startIndex >= [list size]))
		startIndex = 0;
	NSInteger ret = [list findStringExact:string startingAt:startIndex];
	if (ret>=0)
		ret-=indexOffset;
	return [rh getTempValue:(int)ret];
}

-(CValue*)expGetLineData:(int)index
{
	if(currentLine < 0 || currentLine >= [list size])
		return [rh getTempValue:0];
	
	CListItem* item = (CListItem*)[list get:currentLine];
	return [rh getTempValue:item->data];
}


//PickerView delegates
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
	return 1;
}

-(void)pickerView:(UIPickerView*)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[self setCurrentLine:(int)row];
	[ho pushEvent:CND_SELECTIONCHANGED withParam:0];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if([list size] == 0)
		return 1;
	return (NSInteger)[list size];
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if([list size] == 0)
		return @"";

	CListItem* item = (CListItem*)[list get:(int)row];
	
	//Prevent reading any nulls (should not happen)
	if (item == nil || (item != nil && item->string == nil))
		return [[NSString alloc] initWithString:@""];
	
	return [[NSString stringWithString:item->string] retain];
}







//Tableview delegates
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(UITableViewCell*)tableView:(UITableView*)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

	if(cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];

	CListItem* item = (CListItem*)[list get:indexPath.row];
	if (item == nil || (item != nil && item->string == nil))
		cell.textLabel.text = @"";
	else
		cell.textLabel.text = item->string;

	cell.textLabel.font = font;

	[self styleTableCell:cell withListItem:item andRow:indexPath.row];
	return cell;
}

-(void)styleTableCell:(UITableViewCell*)cell withListItem:(CListItem*)item andRow:(NSInteger)row
{
	UITableViewCellAccessoryType accesoryType = UITableViewCellAccessoryNone;
	switch (accessoryView)
	{
		case 0:
			accesoryType = UITableViewCellAccessoryNone; break;
		case 1:
			accesoryType = UITableViewCellAccessoryCheckmark; break;
		case 2:
			accesoryType = UITableViewCellAccessoryDisclosureIndicator; break;
		case 3:
			accesoryType = UITableViewCellAccessoryDetailDisclosureButton; break;
	}
	
	if(accessoryView != 0)
	{
		switch (detailMethod) {
			case 0:
			{
				cell.accessoryType = accesoryType;
				break;
			}
			case 1:
			{
				if(row == currentLine)
					cell.accessoryType = accesoryType;
				else
					cell.accessoryType = UITableViewCellAccessoryNone;
				break;
			}
			case 2:
			{
				if(item->data > 0)
					cell.accessoryType = accesoryType;
				else
					cell.accessoryType = UITableViewCellAccessoryNone;
				break;
			}
		}
	}
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return headerTitle;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (NSInteger)[list size];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self setCurrentLine:(int)indexPath.row];
	[ho pushEvent:CND_SELECTIONCHANGED withParam:0];
}

-(void)doubleTap:(UITapGestureRecognizer*)tap
{
	if(UIGestureRecognizerStateEnded == tap.state)
	{
		CGPoint p = [tap locationInView:tap.view];
		NSIndexPath* indexPath = [tableView indexPathForRowAtPoint:p];
		[self setCurrentLine:(int)indexPath.row];
		[ho pushEvent:CND_DOUBLECLICKED withParam:0];
	}
}

-(CFontInfo*)getRunObjectFont
{
	return listFontInfo;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[listFontInfo release];
	listFontInfo = [fi retain];

	[font release];
	font = [listFontInfo createFont];
	[self reloadData];
}

-(int)getRunObjectTextColor
{
	return listFontFore;
}

-(void)setRunObjectTextColor:(int)rgb
{
	listFontFore = rgb;
}


@end

