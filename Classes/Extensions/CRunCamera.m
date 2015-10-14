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
// CRunCamera
//
//----------------------------------------------------------------------------------
#import "CRunCamera.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CImageBank.h"
#import "CServices.h"
#import "CImage.h"
#import "MainViewController.h"
#import "CRenderer.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define CND_ISPRESENT 0
#define CND_LAST 1
#define ACT_TAKEPICTURE 0
#define ACT_TAKEMOVIE 1
#define ACT_SAVEPICTURE 2
#define FLAG_PICTURE 0x0001
#define FLAG_MOVIE 0x0002
#define CAMFLAG_EDITING 0x0001

@implementation CRunCamera

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    ho->hoImgWidth=[file readAInt];
    ho->hoImgHeight=[file readAInt];
    camFlags=[file readAInt];
    bAllowsEditing=NO;
	mainViewController = ho->hoAdRunHeader->rhApp->mainViewController;
    if ((camFlags&CAMFLAG_EDITING)!=0)
    {
        bAllowsEditing=YES;
    }
    return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
    if (imageToSave!=nil)
    {
        [imageToSave release];
    }
    if (image!=nil)
    {
        [image release];
    }
}
-(void)displayRunObject:(CRenderer *)renderer
{
    if (image!=nil)
    {
		renderer->renderImage(image,
							  ho->hoX,
							  ho->hoY,
							  ho->hoImgWidth,
							  ho->hoImgHeight,
							  0, 0);
    }
}
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    if (num==CND_ISPRESENT)
    {
        return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    }
    return NO;
}

-(void)takeIt:(int)flags
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        NSArray* array=[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];        
        int n;
        int flagsPresent=0;
        for (n=0; n<[array count]; n++)
        {
            NSString* type=[array objectAtIndex:n];
            if ([type caseInsensitiveCompare:(NSString*)kUTTypeImage]==0)
            {
                flagsPresent|=FLAG_PICTURE;
            }
            if ([type caseInsensitiveCompare:(NSString*)kUTTypeMovie]==0)
            {
                flagsPresent|=FLAG_MOVIE;
            }
        }
        flags&=flagsPresent;
        if (flags!=0)
        {        
            UIImagePickerController* cameraUI=[[UIImagePickerController alloc] init];
            cameraUI.sourceType=UIImagePickerControllerSourceTypeCamera;

            switch(flags)
            {
                case FLAG_PICTURE:
                    array=[[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage, nil];
                    break;
                case FLAG_MOVIE:
                    array=[[NSArray alloc] initWithObjects:(NSString*)kUTTypeMovie, nil];
                    break;
                case FLAG_PICTURE|FLAG_MOVIE:
                    array=[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];  
                    break;
            }
            cameraUI.mediaTypes=array;
            cameraUI.allowsEditing=bAllowsEditing;
            cameraUI.delegate=self;

            [ho pause];
            [mainViewController presentViewController:cameraUI animated:YES];
        }
    }
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [ho resume];
    picker.delegate=nil;
	[mainViewController dismissViewControllerAnimated:YES];
    [picker release];
}
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    NSString* mediaType=[info objectForKey:UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *save;
    
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0)==kCFCompareEqualTo)
    {
        editedImage=(UIImage*)[info objectForKey:UIImagePickerControllerEditedImage];
        originalImage=(UIImage*)[info objectForKey:UIImagePickerControllerOriginalImage];
        if (editedImage)
        {
            save=editedImage;
        }
        else
        {
            save=originalImage;
        }
        if (imageToSave!=nil)
        {
            [imageToSave release];
        }
        [save retain];
        imageToSave=save;
        if (image!=nil)
        {
            [image release];            
        }
        image=[CImage loadUIImage:save];
        [ho redraw];
    }
    
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeMovie, 0)==kCFCompareEqualTo)
    {
        NSString* moviePath=[[info objectForKey:UIImagePickerControllerMediaURL] path];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath))
        {
            UISaveVideoAtPathToSavedPhotosAlbum(moviePath, nil, nil, nil);
        }
    }
    [ho resume];
    picker.delegate=nil;
	[mainViewController dismissViewControllerAnimated:YES];
    [picker release];
}
-(void)saveIt
{
    if (imageToSave!=nil)
    {
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);               
        [imageToSave release];
        imageToSave=nil;
    }
}
-(void)action:(int)num withActExtension:(CActExtension *)act
{
    switch(num)
    {
        case ACT_TAKEPICTURE:
            [self takeIt:FLAG_PICTURE];
            break;
        case ACT_TAKEMOVIE:
            [self takeIt:FLAG_MOVIE];
            break;
        case ACT_SAVEPICTURE:
            [self saveIt];
            break;
    }
}

@end
