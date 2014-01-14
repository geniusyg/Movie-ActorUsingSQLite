//
//  ActorViewController.m
//  SqliteTest01
//
//  Created by SDT-1 on 2014. 1. 14..
//  Copyright (c) 2014년 SDT-1. All rights reserved.
//

#import "ActorViewController.h"
#import "Movie.h"

@interface ActorViewController ()<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation ActorViewController {
	NSMutableArray *actors;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if(UITableViewCellEditingStyleDelete == editingStyle) {
		NSString *one = [actors objectAtIndex:indexPath.row];
		NSString *sql = [NSString stringWithFormat:@"delete from actor where movie_id = %d and name = '%@'", self.mid,one];
		
		char *errormsg;
		int ret = sqlite3_exec(self.db, [sql UTF8String], NULL, NULL, &errormsg);
		
		if(SQLITE_OK != ret) {
			NSLog(@"error %d delete %s", ret,errormsg);
		}
		
		[self resolveData];
	}
}

- (void)resolveData {
	[actors removeAllObjects];
	
	NSString *queryStr = [NSString stringWithFormat:@"select name from actor where movie_id = %d",self.mid];
	sqlite3_stmt *stmt;
	int ret = sqlite3_prepare_v2(self.db, [queryStr UTF8String], -1, &stmt, NULL);
	
	NSAssert2(SQLITE_OK == ret, @"error(%d) data : %s", ret, sqlite3_errmsg(self.db));
	
	while(SQLITE_ROW == sqlite3_step(stmt)) {
		
		char *aname = (char *)sqlite3_column_text(stmt, 0);
		
		[actors addObject:[NSString stringWithCString:aname encoding:NSUTF8StringEncoding]];
		Movie *one = [[Movie alloc] init];
		one.actors = actors;
	}
	
	sqlite3_finalize(stmt);
	
	[self.table reloadData];
}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
	NSString *str = [alertView textFieldAtIndex:0].text;
	return [str length] > 0;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(alertView.firstOtherButtonIndex == buttonIndex) {
		UITextField *actorName = [alertView textFieldAtIndex:0];
		[self addActorDB:actorName.text];
	}
}

- (void)addActorDB:(NSString *)name {
	NSString *sql = [NSString stringWithFormat:@"insert into actor values (%d, '%@')",self.mid,name];
	NSLog(@"sql : %@", sql);
	
	char *errmsg;
	int ret = sqlite3_exec(self.db, [sql UTF8String], NULL, nil, &errmsg);
	
	if(SQLITE_OK != ret) {
		NSLog(@"Error insert : %s", errmsg);
	}
	
	[self resolveData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACTORS_CELL"];
	
	NSString *tmp = [actors objectAtIndex:indexPath.row];
	cell.textLabel.text = tmp;
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [actors count];
}

- (IBAction)addActor:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"추가" message:nil delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"확인", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	[alert show];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	actors = [NSMutableArray array];
	
	[self resolveData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

















