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
// CIMAGEBANK : Stockage des images
//
//----------------------------------------------------------------------------------
#import "CImageBank.h"
#import "CRunApp.h"
#import "CImage.h"
#import "CFile.h"
#import "CServices.h"
#import "CoreMath.h"
#import "CRenderer.h"

@implementation CImageBank

-(id)initWithApp:(CRunApp*)app
{
	runApp=app;
	return self;
}
-(void)dealloc
{
	if (images!=nil)
	{
		int n;
		for (n=0; n<nImages; n++)
		{
			if (images[n]!=nil)
			{
				[images[n] release];
			}
		}
		free(images);			
	}
	if (offsetsToImages!=nil)
	{
		free(offsetsToImages);
	}
	if (handleToIndex!=nil)
	{
		free(handleToIndex);
	}
	if (useCount!=nil)
	{
		free(useCount);
	}
	[super dealloc];
}
-(void)preLoad
{
	// Nombre de handles
	nHandlesReel=[runApp->file readAShort];
	offsetsToImages=(NSUInteger*)malloc(nHandlesReel*sizeof(NSUInteger));
	
	// Repere les positions des images
	int nImg=[runApp->file readAShort];
	NSUInteger offset;
	CImage* image=[[CImage alloc] init];
	for (int n=0; n<nImg; n++)
	{
		offset=[runApp->file getFilePointer];
		[image loadHandle:runApp->file];
		offsetsToImages[image->handle]=offset;
	}
	[image release];
	
	// Reservation des tables
	useCount=(short*)malloc(nHandlesReel*sizeof(short));
	[self resetToLoad];
	handleToIndex=nil;
	nHandlesTotal=nHandlesReel;
	nImages=0;
	images=nil;
}
-(CImage*)getImageFromHandle:(short)handle
{
	if (handle>=0 && handle<nHandlesTotal)
	    if (handleToIndex[handle]!=-1)
			return images[handleToIndex[handle]];
	return nil;
}
-(CImage*)getImageFromIndex:(short)index
{
	if (index>=0 && index<nImages)
	    return images[index];
	return nil;
}
-(void)cleanMemory
{
	int index;
	for (index=0; index<nImages; index++)
	{
		if (images[index]!=nil)
		{
			[images[index] cleanMemory];
		}
	}
}
-(void)resetToLoad
{
	int n;
	for (n=0; n<nHandlesReel; n++)
	{
	    useCount[n]=0;
	}
}
-(void)setToLoad:(short)handle
{
	if(offsetsToImages[handle] != 0)
		useCount[handle]++;
}
-(short)enumerate:(short)num
{
	[self setToLoad:num];
	return -1;
}
-(void)load
{
	int n;
	
	// Combien d'images?
	nImages=0;
	for (n=0; n<nHandlesReel; n++)
	{
	    if (useCount[n]!=0)
			nImages++;
	}
	
	// Charge les images
	int idd=0;
	CImage** newImages= NULL;
	if(nImages > 0)
		newImages = (CImage**)calloc(nImages, sizeof(CImage*));
	int count=0;
	int h;
	for (h=0; h<nHandlesReel; h++)
	{
		int objUseCount = useCount[h];
	    if (objUseCount!=0)
	    {
			if (images!=nil && handleToIndex[h]!=-1 && images[handleToIndex[h]]!=nil)
			{
				newImages[count]=images[handleToIndex[h]];
				newImages[count]->useCount=useCount[h];
			}
			else
			{
				CImage* newImage = [[CImage alloc] initWithApp:runApp];
				newImages[count]=newImage;
				[runApp->file seek:offsetsToImages[h]];
				[newImage preload:runApp->file];
				newImage->useCount=useCount[h];
				idd++;
			}
			count++;
	    }
		else
		{
			if (images!=nil && handleToIndex[h]>=0 && images[handleToIndex[h]]!=nil)
			{
				int index = handleToIndex[h];
				CImage* image = images[index];
				runApp->renderer->removeTexture(image, NO);
				[image release];
				images[index]=nil;
			}
		}			
	}
	if (images!=nil)
	{
		free(images);
	}		
	images=newImages;
	
	// Cree la table d'indirection
	if (handleToIndex!=nil)
	{
		free(handleToIndex);
	}
	handleToIndex=(short*)malloc(nHandlesReel*sizeof(short));
	for (n=0; n<nHandlesReel; n++)
	{
	    handleToIndex[n]=-1;
	}
	for (n=0; n<nImages; n++)
	{
	    handleToIndex[images[n]->handle]=(short)n;
	}
	nHandlesTotal=nHandlesReel;
	
	// Plus rien a charger
	[self resetToLoad];
}
-(void)delImage:(short)handle
{
	CImage* img=[self getImageFromHandle:handle];
	if (img!=nil)
	{
	    img->useCount--;
	    if (img->useCount<=0)
	    {
			int n;
			for (n=0; n<nImages; n++)
			{
				if (images[n]==img)
				{
					[images[n] release];
					images[n]=nil;
					handleToIndex[handle]=-1;
					break;
				}
			}
	    }
	}
}
-(short)addImageCompare:(CImage*)img withXSpot:(short)xSpot andYSpot:(short)ySpot andXAP:(short)xAP andYAP:(short)yAP
{
	int i;
	int width=img->width;
	int height=img->height;
	for (i=0; i<nImages; i++)
	{
	    if (images[i]->xSpot==xSpot && images[i]->ySpot==ySpot && images[i]->xAP==xAP && images[i]->yAP==yAP)
	    {
			if (width==images[i]->width && height==images[i]->height)
			{
				BOOL bEqual=YES;

				int n;
				unsigned int* pSrce=images[i]->data;
				unsigned int* pDest=img->data;
	    	    for (n=width*height; n>0; n--)
				{
					if (*(pSrce++)!=*(pDest++))
					{
						bEqual=NO;
						break;
					}
				}

				// Image trouvee
				if (bEqual)
				{
					images[i]->useCount++;
					return images[i]->handle;
				}
			}
	    }
	}
	return [self addImage:img withXSpot:xSpot andYSpot:ySpot andXAP:xAP andYAP:yAP andCount:(short)1];
}
-(short)addImage:(CImage*)img withXSpot:(short)xSpot andYSpot:(short)ySpot andXAP:(short)xAP andYAP:(short)yAP andCount:(short)count
{
	int h;
	
	// Cherche un handle libre
	short hFound=-1;
	for (h=nHandlesReel; h<nHandlesTotal; h++)
	{
	    if (handleToIndex[h]==-1)
	    {
			hFound=(short)h;
			break;
	    }		
	}
	
	// Rajouter un handle
	if (hFound==-1)
	{
	    short* newHToI=(short*)malloc((nHandlesTotal+10)*sizeof(short));
	    for (h=0; h<nHandlesTotal; h++)
	    {
			newHToI[h]=handleToIndex[h];
	    }
	    for (; h<nHandlesTotal+10; h++)
	    {
			newHToI[h]=-1;
	    }
	    hFound=(short)nHandlesTotal;
	    nHandlesTotal+=10;
		if (handleToIndex!=nil)
		{
			free(handleToIndex);
		}
	    handleToIndex=newHToI;
	}
	
	// Cherche une image libre
	int i;
	int iFound=-1;
	for (i=0; i<nImages; i++)
	{
	    if (images[i]==nil)
	    {
			iFound=i;
			break;
	    }
	}		
	
	// Rajouter une image?
	if (iFound==-1)
	{
	    CImage** newImages=(CImage**)malloc((nImages+10)*sizeof(CImage*));
	    for (i=0; i<nImages; i++)
	    {
			newImages[i]=images[i];
	    }
	    for (; i<nImages+10; i++)
	    {
			newImages[i]=nil;
	    }
	    iFound=nImages;
	    nImages+=10;
		if (images!=nil)
		{
			free(images);
		}
	    images=newImages;
	}
	
	// Ajoute la nouvelle image
	handleToIndex[hFound]=(short)iFound;
	images[iFound]=[[CImage alloc] initWithApp:runApp];
	[images[iFound] copyImage:img];
	images[iFound]->handle=hFound;
	images[iFound]->xSpot=xSpot;
	images[iFound]->ySpot=ySpot;
	images[iFound]->xAP=xAP;
	images[iFound]->yAP=yAP;
	images[iFound]->useCount=count;
	
	return hFound;
}
-(void)loadImageList:(short*)handles withLength:(int)length
{
	int h;
	
	int id=0;
	for (h=0; h<length; h++)
	{
		if (handles[h]>=0 && handles[h]<nHandlesTotal)
		{
			if (offsetsToImages[handles[h]]!=0)
			{
				if ([self getImageFromHandle:handles[h]]==nil)
				{	
					// Cherche une image libre
					int i;
					int iFound=-1;
					for (i=0; i<nImages; i++)
					{
						if (images[i]==nil)
						{
							iFound=i;
							break;
						}
					}		
					// Rajouter une image?
					if (iFound==-1)
					{
						CImage** newImages=(CImage**)malloc((nImages+10)*sizeof(CImage*));
						for (i=0; i<nImages; i++)
						{
							newImages[i]=images[i];
						}
						for (; i<nImages+10; i++)
						{
							newImages[i]=nil;
						}
						iFound=nImages;
						nImages+=10;
						if (images!=nil)
						{
							free(images);
						}
						images=newImages;
					}
					// Ajoute la nouvelle image
					handleToIndex[handles[h]]=(short)iFound;
					images[iFound]=[[CImage alloc] initWithApp:runApp];
					images[iFound]->useCount=1;
					[runApp->file seek:offsetsToImages[handles[h]]];
					[images[iFound] load:runApp->file];
					id++;
				}
				else
				{
					[self getImageFromHandle:handles[h]]->useCount++;
				}                  
			}
		}
	}
}
-(ImageInfo)getImageInfoEx:(short)nImage withAngle:(float)nAngle andScaleX:(float)fScaleX andScaleY:(float)fScaleY
{
	CImage* ptei;
	ImageInfo pIfo;
	
	ptei = [self getImageFromHandle:nImage];
	
	if ( ptei == nil )
	{
		pIfo.isFound = NO;
		pIfo.width = pIfo.height = pIfo.xSpot = pIfo.ySpot = pIfo.xAP = pIfo.yAP = 0;
		return pIfo;
	}
	
	int cx = ptei->width;
	int cy = ptei->height;
	int hsx = ptei->xSpot;
	int hsy = ptei->ySpot;
	int asx = ptei->xAP;
	int asy = ptei->yAP;
	
	// No rotation
	if ( nAngle == 0 )
	{
		// Stretch en X
		if ( fScaleX != 1.0f )
		{
			hsx = (int)(hsx * fScaleX);
			asx = (int)(asx * fScaleX);
			cx = (int)(cx * fScaleX);
		}
		
		// Stretch en Y
		if ( fScaleY != 1.0f )
		{
			hsy = (int)(hsy * fScaleY);
			asy = (int)(asy * fScaleY);
			cy = (int)(cy * fScaleY);
		}
	}
	
	// Rotation
	else
	{
		// Calculate dimensions
		if ( fScaleX != 1.0f )
		{
			hsx = (int)(hsx * fScaleX);
			asx = (int)(asx * fScaleX);
			cx = (int)(cx * fScaleX);
		}
		
		if ( fScaleY != 1.0f )
		{
			hsy = (int)(hsy * fScaleY);
			asy = (int)(asy * fScaleY);
			cy = (int)(cy * fScaleY);
		}
		
		// Rotate
		double alpha = (double)nAngle * _PI / 180;
		float cosa = cosf(alpha);
		float sina = sinf(alpha);
		
		int nx2, ny2;
		int	nx4, ny4;
		
		if ( sina >= 0.0f )
		{
			nx2 = (int)(cy * sina + 0.5f);		// (1.0f-sina));		// 1-sina est ici pour l'arrondi ??
			ny4 = -(int)(cx * sina + 0.5f);		// (1.0f-sina));
		}
		else
		{
			nx2 = (int)(cy * sina - 0.5f);		// (1.0f-sina));
			ny4 = -(int)(cx * sina - 0.5f);		// (1.0f-sina));
		}
		
		if ( cosa == 0.0f )
		{
			ny2 = 0;
			nx4 = 0;
		}
		else if ( cosa > 0 )
		{
			ny2 = (int)(cy * cosa + 0.5f);		// (1.0f-cosa));
			nx4 = (int)(cx * cosa + 0.5f);		// (1.0f-cosa));
		}
		else
		{
			ny2 = (int)(cy * cosa - 0.5f);		// (1.0f-cosa));
			nx4 = (int)(cx * cosa - 0.5f);		// (1.0f-cosa));
		}
		
		int nx3 = nx2 + nx4;
		int ny3 = ny2 + ny4;
		int nhsx = (int)(hsx * cosa + hsy * sina);
		int nhsy = (int)(hsy * cosa - hsx * sina);
		int nasx = (int)(asx * cosa + asy * sina);
		int nasy = (int)(asy * cosa - asx * sina);
		
		// Faire translation par rapport au hotspot
		int nx1 = 0;	// -nhsx;
		int ny1 = 0;	// -nhsy;
		
		// Calculer la nouvelle bounding box (� optimiser �ventuellement)
		int x1 = MIN(nx1, nx2);
		x1 = MIN(x1, nx3);
		x1 = MIN(x1, nx4);
		
		int x2 = MAX(nx1, nx2);
		x2 = MAX(x2, nx3);
		x2 = MAX(x2, nx4);
		
		int y1 = MIN(ny1, ny2);
		y1 = MIN(y1, ny3);
		y1 = MIN(y1, ny4);
		
		int y2 = MAX(ny1, ny2);
		y2 = MAX(y2, ny3);
		y2 = MAX(y2, ny4);
		
		cx = x2 - x1;
		cy = y2 - y1;
		
		hsx = -(x1 - nhsx);
		hsy = -(y1 - nhsy);
		
		asx = -(x1 - nasx);
		asy = -(y1 - nasy);
	}		
	
	pIfo.isFound = YES;
	pIfo.width = (short)cx;
	pIfo.height = (short)cy;
	pIfo.xSpot = (short)hsx;
	pIfo.ySpot = (short)hsy;
	pIfo.xAP = (short)asx;
	pIfo.yAP = (short)asy;
	
	return pIfo;
}

@end
