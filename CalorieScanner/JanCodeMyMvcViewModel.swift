//
//  JanCodeMyMvcViewModel.swift
//  CalorieScanner
//
//  Created by mac on 2016/08/09.
//  Copyright © 2016年 kkkdev. All rights reserved.
//

import Foundation
import RxSwift

class JanCodeMyMvcViewModel {
    private static let sharedInstance = JanCodeMyMvcViewModel()
    
    let list:Variable<[String]>  = Variable<[String]>([])
    
    private init() {}
    
    static func getInstance() -> JanCodeMyMvcViewModel{
        return sharedInstance
    }
    
    func add(janCode:String) -> Void {
        if(!list.value.contains(janCode)){
            list.value.append(janCode)
        }
    }
    
    func clear() -> Void {
        list.value.removeAll()
    }
}