//
//  SocketVC.m
//  Jiankongbao
//
//  Created by yunzhihui on 16/2/19.
//  Copyright © 2016年 YunZhiHui. All rights reserved.
//

#import "SocketVC.h"
#import "SocketTestVC.h"
#import "SocketTestVCASY.h"
@interface SocketVC ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property(nonatomic,strong)UITableView *listTableView;
@property(nonatomic,strong)NSArray *requestTypeArray;

@end

@implementation SocketVC

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 27)];
    [btn setImage:[UIImage imageNamed:@"back_icon.png"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = backItem;
    
    self.listTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:_listTableView];
    self.listTableView.dataSource = self;
    self.listTableView.delegate = self;
    self.listTableView.tableFooterView = [UIView new];
    
    NSArray *array = [NSArray arrayWithObjects:@"AsyncSocket-(CFStream)",@"CFSocket", nil];
    self.requestTypeArray = array;
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.requestTypeArray.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"socket"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"socket"];
    }
    
    cell.textLabel.text = [self.requestTypeArray objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
         case 0:{
            SocketTestVCASY *scvc = [[SocketTestVCASY alloc] init];
            [self.navigationController pushViewController:scvc animated:YES];
        }
            break;
        case 1:
        {
            SocketTestVC *testVC = [[SocketTestVC alloc] init];
            [self.navigationController pushViewController:testVC animated:YES];
        }
            break;
        default:
            break;
    }
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}
- (void)backAction{
    
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
