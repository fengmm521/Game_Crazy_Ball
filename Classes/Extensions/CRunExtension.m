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
// CRUNEXTENSION: Classe abstraite run extension
//
//----------------------------------------------------------------------------------
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
#import "CObjectCommon.h"

@implementation CRunExtension

-(void)initialize:(CExtension*)hoPtr
{
	ho = hoPtr;
	rh = hoPtr->hoAdRunHeader;
}

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	return false;
}

-(void)runtimeIsReady
{
	//Called when all objects are created at the start of the frame and event calling is safe. If frame is already started it is called immediately after createRunObject.
}

-(int)handleRunObject
{
	return REFLAG_ONESHOT;
}

-(void)displayRunObject:(CRenderer*)renderer
{
}

-(void)destroyRunObject:(BOOL)bFast
{
}

-(void)pauseRunObject
{
}

-(void)continueRunObject
{
}

-(void)getZoneInfos
{	
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	return false;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
}

-(CValue*)expression:(int)num
{
	return nil;
}

-(CMask*)getRunObjectCollisionMask:(int)flags
{
	return nil;
}

-(CImage*)getRunObjectSurface
{
	return nil;
}

-(CFontInfo*)getRunObjectFont
{
	return nil;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{	
}

-(int)getRunObjectTextColor
{
	return 0;
}

-(void)setRunObjectTextColor:(int)rgb
{
}

-(NSString*)description
{
	return [NSString stringWithString:ho->hoCommon->pCOI->oiName];
}

@end
