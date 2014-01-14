//
//  ActorViewController.h
//  SqliteTest01
//
//  Created by SDT-1 on 2014. 1. 14..
//  Copyright (c) 2014년 SDT-1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@interface ActorViewController : UIViewController

@property int mid;
@property sqlite3 *db;

@end
