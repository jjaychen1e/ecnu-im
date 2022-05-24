//
//  NoOverlayViewController.swift
//  ecnu-im
//
//  Created by 陈俊杰 on 2022/5/13.
//

import UIKit

protocol NoOverlayViewController: UIViewController {
    func shouldPushTo(nvc: UINavigationController?) -> Bool
    func shouldReactTo(nvc: UINavigationController?, ext: [String : Any]) -> Bool
}
