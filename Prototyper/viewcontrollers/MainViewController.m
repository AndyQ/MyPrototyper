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
#import "ProjectSelectTableViewCell.h"
#import "PopoverView.h"

#import "Constants.h"

#import "IASKAppSettingsViewController.h"

@interface MainViewController () <IASKSettingsDelegate, PopoverViewDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    PopoverView *popoverView;

    NSMutableArray *projects;
    NSString *selectedProjectName;
    
    UIBarButtonItem *actionButton;
    UIBarButtonItem *doneButton;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
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
    [super viewDidLoad];\
    
    actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionPressed:)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)];
    self.navigationItem.rightBarButtonItem = actionButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    // Register for import notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadProjects) name:NOTIF_IMPORTED object:nil];

    [self loadProjects];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

-( IBAction) actionPressed:(id)sender
{
    NSArray *items = @[@"Delete projects", @"Settings"];
    popoverView = [PopoverView showPopoverAtPoint:CGPointMake( self.view.frame.size.width - 20, 0) inView:self.view withStringArray:items delegate:self];
}

#pragma mark - PopoverView delegate

- (void)popoverView:(PopoverView *)thePopoverView didSelectItemAtIndex:(NSInteger)index itemText:(NSString *)text
{
    if ( [text isEqualToString:@"Delete projects"] )
    {
        self.tableView.editing = YES;
        [self.tableView reloadData];
        self.navigationItem.rightBarButtonItem = doneButton;
        self.addButton.enabled = NO;
    }
    if ( [text isEqualToString:@"Settings"] )
    {
        IASKAppSettingsViewController *appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        appSettingsViewController.delegate = self;
        appSettingsViewController.showDoneButton = YES;
        
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:appSettingsViewController];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        [self presentViewController:nc animated:YES completion:^{ }];
    }

    [popoverView dismiss];
    popoverView = nil;
    
}

- (void)popoverViewDidDismiss:(PopoverView *)thePopoverView;
{
    popoverView = nil;
}


- (void) donePressed:(id)sender
{
    self.tableView.editing = NO;
    [self.tableView reloadData];

    self.navigationItem.rightBarButtonItem = actionButton;
    self.addButton.enabled = YES;
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
        
        Project *p = [[Project alloc] init];
        p.projectName = name;
        [projects addObject:p];
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
        NSString *path = [[Project getDocsDir] stringByAppendingPathComponent:file];
        BOOL isDir = NO;
        if (![file hasPrefix:@"."] && [fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
        {
            ProjectType projectType = [Project getProjectTypeForProject:file];
            Project *p = [[Project alloc] init];
            p.projectName = file;
            p.projectType = projectType;
            [projects addObject:p];
        }
    }
    
    [self.tableView reloadData];
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
    ProjectSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    Project *project = projects[indexPath.row];
    cell.projectName.text = project.projectName;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && project.projectType == PT_IPHONE)
        cell.projectName.text = [project.projectName stringByAppendingString:@" - iPhone project"];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && project.projectType == PT_IPAD)
        cell.projectName.text = [project.projectName stringByAppendingString:@" - iPad project"];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = projects[indexPath.row];
    selectedProjectName = project.projectName;
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
        Project *project = projects[indexPath.row];
        [Project deleteProjectWithName:project.projectName];
        [projects removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - InAppSettingsKit Delegate
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
