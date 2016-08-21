//
//  JanCodeUtil.swift
//  CalorieScanner
//
//  Created by mac on 2016/08/09.
//  Copyright © 2016年 kkkdev. All rights reserved.
//

import Foundation

class JanCodeUtil {
    /**
     バーコードが正しいフォーマットか(簡易)チェック
     @param String バーコードの値
     @return Bool 正しいフォーマットか？
     */
    static func isValidFormat(barCode:String) -> Bool{
        //JAN13桁のみ扱う(8桁はYahoo APIでうまく検索できないため)
        if(barCode.characters.count == 13){
            if(barCode.hasPrefix("49") || barCode.hasPrefix("45")) {return true}
        }
        return false
    }
}