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
//  CRenderer.cpp
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 8/20/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//


#import "CRenderer.h"

#import "CRenderToTexture.h"
#import "CoreMath.h"
#import "CServices.h"
#import "CShader.h"
#import "CRunView.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CArrayList.h"
#import "CRunFrame.h"
#import "CBitmap.h"
#import "CLayer.h"

static CRenderer* ssRenderer;



CRenderer::CRenderer(CRunView* runView)
{
	currentShader = nil;
	defaultShader = nil;
	gradientShader = nil;
	currentLayer = nil;

	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	if (!context)
		return;
	if(![EAGLContext setCurrentContext:context])
		return;

	view = runView;
	windowSize = CGSizeMake(view->appRect.size.width, view->appRect.size.height);
	topLeft = CGPointMake(0, 0);
	texturesToRemove = [[CArrayList alloc] init];
	forgetCachedState();
	ssRenderer = this;

	// Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
	glGenFramebuffers(1, &defaultFramebuffer);
	glGenRenderbuffers(1, &colorRenderbuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);

	glEnable(GL_BLEND);
	usesBlending = YES;
	usesScissor = NO;

	usedTextures = [[NSMutableSet alloc] init];
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);

	currentRenderState.framebuffer = defaultFramebuffer;
	currentRenderState.viewport = Viewport(0, 0, view->appRect.size.width, view->appRect.size.height);
	currentRenderState.transform = Mat3f::identity();

	//Vertices:
	float vertices[8] = {
		0.0f,	0.0f,
		1.0f,	0.0f,
		0.0f,	1.0f,
		1.0f,	1.0f
	};
	glGenBuffers(1, &buffer);
	glBindBuffer(GL_ARRAY_BUFFER, buffer);
	glBufferData(GL_ARRAY_BUFFER, 2*4*sizeof(float), &vertices, GL_STATIC_DRAW);

	defaultShader = new CShader(this);
	gradientShader = new CShader(this);

	defaultShader->loadShader(@"default", true, false);
	gradientShader->loadShader(@"gradient", false, true);

	setCurrentShader(defaultShader);


	supportedExtensions = [[NSMutableSet alloc] init];
	NSString* extensionString = [NSString stringWithUTF8String:(char *)glGetString(GL_EXTENSIONS)];
	NSArray* extensions = [extensionString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	for(NSString* oneExtension in extensions)
	{
		if(![oneExtension isEqualToString:@""])
			[supportedExtensions addObject:oneExtension];
	}

	checkForError();
}

CRenderer* CRenderer::getRenderer()
{
	return ssRenderer;
}

CRenderer::~CRenderer()
{
	destroyFrameBuffers();
	delete defaultShader;
	delete gradientShader;
	[texturesToRemove release];

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;
}

void CRenderer::pushRenderingState()
{
	renderStateStack.push(currentRenderState);
}

void CRenderer::popRenderingState()
{
	currentRenderState = renderStateStack.pop();

	glBindFramebuffer(GL_FRAMEBUFFER, currentRenderState.framebuffer);
	setProjectionMatrix(topLeft.x, topLeft.y, currentRenderState.contentSize.x, currentRenderState.contentSize.y);
	forgetCachedState();
}

void CRenderer::destroyFrameBuffers()
{
    if (defaultFramebuffer)
    {
        glDeleteFramebuffers(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }
    if (colorRenderbuffer)
    {
        glDeleteRenderbuffers(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }
}

// Clear the frame, ready for rendering
void CRenderer::clear(float red, float green, float blue)
{
    glClearColor(red, green, blue, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
}

void CRenderer::clear()
{
	float r,g,b;
	int background;
	if(view->pRunApp->frame != nil)
		background = BGRtoARGB(view->pRunApp->frame->leBackground);
	else
		background = BGRtoARGB(view->pRunApp->gaBorderColour);

	r = ((background >> 16) & 0xFF)/255.0f;
	g = ((background >> 8) & 0xFF)/255.0f;
	b = (background & 0xFF)/255.0f;
	clear(r,g,b);
}

void CRenderer::clearWithRunApp(CRunApp* app)
{
	float r,g,b;
	int background;
	if(app->frame != nil)
		background = BGRtoARGB(app->frame->leBackground);
	else
		background = BGRtoARGB(app->gaBorderColour);

	r = ((background >> 16) & 0xFF)/255.0f;
	g = ((background >> 8) & 0xFF)/255.0f;
	b = (background & 0xFF)/255.0f;
	clear(r,g,b);
}

void CRenderer::swapBuffers()
{
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

void CRenderer::flush()
{
	glFlush();
}

void CRenderer::checkForError()
{
	GLenum err = glGetError();
	if (GL_NO_ERROR != err)
		NSLog(@"Got OpenGL Error: %i", err);
}

void CRenderer::forgetCachedState()
{
	currentTextureID = -1;
	currentBlendEquationA = currentBlendEquationB = currentBlendFunctionA = currentBlendFunctionB = -1;
	cR = cG = cB = cA = 1.0f;
	currentViewport = Viewport(0,0,0,0);

	CShader* shaderToBindAgain = currentShader;
	currentShader = NULL;
	setCurrentShader(shaderToBindAgain);

	if(defaultShader != NULL)
		defaultShader->forgetCachedState();
	if(gradientShader != NULL)
		gradientShader->forgetCachedState();
}

//Renders the given image with the previously defined shaders and settings.
void CRenderer::renderSimpleImage(int x, int y, int w, int h)
{
	currentShader->setObjectMatrix(Mat3f::objectMatrix(Vec2f(x,y), Vec2f(w,h), Vec2fZero));
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

//The most common image rendering method.
void CRenderer::renderImage(CTexture* image, int x, int y, int w, int h, int inkEffect, int inkEffectParam)
{
	uploadTexture(image);
	setInkEffect(inkEffect, inkEffectParam, nil);
	currentShader->setTexture(image);
	currentShader->setObjectMatrix(Mat3f::objectMatrix(Vec2f(x,y), Vec2f(w,h), Vec2fZero));
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

//The most common image rendering method.
void CRenderer::renderScaledRotatedImage(CTexture* image, float angle, float sX, float sY, int hX, int hY, int x, int y, int w, int h, int inkEffect, int inkEffectParam)
{
	uploadTexture(image);
	setInkEffect(inkEffect, inkEffectParam, nil);
	currentShader->setTexture(image);
	currentShader->setObjectMatrix(Mat3f::objectRotationMatrix(Vec2f(x,y), Vec2f(w,h), Vec2f(sX,sY), Vec2f(hX, hY), angle));
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

//Renders a tiled picture with clipping.
void CRenderer::renderPattern(CTexture* image, int x, int y, int w, int h, int inkEffect, int inkEffectParam, bool flipX, bool flipY, float scaleX, float scaleY)
{
	CRect visibleRect  = currentLayer->visibleRect;

	//Limit the amount of repetitions to what only is visible
	int startX = x;
	int startY = y;
	int endX = x+w;
	int endY = y+h;

	//Update shader information
	[image uploadTexture];
	currentShader->setTexture(image);
	setInkEffect(inkEffect, inkEffectParam, nil);

	int iw = image->width * scaleX;
	int ih = image->height * scaleY;
	int tw = image->textureWidth;
	int th = image->textureHeight;

	if(startX < -iw)
		startX %= iw;

	if(startY < -ih)
		startY %= ih;

	if(endX > visibleRect.right)
		endX = (endX-visibleRect.width()) % iw + visibleRect.right;

	if(endY > visibleRect.bottom)
		endY = (endY-visibleRect.height()) % ih + visibleRect.bottom;

	w = endX - startX;
	h = endY - startY;

	int wMiW = w % iw;
	int hMiH = h % ih;

	int lastX = endX - wMiW;
	int lastY = endY - hMiH;

	BOOL xDivisible = (wMiW == 0);
	BOOL yDivisible = (hMiH == 0);

	BOOL flipped = flipX || flipY;

	//Texture coordinate matrices
	Mat3f normalTexCoord = image->textureMatrix;

	Mat3f current = normalTexCoord;

	float rx, ry;
	for(int cY=startY; cY<endY; cY+=ih)
	{
		for(int cX=startX; cX<endX; cX+=iw)
		{
			int drawWidth = iw;
			int drawHeight = ih;

			current = normalTexCoord;

			if(cX==lastX && !xDivisible)
			{
				drawWidth = wMiW;
				rx = drawWidth/(float)(tw*scaleX);
				current.a = rx;
			}

			if(cY==lastY && !yDivisible)
			{
				drawHeight = hMiH;
				ry = drawHeight/(float)(th*scaleY);
				current.e = ry;
			}

			if(flipped)
				current = current.flippedTexCoord(flipX, flipY);

			currentShader->setTexCoord(current);
			currentShader->setObjectMatrix(Mat3f::objectMatrix(Vec2f(cX,cY), Vec2f(drawWidth,drawHeight), Vec2fZero));
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}
	}
}


//Renders a tiled picture with clipping.
void CRenderer::renderPattern(CTexture* image, int x, int y, int w, int h, int inkEffect, int inkEffectParam)
{
	//Use the fast rendering mode if the image is Power-Of-Two sized
	if([image imageIsPOT])
	{
		[image expectTilableImage];
		[image uploadTexture];
		setInkEffect(inkEffect, inkEffectParam, nil);
		Mat3f texMatrix = Mat3f::textureMatrix(0, 0, w, h, image->originalWidth, image->originalHeight);
		currentShader->setTexture(image, texMatrix);
		currentShader->setObjectMatrix(Mat3f::objectMatrix(Vec2f(x,y), Vec2f(w,h), Vec2fZero));
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	}
	else
	{
		//Use the slow but pixel perfect rendering option
		renderPattern(image, x, y, w, h, inkEffect, inkEffectParam, false, false);
	}
}

void CRenderer::renderSolidColor(int color, int x, int y, int w, int h, int inkEffect, int inkEffectParam)
{
	renderGradient(GradientColor(color), x, y, w, h, inkEffect, inkEffectParam);
}

void CRenderer::renderSolidColor(int color, CRect rect, int inkEffect, int inkEffectParam)
{
	renderGradient(GradientColor(color), (int)rect.left, (int)rect.top, (int)rect.width(), (int)rect.height(), inkEffect, inkEffectParam);
}

void CRenderer::setOrigin(int x, int y)
{
	originX = x;
	originY = y;
}

//Blit wrappers for the transition system
void CRenderer::renderBlitFull(CRenderToTexture* source)
{
	renderStretch(source, 0, 0, source->width, source->height, 0, 0, source->width, source->height);
}

void CRenderer::renderBlit(CRenderToTexture* source, int xDst, int yDst, int xSrc, int ySrc, int width, int height)
{
	renderStretch(source, xDst, yDst, width, height, xSrc, ySrc, width, height);
}

void CRenderer::renderFade(CRenderToTexture* source, int alpha)
{
	renderStretch(source, 0, 0, source->width, source->height, 0, 0, source->width, source->height, 1, alpha/2);
}

void CRenderer::renderStretch(CRenderToTexture* source, int xDst, int yDst, int wDst, int hDst, int xSrc, int ySrc, int wSrc, int hSrc, int inkEffect, int inkEffectParam)
{
	uploadTexture(source);

	if(currentRenderState.framebuffer == defaultFramebuffer)
	{
		xDst += originX;
		yDst += originY;
	}

	Mat3f texCoord = Mat3f::textureMatrixFlipped(xSrc, ySrc, wSrc, hSrc, source->height, source->textureWidth, source->textureHeight);
	Mat3f transform = Mat3f::objectMatrix(Vec2f(xDst, yDst), Vec2f(wDst, hDst), Vec2fZero);

	setInkEffect(inkEffect, inkEffectParam, nil);
	currentShader->setTexture(source, texCoord);
	currentShader->setObjectMatrix(transform);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void CRenderer::useBlending(BOOL useBlending)
{
	if(useBlending)
	{
		if(!usesBlending)
		{
			glEnable(GL_BLEND);
			usesBlending = YES;
		}
	}
	else
	{
		if(usesBlending)
		{
			glDisable(GL_BLEND);
			usesBlending = NO;
		}
	}
}

void CRenderer::uploadTexture(CTexture* texture)
{
	texture->usageCount++;

	if(texture->textureId != -1)
		return;

	textureUsage += [texture uploadTexture];

	//Add texture to set of used textures if it has a valid image-bank handle
	if(texture->handle != -1 && [usedTextures containsObject:texture] == NO)
		[usedTextures addObject:texture];
}



void CRenderer::removeTexture(CTexture* texture, BOOL cleanMemory)
{
	textureUsage -= [texture deleteTexture];
    if(cleanMemory)
        [texture cleanMemory];

	if([usedTextures containsObject:texture] == YES)
		[usedTextures removeObject:texture];
}

void CRenderer::updateViewport()
{
	setViewport(Viewport(0,0,backingWidth,backingHeight));
}

void CRenderer::setViewport(Viewport viewport)
{
	if(currentViewport != viewport)
	{
		glViewport(viewport.position.x, viewport.position.y, viewport.size.x, viewport.size.y);
	}
}

void CRenderer::setCurrentLayer(CLayer *layer)
{
	//Get the rhApp base values
	currentRenderState.transform = Mat3f::identity();

	if(layer != nil)
		currentRenderState.transform = [layer getTransformMatrix];

	currentLayer = layer;
	currentShader->setTransformMatrix(currentRenderState.transform);
}

void CRenderer::cleanMemory()
{
	NSEnumerator* enumerator = [usedTextures objectEnumerator];
	id value;
	while ((value = [enumerator nextObject]))
	{
		CTexture* texture = value;
		textureUsage -= [texture deleteTexture];
		texture->usageCount = 0;
	}
	[usedTextures removeAllObjects];
}


//Generates a list of all unused textures over a timespan of 10 seconds
//The renderer will release these textures spread out over the next 10 seconds for minimal speed impact
void CRenderer::cleanUnused()
{
	//NSLog(@"Texture usage: %f MB", (textureUsage/1024.0f)/1024.0f);

	//Clean prune list just to be sure no textures are added twice:
	[texturesToRemove clear];

	NSEnumerator* enumerator = [usedTextures objectEnumerator];
	id value;
	while ((value = [enumerator nextObject]))
	{
		CTexture* texture = value;
		if(texture->usageCount == 0)
			[texturesToRemove add:(void*)texture];
		texture->usageCount = 0;
	}
	//NSLog(@"Generated clean list of %i entries", [texturesToRemove size]);
}

//Remove one unused texture at a time.
void CRenderer::pruneTexture()
{
	int index = [texturesToRemove size]-1;
	if(index >= 0)
	{
		CTexture* texture = (CTexture*)[texturesToRemove get:index];
		//Recheck that the texture wasn't used
		if(texture->usageCount == 0)
			removeTexture(texture, true);

		[texturesToRemove removeIndex:index];
		//NSLog(@"Pruned texture %@", texture);
	}
}

void CRenderer::clearPruneList()
{
	[texturesToRemove clear];
}

void CRenderer::setClip(int x, int y, int w, int h)
{
	int currentWidth = currentRenderState.framebufferSize.x;
	int currentHeight = currentRenderState.framebufferSize.y;

	w = MIN(currentWidth,w);
	h = MIN(currentHeight,h);
	x = MAX(0,x);
	y = MAX(0,y);

	if(!usesScissor)
	{
		glEnable(GL_SCISSOR_TEST);
		usesScissor = YES;
	}
	glScissor(x, backingHeight-y-h, w, h);
}

void CRenderer::resetClip()
{
	if(usesScissor)
	{
		glDisable(GL_SCISSOR_TEST);
		usesScissor = NO;
	}
}

void CRenderer::setBlendEquation(GLenum equation)
{
	if(currentBlendEquationA != equation)
	{
		currentBlendEquationA = equation;
		glBlendEquation(equation);
	}
}

void CRenderer::setBlendEquationSeperate(GLenum equationA, GLenum equationB)
{
	if(currentBlendEquationA != equationA || equationB != currentBlendEquationB)
	{
		currentBlendEquationA = equationA;
		currentBlendEquationB = equationB;
		glBlendEquationSeparate(equationA, equationB);
	}
}

void CRenderer::setBlendFunction(GLenum sFactor, GLenum dFactor)
{
	if(currentBlendFunctionA != sFactor || currentBlendFunctionB != dFactor)
	{
		currentBlendFunctionA = sFactor;
		currentBlendFunctionB = dFactor;
		glBlendFunc(sFactor, dFactor);
	}
}

void CRenderer::setBlendColor(float red, float green, float blue, float alpha)
{
	if(cA != alpha || cR != red || cG != green || cB != blue)
	{
		cR = red;
		cG = green;
		cB = blue;
		cA = alpha;
	}
}

void CRenderer::bindRenderBuffer()
{
	[EAGLContext setCurrentContext:context];
	glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
}

void CRenderer::setCurrentShader(CShader* shader)
{
	if(shader == currentShader)
		return;

	currentShader = shader;
	currentShader->bindShader();
	currentShader->setProjectionMatrix(currentRenderState.projection);
	currentShader->setTransformMatrix(currentRenderState.transform);
}

void CRenderer::setInkEffect(int effect, int effectParam, CShader* shader)
{
	bool useBasic = YES;
	CShader* useShader = defaultShader;
	unsigned int rgbaCoeff;
	float red = 1.0f, green = 1.0f, blue = 1.0f, alpha = 1.0f;

	//Ignores shader effects
	if((effect & BOP_MASK)==BOP_EFFECTEX)
	{
		effect = BOP_BLEND;
		rgbaCoeff = effectParam;
		alpha = (rgbaCoeff >> 24)/255.0f;
	}
	//Extracts the RGB Coefficient
	else if((effect & BOP_RGBAFILTER) != 0)
	{
		effect = MAX(effect & BOP_MASK, BOP_BLEND);
		useBasic = NO;

		rgbaCoeff = effectParam;
		red = ((rgbaCoeff>>16) & 0xFF) / 255.0f;
		green = ((rgbaCoeff>>8) & 0xFF) / 255.0f;
		blue = (rgbaCoeff & 0xFF) / 255.0f;
		alpha = (rgbaCoeff >> 24)/255.0f;
	}
	//Uses the generic INK-effect
	else
	{
		effect &= BOP_MASK;
		if(effectParam == -1)
			alpha = 1.0f;
			else
				alpha = 1.0f - effectParam/128.0f;
	}

	// Use shader program
	if(shader != nil)
	{
		useShader = shader;
		effect = MAX(effect & BOP_MASK, BOP_BLEND);
	}

	setCurrentShader(useShader);
	currentShader->setInkEffect(effect);
	currentShader->setRGBCoeff(red, green, blue, alpha);
}

void CRenderer::setProjectionMatrix(int x, int y, int width, int height)
{
	currentRenderState.projection = Mat3f::orthogonalProjectionMatrix(x, y, width, height);
	currentShader->setProjectionMatrix(currentRenderState.projection);
	setViewport(Viewport(x, y, width, height));
}

void CRenderer::renderLine(Vec2f pA, Vec2f pB, int color, float thickness)
{
	float angle = atan2(pB.y-pA.y, pB.x-pA.x);
	float length = pA.distanceTo(pB);
	Mat3f lineMatrix = Mat3f::objectRotationMatrix(pA, Vec2f(length, thickness), Vec2fOne, Vec2f(0, thickness/2), -radiansToDegrees(angle));

	//Update shader information
	setInkEffect(0, 0, gradientShader);
	currentShader->setGradientColors(color);
	currentShader->setObjectMatrix(lineMatrix);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void CRenderer::renderGradient(GradientColor gradient, int x, int y, int w, int h, int inkEffect, int inkEffectParam)
{
	float alpha;
	unsigned int rgbaCoeff = inkEffectParam;
	if((inkEffect & BOP_MASK)==BOP_EFFECTEX || (inkEffect & BOP_RGBAFILTER) != 0)
	{
		alpha = (rgbaCoeff >> 24)/255.0f;
	}
	else
	{
		if(inkEffectParam == -1)
			alpha = 1.0f;
		else
			alpha = 1.0f - inkEffectParam/128.0f;
	}
	gradient.a.a = alpha;
	gradient.b.a = alpha;
	gradient.c.a = alpha;
	gradient.d.a = alpha;

	//Update shader information
	setInkEffect(0, 0, gradientShader);
	currentShader->setGradientColors(gradient);
	currentShader->setObjectMatrix(Mat3f::objectMatrix(Vec2f(x,y), Vec2f(w,h), Vec2fZero));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void CRenderer::renderGradient(GradientColor gradient, CRect rect, int inkEffect, int inkEffectParam)
{
	renderGradient(gradient, (int)rect.left, (int)rect.top, (int)rect.width(), (int)rect.height(), inkEffect, inkEffectParam);
}

bool CRenderer::resizeFromLayer(CAEAGLLayer* layer)
{
	layer.bounds = CGRectMake(layer.bounds.origin.x, layer.bounds.origin.y, windowSize.width, windowSize.height);

	// Allocate color buffer backing based on the current layer size
	[EAGLContext setCurrentContext:context];
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);

	currentRenderState.framebufferSize = Vec2i(backingWidth, backingHeight);
	currentRenderState.contentSize = Vec2f(backingWidth, backingHeight);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }


	forgetCachedState();

	//Set the projection matrix of the shaders
	gradientShader->bindShader();
	setProjectionMatrix(topLeft.x, topLeft.y, currentRenderState.contentSize.x, currentRenderState.contentSize.y);
	defaultShader->bindShader();
	setProjectionMatrix(topLeft.x, topLeft.y, currentRenderState.contentSize.x, currentRenderState.contentSize.y);

    return YES;
}





Viewport::Viewport()
{
	this->position = Vec2iZero;
	this->size = Vec2iZero;
}

Viewport::Viewport(Vec2i position, Vec2i size)
{
	this->position = position;
	this->size = size;
}

Viewport::Viewport(int x, int y, int width, int height)
{
	this->position = Vec2i(x,y);
	this->size = Vec2i(width, height);
}

float Viewport::aspect()
{
	return size.x/(float)size.y;
}

bool Viewport::operator==(const Viewport &rhs) const{return this->position == rhs.position && this->size == rhs.size;}
bool Viewport::operator!=(const Viewport &rhs) const{return !(*this == rhs);}