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
//  CRunkcpica.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 9/13/11.
//  Copyright (c) 2011 Clickteam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;
@class CImage;
@class MainViewController;
@class CRenderToTexture;

#ifdef __IPHONE_5_0
@interface CRunkcpica : CRunExtension <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, NSURLConnectionDataDelegate>
#else
@interface CRunkcpica : CRunExtension <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>
#endif

{
	NSString* szImageName;
	int dwImageFlags;
	int dwPictureWidth;
	int dwPictureHeight;
	int dwScreenWidth;
	int dwScreenHeight;
	int dwEditorWidth;
	int dwEditorHeight;
	int iHotSpotX;
	int iHotSpotY;
	int oldHotSpotX;
	int oldHotSpotY;
	
	float iAngle;
	int nOffsetX;
	int nOffsetY;
	BOOL highQuality;

	CImage* aImage;
	BOOL flippedH;
	BOOL flippedV;

	MainViewController* mainViewController;
	NSURLConnection* uConnection;
	NSMutableData* uData;
	
	UIImagePickerController* imageSelector;
 	UIPopoverController* popOverController;

	CRenderToTexture* renderToTexture;
}

-(void)act_LoadPicture:(NSString*)filename;
-(void)act_LoadPictureFromSelector;
-(void)act_SetHotSpot:(int)x andY:(int)y;
-(void)act_SetSizePixels:(int)width andHeight:(int)height;
-(void)act_SetAngle:(float)angle;
-(void)act_SetHotSpot_TopLeft;
-(void)act_SetHotSpot_TopCenter;
-(void)act_SetHotSpot_TopRight;
-(void)act_SetHotSpot_CenterLeft;
-(void)act_SetHotSpot_Center;
-(void)act_SetHotSpot_CenterRight;
-(void)act_SetHotSpot_BottomLeft;
-(void)act_SetHotSpot_BottomCenter;
-(void)act_SetHotSpot_BottomRight;
-(void)act_FlipH;
-(void)act_FlipV;
-(void)act_LinkDir;
-(void)act_UnlinkDir;
-(void)act_LookAt:(int)x andY:(int)y;
-(void)act_SetOffsetX:(int)offsetX;
-(void)act_SetOffsetY:(int)offsetY;
-(void)act_SetResizeFast;
-(void)act_SetResizeResample;
-(void)act_SetWrapMode_On;
-(void)act_SetWrapMode_Off;
-(void)act_AddBackdrop:(int)dX destY:(int)dY sourceX:(int)sX sourceY:(int)sY width:(int)width height:(int)height obstacle:(short)obstacle;
-(void)act_AutoResizeOn;
-(void)act_AutoResizeOff;
-(void)act_ZoomPercent:(int)percent;
-(void)act_ZoomWidth:(int)width;
-(void)act_ZoomHeight:(int)height;
-(void)act_ZoomRect:(int)width height:(int)height zoomMode:(int)evenIfSmaller;

-(UIImage*)loadImageFromString:(NSString*)filename;
-(void)loadUIImage:(UIImage*)imageToLoad;

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(void)displayRunObject:(CRenderer *)renderer;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd;
-(void)action:(int)num withActExtension:(CActExtension *)act;
-(CValue*)expression:(int)num;

@end
