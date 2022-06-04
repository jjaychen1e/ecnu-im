//
//  MySplitViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/6/5.
//

import UIKit

class MySplitViewController: UISplitViewController {
    func setOverrideTraitCollectionForAllChildViewControllers(_ collection: UITraitCollection?) {
        for child in children {
            setOverrideTraitCollection(collection, forChild: child)
        }
    }
}
