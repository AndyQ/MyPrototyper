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

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *projects;
    NSString *selectedProjectName;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

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
    selectedProjectName = @"Default";
    [projects addObject:selectedProjectName];
    [self.tableView reloadData];
}

- (IBAction) editPressed:(id)sender
{
    
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

@end
