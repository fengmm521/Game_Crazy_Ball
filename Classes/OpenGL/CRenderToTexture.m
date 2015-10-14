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
//  CRenderToTexture.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 8/10/10.
//  Copyright 2010 Clickteam. All rights reserved.
//

#import "CRenderToTexture.h"
#import "CRunApp.h"
#import "CServices.h"
#import "CRenderer.h"
#import "CRunView.h"

@implementation CRenderToTexture

- (id)initWithWidth:(int)w andHeight:(int)h andRunApp:(CRunApp*)runApp
{
	handle = -1;

	app = runApp;
	renderer = app->renderer;
	
	width = w;
	height = h;
	
	int nW = 16;
	int nH = 16;
	
	while(nW < w)
		nW *= 2;
	
	while(nH < h)
		nH *= 2;
	
	textureWidth = nW;
	textureHeight = nH;
	originalWidth = width;
	originalHeight = height;

	wrapS = wrapT = GL_CLAMP_TO_EDGE;

	textureId = [self newEmptyTextureWithWidth:textureWidth	andHeight:textureHeight];

	//Generate the render-to-texture framebuffer
	glGenFramebuffers(1, &framebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureId, 0);
	int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	if(status != GL_FRAMEBUFFER_COMPLETE)
		NSLog(@"Error: Could not create framebuffer!");

	glBindFramebuffer(GL_FRAMEBUFFER, renderer->currentRenderState.framebuffer);
	coordsAreSwapped = YES;
	[self updateTextureMatrix];
	return self;
}

- (void)dealloc
{
	glDeleteTextures(1, &textureId);
	glDeleteFramebuffers(1, &framebuffer);
	[super dealloc];
}

- (GLuint)newEmptyTextureWithWidth:(int)w andHeight:(int)h
{
	void* data = calloc(w*h, sizeof(char)*4);

	GLuint texId;
	glGenTextures(1, &texId);
	glBindTexture(GL_TEXTURE_2D, texId);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
	free(data);
	return texId;
}

- (void)bindFrameBuffer
{
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	renderer->pushRenderingState();
	renderer->currentRenderState.framebuffer = framebuffer;
	renderer->currentRenderState.framebufferSize = Vec2i(textureWidth, textureHeight);
	renderer->currentRenderState.contentSize = Vec2f(width, height);
	renderer->setProjectionMatrix(0, 0, width, height);
	renderer->forgetCachedState();
}

- (void)unbindFrameBuffer
{
	renderer->popRenderingState();
}

- (void)fillWithColor:(int)color
{
	GLint prevbuff = renderer->currentRenderState.framebuffer;
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glClearColor(getR(color)/255.0f, getG(color)/255.0f, getB(color)/255.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	glBindFramebuffer(GL_FRAMEBUFFER, prevbuff);
}

- (void)copyAlphaFrom:(CRenderToTexture*)rtt
{
	GLint prevbuff = renderer->currentRenderState.framebuffer;
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_TRUE);
	renderer->renderBlitFull(rtt);
	glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
	glBindFramebuffer(GL_FRAMEBUFFER, prevbuff);
}


- (void)clearColorChannelWithColor:(int)color
{
	GLint prevbuff = renderer->currentRenderState.framebuffer;
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	
	glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_FALSE);
	glClearColor(getR(color)/255.0f, getG(color)/255.0f, getB(color)/255.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
	
	glBindFramebuffer(GL_FRAMEBUFFER, prevbuff);
}







- (void)fillWithColor:(int)color andAlpha:(unsigned char)alpha
{
	GLint prevbuff = renderer->currentRenderState.framebuffer;
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glClearColor(getR(color)/255.0f, getG(color)/255.0f, getB(color)/255.0f, alpha/255.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	glBindFramebuffer(GL_FRAMEBUFFER, prevbuff);
}

//Clears the texture and sets the alpha to the specified value
-(void) clearWithAlpha:(float)alpha
{
	GLint prevbuff = renderer->currentRenderState.framebuffer;
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glClearColor(0,0,0,alpha);
	glClear(GL_COLOR_BUFFER_BIT);
	glBindFramebuffer(GL_FRAMEBUFFER, prevbuff);
}

//Clears the texture and sets the alpha to the specified value (doesn't bind the buffer first)
-(void) clearWithAlphaDontBind:(float)alpha
{
	glClearColor(0,0,0,alpha);
	glClear(GL_COLOR_BUFFER_BIT);
}

//Sets the contents of the alpha channel without modifying the contents of the texture
-(void) clearAlphaChannel:(float)alpha
{
	GLint prevbuff = renderer->currentRenderState.framebuffer;
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glColorMask(false, false, false, true);
	glClearColor(0,0,0,alpha);
	glClear(GL_COLOR_BUFFER_BIT);
	glColorMask(true, true, true, true);
	glBindFramebuffer(GL_FRAMEBUFFER, prevbuff);
} 

-(int)uploadTexture
{
	// No need to upload the texture as a rendertarget in itself is a graphics card only texture.
	isUploaded = YES;
	return 0;
}

-(int)deleteTexture
{
	// No deletion of the texture. Waits to the object is released.
	isUploaded = NO;
	return 0;
}

-(void)expectTilableImage
{
	//Render to texture's are not supported for tileable textures
}



//Mipmaps not supported by RenderToTextures as it could
//cause massive slowdowns for often updated textures
-(void)generateMipMaps
{
}

-(void)cleanMemory
{
	//No resources to clean (done in dealloc)
}

-(void)setResampling:(BOOL)_resample
{
	resample = _resample;
	[self updateFilter];
}

@end
