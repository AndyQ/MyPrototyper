//
//  MainViewController.m
//  Prototyper
//
//  Created by Andy Qua on 12/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "MainViewController.h"
#import "ProjectViewController.h"
#import "Project.h"

@interface MainViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *projects;
    NSString *selectedProjectName;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@end

@implementation MainViewController

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

    [self loadProjects];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) addProjectPressed:(id)sender
{
    // prompt for name
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Enter project name" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av show];
}

- (IBAction) editPressed:(id)sender
{
    self.tableView.editing = !self.tableView.editing;
    if ( self.tableView.editing )
    {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editPressed:)];
        self.navigationItem.rightBarButtonItem = editButton;
        self.addButton.enabled = NO;
    }
    else
    {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editPressed:)];
        self.navigationItem.rightBarButtonItem = editButton;
        self.addButton.enabled = YES;
    }
}

#pragma mark - UIAlertViewDelegate methods
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    NSString *inputText = [[alertView textFieldAtIndex:0] text];
    if ( [projects containsObject:inputText] || inputText.length == 0 )
        return NO;
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 1 )
    {
        NSString *name = [alertView textFieldAtIndex:0].text;
        
        [projects addObject:name];
        [self.tableView reloadData];
    }
}
#pragma mark - Load projects
- (void) loadProjects
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    projects = [NSMutableArray array];
    NSArray *files = [fm contentsOfDirectoryAtPath:[Project getDocsDir] error:nil];
    for ( NSString *file in files )
    {
        if ( ![file hasPrefix:@"."] )
            [projects addObject:file];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"ShowProject"] )
    {
        ProjectViewController *vc = segue.destinationViewController;
        vc.projectName = selectedProjectName;
    }
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *project = projects[indexPath.row];
    cell.textLabel.text = project;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedProjectName = projects[indexPath.row];
    [self performSegueWithIdentifier:@"ShowProject" sender:self];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete )
    {
        [Project deleteProjectWithName:projects[indexPath.row]];
        [projects removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
