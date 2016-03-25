//
//  ViewController.swift
//  FAMCollapseTableView
//
//  Created by Kazuya Ueoka on 2016/03/24.
//  Copyright © 2016年 Timers inc. All rights reserved.
//

import UIKit

protocol SectionHeaderDelegate
{
    func sectionHeaderDidTapped(sectionHeader :SectionHeaderView) -> Void
}

public class SectionHeaderView :UITableViewHeaderFooterView
{
    private var didSet :Bool = false
    lazy var titleLabel :UILabel = {
        let result :UILabel = UILabel()
        return result
    }()
    lazy var tapGesture :UITapGestureRecognizer = {
        let gesture :UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SectionHeaderView._tappedSelf(_:)))
        return gesture
    }()
    var delegate :SectionHeaderDelegate?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self._commonInit()
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self._commonInit()
    }

    private func _commonInit() -> Void
    {
        if (!self.didSet)
        {
            self.addSubview(self.titleLabel)
            self.addGestureRecognizer(self.tapGesture)
            self.didSet = true
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.titleLabel.frame = CGRectMake(16.0, (self.frame.size.height - 20.0) / 2.0, self.frame.size.width - 32.0, 20.0);
    }

    public func _tappedSelf(gesture :UITapGestureRecognizer)
    {
        self.delegate?.sectionHeaderDidTapped(self)
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SectionHeaderDelegate {

    let cellIdentifier = "cellIdentifier"
    let headerIdentifier = "headerIdentifier"

    lazy var dataSource :FAMCollapseTableViewDataSource = {
        let result :FAMCollapseTableViewDataSource = FAMCollapseTableViewDataSource(dataSource: self)
        result.exclusiveSections = true
        return result
    }()

    lazy var tableView :UITableView = {
        let result :UITableView = UITableView()
        result.delegate = self
        result.dataSource = self.dataSource
        result.registerClass(UITableViewCell.self, forCellReuseIdentifier: self.cellIdentifier)
        result.registerClass(SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: self.headerIdentifier)
        return result
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.tableView)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.tableView.frame = self.view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header :SectionHeaderView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(self.headerIdentifier) as! SectionHeaderView
        header.titleLabel.text = "\(section)"
        header.delegate = self
        header.tag = section
        return header
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }

    func sectionHeaderDidTapped(sectionHeader: SectionHeaderView) {
        let open :Bool = (self.dataSource as FAMCollapseTableViewProtocol).tableView(self.tableView, toggleSection: sectionHeader.tag, animated: true)
        print("\(open)")
    }
}

