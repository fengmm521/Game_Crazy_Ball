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
//  CRuniPhoneStore.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 1/25/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "CRuniOSStore.h"

#import "CActExtension.h"
#import "CCndExtension.h"

#import "CExtension.h"
#import "CPoint.h"
#import "CCreateObjectInfo.h"
#import "CFile.h"

#import "CRunApp.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CServices.h"
#import "NSExtensions.h"
#import "Reachability.h"


#define	CND_CANPAYMENTSBEMADE		0
#define CND_ONREQUESTRESPONSE		1
#define CND_ONPAYMENTPURCHASED		2
#define CND_ONPAYMENTFAILED			3
#define CND_ONPAYMENTCANCELED		4
#define CND_ONPAYMENTRESTORED		5

#define CND_ONANYREQUESTRESPONSE	6
#define CND_ONANYPAYMENTPURCHASED	7
#define CND_ONANYPAYMENTFAILED		8
#define CND_ONANYPAYMENTCANCELED	9
#define CND_ONANYPAYMENTRESTORED	10

#define CND_ONINVALIDIDENTIFIER		11
#define CND_ONANYINVALIDIDENTIFIER	12
#define CND_RESTOREPAYMENTSFINISHED	13
#define CND_RESTOREPAYMENTSFAILED	14
#define CND_LAST                    15

#define	ACT_REQUESTPRODUCTSLOT		0
#define ACT_REQUESTPAYMENTSLOT		1
#define ACT_RESTORETRANSACTIONS		2

#define	EXP_PRODUCTNAME				0
#define EXP_PRODUCTDESCRIPTION		1
#define EXP_PRODUCTPRICE			2
#define EXP_PRODUCTPRICELOCALE		3
#define EXP_PRODUCTIDENTIFIER		4
#define EXP_STORERECEIPT			5
#define EXP_PRODUCTQUANTITY			6
#define EXP_ERRORSTRING				7
#define EXP_ERRORNUMBER				8


@implementation GlobalStore

-(id)init
{
	if(self = [super init])
	{
		currentRequests = [[NSMutableArray alloc] init];
		storeListeners = [[NSMutableArray alloc] init];
		invalidProductIdentifiers = [[NSMutableArray alloc] init];	//NSString
		requestResponses = [[NSMutableArray alloc] init];			//SKProduct
		transactionsReceived = [[NSMutableArray alloc] init];		//SKPaymentTransaction
	}
	return self;
}

-(void)listenForStoreEvents
{
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(void)addStoreListener:(CRuniOSStore*)store
{
	[storeListeners addObject:store];
	[self sendEvents];
}

-(void)removeStoreListener:(CRuniOSStore*)store
{
	[storeListeners removeObject:store];
}

-(void)dealloc
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];

	//Cancel any ongoing requests
	for(int i=0; i<[currentRequests count]; ++i)
	{
		SKProductsRequest* request = (SKProductsRequest*)[currentRequests objectAtIndex:i];
		[request cancel];
		request.delegate = nil;
	}
	[currentRequests release];
	[storeListeners release];
	[invalidProductIdentifiers release];
	[requestResponses release];
	[transactionsReceived release];
	[super dealloc];
}

-(void)startProductRequest:(SKProductsRequest *)request
{
	request.delegate = self;
	[currentRequests addObject:request];
	[request start];
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSLog(@"Products Request Did Receive Response");
	[invalidProductIdentifiers addObjectsFromArray:response.invalidProductIdentifiers];
	[requestResponses addObjectsFromArray:response.products];
	[currentRequests removeObject:request];
	[self sendEvents];
}

-(void)sendEvents
{
	if(storeListeners.count > 0)
	{
		CRuniOSStore* storeObject = [storeListeners objectAtIndex:0];
		if(requestResponses.count > 0 || invalidProductIdentifiers > 0)
		{
			[storeObject receivedResponse:requestResponses andInvalidIdentifiers:invalidProductIdentifiers];

			[requestResponses removeAllObjects];
			[invalidProductIdentifiers removeAllObjects];
		}

		if(transactionsReceived.count > 0)
		{
			[storeObject updatedTransactions:transactionsReceived];
			[transactionsReceived removeAllObjects];
		}
	}
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	NSLog(@"Payment Queue Updated Transactions");
	[transactionsReceived addObjectsFromArray:transactions];
	[self sendEvents];
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	NSLog(@"Payment Queue Restore Completed Transactions Finished");
	if(storeListeners.count > 0)
	{
		CRuniOSStore* storeObject = [storeListeners objectAtIndex:0];
		[storeObject->ho resume];
		[storeObject->ho generateEvent:CND_RESTOREPAYMENTSFINISHED withParam:0];
	}
}
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	NSLog(@"Restore completed transactions failed with error: %@", [error localizedDescription]);
	if(storeListeners.count > 0)
	{
		CRuniOSStore* storeObject = [storeListeners objectAtIndex:0];
		[storeObject->lastErrorString release];
		storeObject->lastErrorString = [[NSString alloc] initWithString:error.description];
		storeObject->lastErrorNumber = error.code;

		[storeObject->ho resume];
		[storeObject->ho generateEvent:CND_RESTOREPAYMENTSFAILED withParam:0];
	}
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
	NSLog(@"Removed transactoins from queue");
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	NSLog(@"Store failed with error: %@", [error localizedDescription]);
	if(storeListeners.count > 0)
	{
		CRuniOSStore* storeObject = [storeListeners objectAtIndex:0];

		[storeObject->lastErrorString release];
		storeObject->lastErrorString = [[NSString alloc] initWithString:error.description];
		storeObject->lastErrorNumber = error.code;

		[storeObject->ho resume];
		[storeObject->ho generateEvent:CND_ONANYPAYMENTFAILED withParam:0];
	}
}

@end



@implementation CRuniOSStore

-(void)receivedResponse:(NSMutableArray*)products andInvalidIdentifiers:(NSMutableArray*)invalidIdentifiers
{
	for(NSString* invId in invalidIdentifiers)
	{
		if(invId != nil)
		{
			[productIdentifier release];
			productIdentifier = [[NSString alloc] initWithString:invId];
			NSLog(@"Invalid product itentifier: %@", productIdentifier);
			[ho resume];
			[ho generateEvent:CND_ONINVALIDIDENTIFIER withParam:0];
			[ho generateEvent:CND_ONANYINVALIDIDENTIFIER withParam:0];
		}
		else
			NSLog(@"Invalid product itentifier (returned nil) - Unknown error.");
	}

	for(SKProduct* product in products)
	{
		[productIdentifier release];
		[productName release];
		[productDescription release];
		[localizedPrice release];

		if(product.productIdentifier != nil)
			[validProducts setObject:product forKey:product.productIdentifier];
		else
			NSLog(@"Invalid product identifier returned for valid product! Please check your items in iTunes Connect!");

		productName = [[NSString alloc] initWithString:((product.localizedTitle != nil) ? product.localizedTitle : @"")];
		productDescription = [[NSString alloc] initWithString:((product.localizedDescription != nil) ? product.localizedDescription : @"")];
		productPrice = [product.price doubleValue];
        productIdentifier=[[NSString alloc] initWithString:((product.productIdentifier != nil) ? product.productIdentifier : @"")];
		[formatter setLocale:product.priceLocale];
		localizedPrice = [[formatter stringFromNumber:product.price] retain];

		[ho resume];
		[ho generateEvent:CND_ONREQUESTRESPONSE withParam:0];
		[ho generateEvent:CND_ONANYREQUESTRESPONSE withParam:0];
	}
}

-(void)updatedTransactions:(NSMutableArray *)transactions
{
	for(SKPaymentTransaction* transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
			{
				[productIdentifier release];
				productIdentifier = [[NSString alloc] initWithString:transaction.payment.productIdentifier];
				productQuantity = transaction.payment.quantity;
				[storeReceipt release];
				storeReceipt = [transaction.transactionReceipt base64encode];
				[ho resume];
				[ho generateEvent:CND_ONPAYMENTPURCHASED withParam:0];
				[ho generateEvent:CND_ONANYPAYMENTPURCHASED withParam:0];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			}

			case SKPaymentTransactionStateFailed:
			{
				if(transaction.payment != nil)
				{
					[productIdentifier release];
					if(transaction.payment.productIdentifier != nil)
						productIdentifier = [[NSString alloc] initWithString:transaction.payment.productIdentifier];
					else
						productIdentifier = @"Invalid product identifier";
					productQuantity = transaction.payment.quantity;
				}
				else
				{
					[productIdentifier release];
					productIdentifier = @"";
					productQuantity = 0;
				}

				[ho resume];
				if(transaction.error != nil)
				{
					[lastErrorString release];
					if(transaction.error.description != nil)
						lastErrorString = [[NSString alloc] initWithString:transaction.error.description];
					else
						lastErrorString = @"Unknown store error";

					lastErrorNumber = transaction.error.code;

					if(transaction.error.code == SKErrorPaymentCancelled)
					{
						[ho generateEvent:CND_ONPAYMENTCANCELED withParam:0];
						[ho generateEvent:CND_ONANYPAYMENTCANCELED withParam:0];
					}
					else
					{
						[ho generateEvent:CND_ONPAYMENTFAILED withParam:0];
						[ho generateEvent:CND_ONANYPAYMENTFAILED withParam:0];
					}
				}
				else
				{
					[lastErrorString release];
					lastErrorString = @"";
					lastErrorNumber = 0;

					//No error but the transaction still failed
					[ho generateEvent:CND_ONPAYMENTFAILED withParam:0];
					[ho generateEvent:CND_ONANYPAYMENTFAILED withParam:0];
				}
				NSLog(@"Failed transaction: %@", transaction);

				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			}

			case SKPaymentTransactionStateRestored:
			{
				[productIdentifier release];
				productIdentifier = [[NSString alloc] initWithString:transaction.payment.productIdentifier];
				productQuantity = transaction.payment.quantity;

				NSLog(@"Restored purchase for identifier: %@", transaction.transactionIdentifier);

				[ho resume];
				[ho generateEvent:CND_ONPAYMENTRESTORED withParam:0];
				[ho generateEvent:CND_ONANYPAYMENTRESTORED withParam:0];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];

				break;
			}

			case SKPaymentTransactionStatePurchasing:
			{
				NSLog(@"Purchasing identifier: %@", transaction.transactionIdentifier);
				break;
			}
		}
	}

}

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	productIdentifier = [[NSString alloc] initWithString:@""];
	productName = [[NSString alloc] initWithString:@""];
	productDescription = [[NSString alloc] initWithString:@""];
	localizedPrice = [[NSString alloc] initWithString:@""];
	storeReceipt = [[NSString alloc] initWithString:@""];
	lastErrorString = [[NSString alloc] initWithString:@""];
	lastErrorNumber = -1;
	productPrice = 0;
	validProducts = [[NSMutableDictionary alloc] init];

	globalStore = nil;

	productsToRequest = [[NSMutableArray alloc] init];

	formatter = [[NSNumberFormatter alloc] init];
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	
	return YES;
}

-(void)runtimeIsReady
{
	CExtStorage* pExtData = [rh getStorage:ho->hoIdentifier];
	if(pExtData != nil)
		globalStore = (GlobalStore*)pExtData;
	else
		globalStore = [[GlobalStore alloc] init];

	[globalStore addStoreListener:self];
	[globalStore listenForStoreEvents];
}


-(void)destroyRunObject:(BOOL)bFast
{
	if(productIdentifier != nil)
		[productIdentifier release];
	if(productName != nil)
		[productName release];
	if(productDescription != nil)
		[productDescription release];
	if(localizedPrice != nil)
		[localizedPrice release];
	if(storeReceipt != nil)
		[storeReceipt release];
	if(lastErrorString != nil)
		[lastErrorString release];

	if(globalStore != nil)
		[globalStore removeStoreListener:self];

	[formatter release];
	[validProducts release];
	[productsToRequest release];
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_CANPAYMENTSBEMADE:
			return [SKPaymentQueue canMakePayments];
		case CND_ONREQUESTRESPONSE:
		case CND_ONPAYMENTPURCHASED:
		case CND_ONPAYMENTFAILED:
		case CND_ONPAYMENTCANCELED:
		case CND_ONPAYMENTRESTORED:
		case CND_ONINVALIDIDENTIFIER:
			return [productIdentifier isEqualToString:[cnd getParamExpString:rh withNum:0]];
		case CND_ONANYREQUESTRESPONSE:
		case CND_ONANYPAYMENTPURCHASED:
		case CND_ONANYPAYMENTFAILED:
		case CND_ONANYPAYMENTCANCELED:
		case CND_ONANYPAYMENTRESTORED:
		case CND_ONANYINVALIDIDENTIFIER:
        case CND_RESTOREPAYMENTSFINISHED:
        case CND_RESTOREPAYMENTSFAILED:
			return YES;
	}
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_REQUESTPRODUCTSLOT:
			[productsToRequest addObject:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_REQUESTPAYMENTSLOT:
		{
			NSString* identifier = [act getParamExpString:rh withNum:0];
			int q = [act getParamExpression:rh withNum:1];
			[self act_RequestPaymentSlot:identifier andQuantity:q];
			break;
		}
        case ACT_RESTORETRANSACTIONS:
            [self act_RestoreTransactions];            
            break;
    }
}

-(int)handleRunObject
{
	if(productsToRequest.count > 0)
	{
		Reachability* networkReachability = [Reachability reachabilityForInternetConnection];
		NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
		if(networkStatus == NotReachable)
		{
			NSLog(@"Internet connection not available for requesting In-App item information. Retrying...");
			return 0;
		}

		NSLog(@"Requesting product information for: %@", [productsToRequest componentsJoinedByString:@", "]);

		//Request product information
		SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productsToRequest]];
		[globalStore startProductRequest:request];

		[productsToRequest removeAllObjects];
	}
	return 0;
}

-(void)act_RequestPaymentSlot:(NSString*)slot andQuantity:(int)quantity
{
	Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	if (networkStatus == NotReachable)
	{
		NSLog(@"Internet connection not available for requesting an In-App purchase.");
		return;
	}

	SKProduct* product = [validProducts objectForKey:slot];
	if(product == nil)
	{
		NSLog(@"You need to request product information before requesting a payment!");
		return;
	}
	
	SKMutablePayment* payment = [SKMutablePayment paymentWithProduct:product];
	payment.quantity = quantity;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(void)act_RestoreTransactions
{
	Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	if (networkStatus == NotReachable)
	{
		NSLog(@"Internet connection not available for restoring In-App purchases.");
		return;
	}
	
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_PRODUCTNAME:
			return [rh getTempString:productName];
		case EXP_PRODUCTDESCRIPTION:
			return [rh getTempString:productDescription];
		case EXP_PRODUCTPRICE:
			return [rh getTempDouble:productPrice];
		case EXP_PRODUCTPRICELOCALE:
			return [rh getTempString:localizedPrice];
		case EXP_PRODUCTIDENTIFIER:
			return [rh getTempString:productIdentifier];
		case EXP_STORERECEIPT:
			return [rh getTempString:storeReceipt];
		case EXP_PRODUCTQUANTITY:
			return [rh getTempValue:(int)productQuantity];
		case EXP_ERRORSTRING:
			return [rh getTempString:lastErrorString];
		case EXP_ERRORNUMBER:
			return [rh getTempValue:(int)lastErrorNumber];
	}
	return [rh getTempValue:0];//won't happen
}

@end
