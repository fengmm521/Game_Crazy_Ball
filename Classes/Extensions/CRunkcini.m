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
// CRUNKCINI : objet ini
//
//----------------------------------------------------------------------------------
#import "CRunkcini.h"
#import "CIni.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CArrayList.h"
#import "CObjInfo.h"
#import "CObject.h"
#import "CRCom.h"


@implementation CRunkcini

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	iniFlags=[file readAShort];
	iniName=[file readAString];
    if ([iniName length]==0)
        iniName= [[NSString alloc] initWithString:@"noname.ini"];
	
	ini=[CIni getINIforFile:iniName];
	saveCounter=0;
	iniCurrentGroup=[[NSString alloc] initWithString:@"Group"];
	iniCurrentItem=[[NSString alloc] initWithString:@"Item"];
	
	return NO;
}
-(void)destroyRunObject:(BOOL)bFast
{
	[CIni closeIni:ini];
	[iniName release];
	[iniCurrentGroup release];
	[iniCurrentItem release];
}
-(int)handleRunObject
{
	if (saveCounter>0)
	{
		saveCounter--;
		if (saveCounter<=0)
		{
			saveCounter=0;
			[ini saveIni];
		}
	}
	return 0;
}
-(NSString*)cleanPCPath:(NSString*)srce
{
	NSRange searchRange;
	searchRange.location=0;
	searchRange.length=[srce length];
	NSRange index=[srce rangeOfString:@"\\" options:NSBackwardsSearch range:searchRange];
	if (index.location!=NSNotFound)
	{
		NSString* temp=[srce substringFromIndex:index.location+1];
		[srce release];
		return [[NSString alloc] initWithString:temp];
	}
	return srce;
}
// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch(num)
	{
	case 0:
		[self SetCurrentGroup:act];
		break;
	case 1:
		[self SetCurrentItem:act];
		break;
	case 2:
		[self SetValue:act];
		break;
	case 3:
		[self SavePosition:act];
		break;
	case 4:
		[self LoadPosition:act];
		break;        
	case 5:
		[self SetString:act];
		break;
	case 6:
		[self SetCurrentFile:act];
		break;
	case 7:
		[self SetValueItem:act];
		break;
	case 8:
		[self SetValueGroupItem:act];
		break;
	case 9:
		[self SetStringItem:act];
		break;
	case 10:
		[self SetStringGroupItem:act];
		break;
	case 11:
		[self DeleteItem:act];
		break;
	case 12:
		[self DeleteGroupItem:act];
		break;
	case 13:
		[self DeleteGroup:act];
		break;
	}	
}

-(void)SetCurrentGroup:(CActExtension*)act
{   
	[iniCurrentGroup release];
	iniCurrentGroup=[[NSString alloc] initWithString:[act getParamExpString:rh withNum: 0]];
}
-(void)SetCurrentItem:(CActExtension*)act
{       
	[iniCurrentItem release];
	iniCurrentItem=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
}
-(void)SetValue:(CActExtension*)act
{     
	int value=[act getParamExpression:rh withNum:0];
	NSString* s=[NSString stringWithFormat:@"%d", value];
	[ini writeValueToGroup:iniCurrentGroup withKey:iniCurrentItem andValue:s];
	saveCounter=50;
}
-(void)SavePosition:(CActExtension*)act
{        
	CObject* hoPtr = [act getParamObject:rh withNum:0];
	NSString* s=[NSString stringWithFormat:@"%d,%d", hoPtr->hoX, hoPtr->hoY];
	NSString* item=[NSString stringWithFormat:@"pos.%@", hoPtr->hoOiList->oilName];
	[ini writeValueToGroup:iniCurrentGroup withKey:item andValue:s];
	saveCounter=50;
}
-(void)LoadPosition:(CActExtension*)act
{        
	CObject* hoPtr = [act getParamObject:rh withNum:0];
	NSString* item=[NSString stringWithFormat:@"pos.%@", hoPtr->hoOiList->oilName];
	NSString* s=[ini getValueFromGroup:iniCurrentGroup withKey:item andDefaultValue:@"X"];
	if ([s compare:@"X"]!=0)
	{
		NSRange r=[s rangeOfString:@","];
		if (r.location!=NSNotFound)
		{
			NSUInteger virgule=r.location;
			NSString* left=[s substringToIndex:virgule];
			NSString* right=[s substringFromIndex:virgule+1];
			hoPtr->hoX=[left intValue];
			hoPtr->hoY=[right intValue];
			hoPtr->roc->rcChanged = YES;
			hoPtr->roc->rcCheckCollides = YES;
		}
	}
}
-(void)SetString:(CActExtension*)act
{        
	NSString* s=[act getParamExpString:rh withNum:0];
	[ini writeValueToGroup:iniCurrentGroup withKey:iniCurrentItem andValue:s];
	saveCounter=50;
}
-(void)SetCurrentFile:(CActExtension*)act
{
	[CIni closeIni:ini];
	[iniName release];
	iniName=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
	ini = [CIni getINIforFile:iniName];
}
-(void)SetValueItem:(CActExtension*)act
{        
	NSString* item=[act getParamExpString:rh withNum:0];
	int value=[act getParamExpression:rh withNum:1];
	NSString* s=[NSString stringWithFormat:@"%d", value];
	[ini writeValueToGroup:iniCurrentGroup withKey:item andValue:s];
	saveCounter=50;
}
-(void)SetValueGroupItem:(CActExtension*)act
{        
	NSString* group=[act getParamExpString:rh withNum:0];
	NSString* item=[act getParamExpString:rh withNum:1];
	int value=[act getParamExpression:rh withNum:2];
	NSString* s=[NSString stringWithFormat:@"%d", value];
	[ini writeValueToGroup:group withKey:item andValue:s];
	saveCounter=50;
}
-(void)SetStringItem:(CActExtension*)act
{
	NSString* item=[act getParamExpString:rh withNum:0];
	NSString* s=[act getParamExpString:rh withNum:1];
	[ini writeValueToGroup:iniCurrentGroup withKey:item andValue:s];
	saveCounter=50;
}
-(void)SetStringGroupItem:(CActExtension*)act
{        
	NSString* group=[act getParamExpString:rh withNum:0];
	NSString* item=[act getParamExpString:rh withNum:1];
	NSString* s=[act getParamExpString:rh withNum:2];
	[ini writeValueToGroup:group withKey:item andValue:s];
	saveCounter=50;
}
-(void)DeleteItem:(CActExtension*)act
{
	[ini deleteItemFromGroup:iniCurrentGroup withKey:[act getParamExpString:rh withNum:0]];
	saveCounter=50;
}
-(void)DeleteGroupItem:(CActExtension*)act
{
	[ini deleteItemFromGroup:[act getParamExpString:rh withNum:0] withKey:[act getParamExpString:rh withNum:1]];
	saveCounter=50;
}
-(void)DeleteGroup:(CActExtension*)act
{
	[ini deleteGroup:[act getParamExpString:rh withNum:0]];
	saveCounter=50;
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch(num)
	{
	case 0:
		return [self GetValue];
	case 1:
		return [self GetString];
	case 2:
		return [self GetValueItem];
	case 3:
		return [self GetValueGroupItem];
	case 4:
		return [self GetStringItem];
	case 5:
		return [self GetStringGroupItem];
	}
	return nil;
}

-(CValue*)GetValue
{
	NSString* s=[ini getValueFromGroup:iniCurrentGroup withKey:iniCurrentItem andDefaultValue:@"0"];
	return [rh getTempValue:[s intValue]];
}
-(CValue*)GetString
{
	NSString* s=[ini getValueFromGroup:iniCurrentGroup withKey:iniCurrentItem andDefaultValue:@""];
	return [rh getTempString:s];
}
-(CValue*)GetValueItem
{     
	NSString* item=[[ho getExpParam] getString];
	NSString* s=[ini getValueFromGroup:iniCurrentGroup withKey:item andDefaultValue:@"0"];
	return [rh getTempValue:[s intValue]];
}
-(CValue*)GetValueGroupItem
{     
	NSString* group=[[ho getExpParam] getString];
	NSString* item=[[ho getExpParam] getString];
	NSString* s=[ini getValueFromGroup:group withKey:item andDefaultValue:@"0"];
	return [rh getTempValue:[s intValue]];
}
-(CValue*)GetStringItem
{     
	NSString* item=[[ho getExpParam] getString];
	NSString* s=[ini getValueFromGroup:iniCurrentGroup withKey:item andDefaultValue:@""];
	return [rh getTempString:s];
}
-(CValue*)GetStringGroupItem
{     
	NSString* group=[[ho getExpParam] getString];
	NSString* item=[[ho getExpParam] getString];
	NSString* s=[ini getValueFromGroup:group withKey:item andDefaultValue:@""];
	return [rh getTempString:s];
}

@end

