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
//----------------------------------------------------------------------------------
//
// CRUNKCLIST: List object
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CCreateObjectInfo;
@class CActExtension;
@class CCndExtension;
@class CFile;
@class CValue;
@class CArrayList;
@class CFontInfo;
@class CListItem;
@class CRunView;
@class CFont;

@interface CRunkclist : CRunExtension <UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource>
{
	CArrayList* list;
	CFontInfo* listFontInfo;
	UIFont* font;
	int listFontFore;
	int listFontBack;
	int flags;
	int indexOffset;
	BOOL scrollToNewLine;
	BOOL selectionChangedIgnore;
	BOOL bVisible;
	int oldWidth;
	int oldHeight;
	CArrayList* array;
	int doubleClickedEvent;
	int selectionChangedEvent;
	int lastIndex;
	
	BOOL sort;
	BOOL verticalScrollBar;
	BOOL hideOnStart;
	BOOL border;
	BOOL look3D;
	BOOL systemColors;
	
	BOOL isVisible;
	BOOL isEnabled;
	BOOL hasFocus;
	int currentLine;
	int oldLine;
	
	int listType;		//PickerView, TableView
	int tableStyle;		//Plain, Grouped
	int accessoryView;	//None, checkbox, disclosure, disclosure button
	int detailMethod;	//Show for all, Show only for selected item, Show based on line data
	int fillWidth;		//Fill entire view
	NSString* headerTitle;
	
	CRunView* runView;
	UIPickerView* pickerView;
	UITableView* tableView;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;
-(void)createListIfNessecary;

-(void)reloadData;
-(void)setCurrentLine:(int)index;	//Sets the current line (0 based)
-(void)styleTableCell:(UITableViewCell*)cell withListItem:(CListItem*)item andRow:(NSInteger)row;

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

-(BOOL)cndSelectionChanged;

-(void)actReset;
-(void)actAddLine:(NSString*)string;
-(void)actInsertLine:(NSString*)string atIndex:(int)index;
-(void)actChangeLine:(int)index toString:(NSString*)string;
-(void)actDelLine:(int)index;
-(void)actSetCurrentLine:(int)index;
-(void)actSetLineData:(int)data forLine:(int)index;
-(void)actSaveList:(CActExtension*)act;
-(void)actLoadList:(CActExtension*)act;

-(CValue*)expGetLineText:(int)index;
-(CValue*)expFindString:(NSString*)string startingAt:(int)startIndex;
-(CValue*)expFindStringExact:(NSString*)string startingAt:(int)startIndex;
-(CValue*)expGetLineData:(int)index;

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc;
-(int)getRunObjectTextColor;
-(void)setRunObjectTextColor:(int)rgb;

@end


