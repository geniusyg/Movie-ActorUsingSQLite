//
//  ViewController.m
//  SqliteTest01
//
//  Created by SDT-1 on 2014. 1. 13..
//  Copyright (c) 2014년 SDT-1. All rights reserved.
//

#import "ViewController.h"
#import "Movie.h"
#import <sqlite3.h>
#import "ActorViewController.h"


@interface ViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *tf;
@property (weak, nonatomic) IBOutlet UITableView *table;

@end

@implementation ViewController {
	int cc;
	NSMutableArray *data;
	sqlite3 *db;
	NSMutableArray *actors;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	ActorViewController *avc = segue.destinationViewController;
	
	UITableViewCell *cell = (UITableViewCell *)sender;
	NSIndexPath *path = [self.table indexPathForCell:cell];
	Movie *tmp = data[path.row];
	
	avc.mid = tmp.rowID;
	avc.db = db;
}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
	NSString *str = [alertView textFieldAtIndex:0].text;
	return [str length] > 0;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(alertView.firstOtherButtonIndex == buttonIndex) {
		UITextField *newTitle = [alertView textFieldAtIndex:0];
		[self updateDB:newTitle.text];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"변경" message:nil delegate:self cancelButtonTitle:@"취소" otherButtonTitles:@"확인", nil];
	alert.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField *tmp = [alert textFieldAtIndex:0];
	Movie *tmp2 = data[indexPath.row];
	tmp.text = tmp2.title;
	[alert show];
	
}

- (void)updateDB:(NSString *)newTitle {
	
	NSIndexPath *path = [self.table indexPathForSelectedRow];
	Movie *tmp = data[path.row];
	NSString *sql = [NSString stringWithFormat:@"update movie set title = '%@' where rowid = %d",newTitle,tmp.rowID];
	NSLog(@"sql : %@", sql);
	
	char *errmsg;
	int ret = sqlite3_exec(db, [sql UTF8String], NULL, nil, &errmsg);
	
	if(SQLITE_OK != ret) {
		NSLog(@"Error update : %s", errmsg);
	}
	
	
	[self resolveData];
}

- (void)openDB {
	NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	NSString *dbFilePath = [docPath stringByAppendingPathComponent:@"db.sqlite"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL existFile = [fm fileExistsAtPath:dbFilePath];
	
	int ret = sqlite3_open([dbFilePath UTF8String], &db);
	NSAssert1(SQLITE_OK == ret, @"ErrorDB : %s", sqlite3_errmsg(db));
	NSLog(@"Success on opening DB");
	
	if(YES == existFile) {
		const char *createSQL = "create table if not exists movie (title text)";
		char *errorMsg;
		ret = sqlite3_exec(db, createSQL, NULL, NULL, &errorMsg);
		
		if(SQLITE_OK != ret) {
			[fm removeItemAtPath:dbFilePath error:nil];
		}
		
		NSAssert1(SQLITE_OK == ret, @"error db = %s", errorMsg);
		
		const char *createSQL2 = "create table if not exists actor (movie_id int, name text)";
		char *errorMsg2;
		int ret2 = sqlite3_exec(db, createSQL2, NULL, NULL, &errorMsg2);
		
		if(SQLITE_OK != ret2) {
			[fm removeItemAtPath:dbFilePath error:nil];
		}
		
		NSAssert1(SQLITE_OK == ret, @"error db = %s", errorMsg);
		NSLog(@"creating table with ret : %d", ret);
	}
}

- (void)addData:(NSString *)input {
	NSLog(@"adding data : %@", input);
	
	NSString *sql = [NSString stringWithFormat:@"insert into movie values ('%@')",input];
	NSLog(@"sql : %@", sql);
	
	char *errmsg;
	int ret = sqlite3_exec(db, [sql UTF8String], NULL, nil, &errmsg);
	
	if(SQLITE_OK != ret) {
		NSLog(@"Error insert : %s", errmsg);
	}
	
	[self resolveData];
	
}

- (void)closeDB {
	sqlite3_close(db);
}

- (void)resolveData {
	[data removeAllObjects];
	
	NSString *queryStr = @"select rowid, title from movie";
	sqlite3_stmt *stmt;
	int ret = sqlite3_prepare_v2(db, [queryStr UTF8String], -1, &stmt, NULL);
	
	NSAssert2(SQLITE_OK == ret, @"error(%d) data : %s", ret, sqlite3_errmsg(db));
	
	while(SQLITE_ROW == sqlite3_step(stmt)) {
		int rowID = sqlite3_column_int(stmt, 0);
		char *title = (char *)sqlite3_column_text(stmt, 1);
		
		Movie *one = [[Movie alloc] init];
		one.rowID = rowID;
		one.title = [NSString stringWithCString:title encoding:NSUTF8StringEncoding];
		
		[data addObject:one];
	}
	
	sqlite3_finalize(stmt);
	
	[self.table reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if([textField.text length] > 0) {
		[self addData:textField.text];
		[textField resignFirstResponder];
		textField.text=@"";
	}
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if(UITableViewCellEditingStyleDelete == editingStyle) {
		Movie *one = [data objectAtIndex:indexPath.row];
		NSString *sql = [NSString stringWithFormat:@"delete from movie where rowid = %d", one.rowID];
		
		char *errormsg;
		int ret = sqlite3_exec(db, [sql UTF8String], NULL, NULL, &errormsg);
		
		if(SQLITE_OK != ret) {
			NSLog(@"error %d delete %s", ret,errormsg);
		}
		
		[self resolveData];
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MOVIE_CELL"];
	
	Movie *one = [data objectAtIndex:indexPath.row];
	cell.textLabel.text = one.title;
	
	return cell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	data = [NSMutableArray array];
	actors = [NSMutableArray array];
	[self openDB];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self resolveData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end





















