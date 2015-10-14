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
//  CRuniPhoneStore.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 1/25/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CExtStorage.h"

#import <StoreKit/StoreKit.h>

@class CCreateObjectInfo;
@class CActExtension;
@class CCndExtension;
@class CFile;
@class CValue;
@class CArrayList;
@class CFontInfo;
@class CListItem;
@class CRuniOSStore;

@interface GlobalStore : CExtStorage <SKProductsRequestDelegate, SKRequestDelegate, SKPaymentTransactionObserver>
{
@public
	NSMutableArray* currentRequests;			//SKProductsRequest
	NSMutableArray* storeListeners;				//CRuniOSStore
	NSMutableArray* invalidProductIdentifiers;	//NSString
	NSMutableArray* requestResponses;			//SKProduct
	NSMutableArray* transactionsReceived;		//SKPaymentTransaction
}
-(void)listenForStoreEvents;
-(void)addStoreListener:(CRuniOSStore*)store;
-(void)removeStoreListener:(CRuniOSStore*)store;
-(void)startProductRequest:(SKProductsRequest*)request;
-(void)sendEvents;
@end

@interface CRuniOSStore : CRunExtension
{
@public

	NSString* productIdentifier;
	NSString* productName;
	NSString* productDescription;
	NSString* localizedPrice;
	NSString* storeReceipt;
	NSString* lastErrorString;
	NSMutableArray* productsToRequest;
	NSNumberFormatter* formatter;
	NSMutableDictionary* validProducts;
	double productPrice;
	NSInteger productQuantity;
	NSInteger lastErrorNumber;
	GlobalStore* globalStore;
}
-(void)runtimeIsReady;
-(int)handleRunObject;
-(void)receivedResponse:(NSMutableArray*)products andInvalidIdentifiers:(NSMutableArray*)invalidIdentifiers;
-(void)updatedTransactions:(NSMutableArray*)transactions;
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(void)act_RequestPaymentSlot:(NSString*)slot andQuantity:(int)quantity;
-(void)act_RestoreTransactions;
@end
