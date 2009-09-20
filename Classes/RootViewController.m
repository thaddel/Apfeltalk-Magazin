//
//  RootViewController.m
//  Apfeltalk Magazin
//
//	Apfeltalk Magazin -- An iPhone Application for the site http://apfeltalk.de
//	Copyright (C) 2009	Stephan König (stephankoenig at me dot com), Stefan Kofler
//						Alexander von Below, Andreas Rami, Michael Fenske, Laurids Düllmann, Jesper Frommherz (Graphics),
//						Patrick Rollbis (Graphics),
//						
//	This program is free software; you can redistribute it and/or
//	modify it under the terms of the GNU General Public License
//	as published by the Free Software Foundation; either version 2
//	of the License, or (at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.//
//

#import "RootViewController.h"


@interface RootViewController (private)
- (BOOL) openDatabase;
- (NSString *) readDocumentsFilename;
- (void) setApplicationDefaults;
@end


@implementation RootViewController

@synthesize stories;


#pragma mark Instance Methods

- (IBAction)openSafari:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apfeltalk.de"]];
}

- (IBAction)about:(id)sender {
	[newsTable reloadData];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:@"Credits" // oder einfach Wilkommen in der Touch-Mania.com Applikation?
						  message:@"Apfeltalk.de App \n \n\nIdee: Stephan König \n\nProgrammierung: Alexander von Below, Andreas Rami, Stefan Kofler, Michael Fenske und \nStephan König \n\nSplashcreen: Patrick Rollbis \n\nIcons: Jesper Frommherz und Patrick Rollbis \n\nGUI: Laurids Düllmann \n\nMit freundlicher Unterstützung der Apfeltalk GmbH"
						  delegate:self
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:@"Kontakt"
						  ,nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1)
	{
		NSArray *recipients = [[NSArray alloc] initWithObjects:@"info@apfeltalk.de", nil];
		MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
		controller.mailComposeDelegate = self;
		[controller setToRecipients:recipients];
		[recipients release];
		[self presentModalViewController:controller animated:YES];
		[controller release];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self becomeFirstResponder];
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [stories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
    }

	// Configure the cell.

	int storyIndex = [indexPath row];
	// Everything below here is customization

	NSString * link = [[stories objectAtIndex: indexPath.row] link];
	BOOL read = [self databaseContainsURL:link];

	if (read) {
		cell.imageView.image = [UIImage imageNamed:@"thread_dot.gif"];
	} else {
		cell.imageView.image = [UIImage imageNamed:@"thread_dot_hot.gif"];
	}

	cell.textLabel.text = [[stories objectAtIndex: storyIndex] title];

    return cell;
}

#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Navigation logic
	
	Story *story = [stories objectAtIndex: indexPath.row];
	Class dvClass = [self detailControllerClass];
	DetailViewController *detailController = [[dvClass alloc] initWithNibName:@"DetailView" 
																	   bundle:[NSBundle mainBundle]
																		story:story];

	NSString * link = [story link];

	if ([link length] > 0 && ![self databaseContainsURL:link]) {
		NSDate *date = [[stories objectAtIndex: indexPath.row] date];
		
		const char *sql = "insert into read(url, date) values(?,?)"; 
		sqlite3_stmt *insert_statement;
		int error;
		error = sqlite3_prepare_v2(database, sql, -1, &insert_statement, NULL); 
		if (error == SQLITE_OK) {
			sqlite3_bind_text(insert_statement, 1, [link UTF8String], -1, SQLITE_TRANSIENT); 
			sqlite3_bind_double(insert_statement, 2, [date timeIntervalSinceReferenceDate]);
			error = (sqlite3_step(insert_statement) != SQLITE_DONE);
		}
		if (error == SQLITE_OK)
			error = sqlite3_finalize(insert_statement);	
		
		// This code could be resued in the News Controller
		if (error != SQLITE_OK) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString (@"Datenbank Fehler", @"")
															message:NSLocalizedString (@"Ein unerwarteter Fehler ist aufgetreten", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString (@"OK", @"") otherButtonTitles:nil];
			[alert show];
			[alert release];
		}

		/*
		 *	More thinking needs to go into the deletion of reads
		 *
		 sqlite3_stmt *delete_statement;
		 NSString *deleteSql = [NSString stringWithFormat:@"delete from read where date<%f", [[[self class] oldestStoryDate] timeIntervalSinceReferenceDate]];
		 error = sqlite3_prepare_v2(database, [deleteSql UTF8String], -1, &delete_statement, NULL); 
		 if (error != SQLITE_OK)
		 NSLog (@"An error occurred: %s", sqlite3_errmsg(database));
		 
		 error = sqlite3_step(delete_statement); 
		 error = error != SQLITE_DONE;
		 
		 error = sqlite3_finalize(delete_statement);	
		 if (error != SQLITE_OK)
		 NSLog (@"An error occurred: %s", sqlite3_errmsg(database));
		 */	
		[newsTable reloadData];
		
		// update the number of unread messages in Application Badge
		[self updateApplicationIconBadgeNumber];
	}

	[self.navigationController pushViewController:detailController animated:YES];
	[detailController release];
}

#pragma mark -
#pragma mark Database

- (BOOL) openDatabase {
	if (![[NSFileManager defaultManager] fileExistsAtPath:[self readDocumentsFilename]])
	{
		NSError *error;
		NSString *dbResourcePath = [[NSBundle mainBundle] pathForResource:@"gelesen" ofType:@"db"];
		[[NSFileManager defaultManager] copyItemAtPath:dbResourcePath toPath:[self readDocumentsFilename] error:&error];
		// Check for errors...
	}
	
	if (sqlite3_open([[self readDocumentsFilename] UTF8String], &database) 
        == SQLITE_OK)
		return true;
	else 
		return false;
}

/*
 * This funktion checks to see if the given URL is in the database
 */
- (BOOL) databaseContainsURL:(NSString *)link {
	BOOL found = NO;
	
	const char *sql = "select url from read where url=?";
	sqlite3_stmt *statement;
	int error;
	
	error = sqlite3_prepare_v2(database, sql, -1, &statement, NULL);
	if (error == SQLITE_OK) {
		error = sqlite3_bind_text (statement, 1, [link UTF8String], -1, SQLITE_TRANSIENT);
		if (error == SQLITE_OK && sqlite3_step(statement) == SQLITE_ROW) {
			found = YES;
		}
	}
	if (error != SQLITE_OK)
		NSLog (@"An error occurred: %s", sqlite3_errmsg(database));
	error = sqlite3_finalize(statement);	
	if (error != SQLITE_OK)
		NSLog (@"An error occurred: %s", sqlite3_errmsg(database));

	return found;
}

#pragma mark -

- (NSString *) documentPath {
	return @"http://feeds.apfeltalk.de/apfeltalk-magazin";
}

- (NSString *) supportFolderPath {
	// This could be static
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	assert ([paths count]);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

- (NSString *) readDocumentsFilename {	 
	return [[self supportFolderPath] stringByAppendingPathComponent:@"gelesen.db"];
}

- (Class) detailControllerClass {
	return [DetailViewController self];
}

- (void)viewWillAppear:(BOOL)animated {
	[self openDatabase];
	// read and set defaults from preference pane
	[self setApplicationDefaults];
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if ([stories count] == 0)
		[self parseXMLFileAtURL:[self documentPath]];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	int error = sqlite3_close(database);
	assert (error == 0);
}

- (void)setApplicationDefaults {
	NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"showIconBadge"];
	if (testValue == nil)
	{
		// no default values have been set, create them here based on what's in our Settings bundle info
		showIconBadge = YES;
		shakeToReload = YES;
		vibrateOnReload = YES;
	} else {
		// set the showIconBadge property
		NSString *iconBadgeToogleValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"showIconBadge"];
		if([iconBadgeToogleValue isEqualToString: @"1"]) {
			showIconBadge = YES;
		} else {
			showIconBadge = NO;
		}
		
		// set the shakeToReload property
		NSString *shakeToReloadToggleValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"shakeToReload"];
		if([shakeToReloadToggleValue isEqualToString: @"1"]) {
			shakeToReload = YES;
		} else {
			shakeToReload = NO;
		}
		
		// set the vibrateOnReload property
		NSString *vibrateOnReloadToggleValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"vibrateOnReload"];
		if([vibrateOnReloadToggleValue isEqualToString:@"1"]) {
			vibrateOnReload = YES;
		} else {
			vibrateOnReload = NO;
		}

	}
	
	NSLog(@"Application configuration: [showIconBadge: %d], [shakeToReload: %d], [vibrateOnReload: %d]", showIconBadge, shakeToReload, vibrateOnReload);
}

- (void)parseXMLFileAtURL:(NSString *)URL
{
    ATXMLParser *parser = [[ATXMLParser alloc] initWithURLString:URL];

    [parser setDelegate:self];
    [parser parse];
    [parser release];
}

- (void)updateApplicationIconBadgeNumber {
	//logic is now in each Controllers
}

// activate the UIAcceleromter for Shake To Reload
- (void) activateShakeToReload:(id)delegate
{
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
    accel.delegate = delegate;
    accel.updateInterval = kUpdateInterval;	
}

- (BOOL) isShake:(UIAcceleration *)acceleration
{
	BOOL ret = NO;
	
	if (acceleration.x > kAccelerationThreshold || acceleration.y > kAccelerationThreshold || acceleration.z > kAccelerationThreshold)
	{
		ret = YES;
		NSLog(@"shake was recognized");
	}
	
	return ret;
}


- (void)dealloc
{	
	[stories release];

	[super dealloc];
}


#pragma mark -
#pragma mark ATXMLParserDelegateProtocol

- (void)parser:(ATXMLParser *)parser setParsedStories:(NSArray *)parsedStories
{
    [self setStories:parsedStories];
    [(UITableView *)[self view] reloadData];
}



- (void)parser:(ATXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"%@", [parseError localizedDescription]);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Content konnte nicht geladen werden", nil)
                                                        message:@"Der Feed ist im Moment nicht verfügbar. Versuche es bitte später erneut."
													   delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

@end
