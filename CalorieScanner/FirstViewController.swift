//
//  FirstViewController.swift
//  CalorieScanner
//
//  Created by kkkdev on 2016/06/22.
//  Copyright © 2016年 kkkdev. All rights reserved.
//

import UIKit
import SVProgressHUD
import Foundation

import RxSwift
import RxCocoa

import Alamofire
import SwiftyJSON
/**
 結果のViewController
 */
class FirstViewController: UIViewController , UITabBarControllerDelegate, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    //問い合わせ結果のview
    @IBOutlet weak var calorieResultTableView: UITableView!
    //合計カロリーのラベル
    @IBOutlet weak var calorieSum: UILabel!
    
    var candidatePicker: UIPickerView! = UIPickerView()
    var overlayView: UIView! = UIView()
    var subitButton: UIButton! = UIButton(type: UIButtonType.RoundedRect)
    
    //APIのエンドポイント
    let SERACH_API_ENDPOINT_URL:String = "http://************/api/index.php/search/"
    //候補選択のpickerViewの高さ
    let CANDIDATE_PICKER_VIEW_HEIGHT:CGFloat = 250.0
    
    var janCodeList:Variable<[String]>  = JanCodeMyMvcViewModel.getInstance().list
    var resultList:Variable<[Array<Dictionary<String, AnyObject>>]> = Variable<[Array<Dictionary<String, AnyObject>>]>([])
    let disposeBag = DisposeBag()
    //候補リストのインデックス
    var selectedCandidateIndex = 0
    var selectedCandidate:Array<Dictionary<String, AnyObject>> = []
    //選択した候補の値インデックス
    var selectedCandidateValueIndex = 0
    
    // MARK: public method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initalizeUI()
        self.initializeBind()
    }
    
    func getCalorieAPIResult () {
        janCodeList.value.flatMap{ callAPI($0) }
    }
    
    /** janコードを指定してカロリー検索を行う */
    func callAPI(janCode:String){
        Alamofire.request(.GET, SERACH_API_ENDPOINT_URL + janCode).responseJSON { response in
                response.result.value.flatMap{ self.parseAPIResponse($0) }
                    .flatMap{
                        (var parsedObj) in self.resultList.value.append(parsedObj)
                    }
                    .flatMap{ self.janCodeList.value.removeFirst() }
                    SVProgressHUD.dismiss()
        }
    }
    
    // MARK: private method
    
    /** レスポンスデータから結果を組み立てる */
    private func parseAPIResponse(v:AnyObject) -> Array<Dictionary<String, AnyObject>>{
        var itemRoot:[Dictionary<String, AnyObject>] = []
        JSON(v)["result"].forEach { (_, json) in
            let name:String? = json["name"].string
            let cal:Int? = json["cal"].int
            if let name_ = name, cal_ = cal {
                itemRoot.append(["name": name_, "cal":cal_])
            }else {
                itemRoot.append(["name":"なし", "cal":0])
            }
        }
        return itemRoot
    }
    
    private func initalizeUI(){
        //tabbarのデリゲート
        self.tabBarController.flatMap{ $0.delegate = self }
        //候補の選択肢
        self.candidatePicker.frame = CGRectMake(
            0,100,
            self.view.bounds.width, CANDIDATE_PICKER_VIEW_HEIGHT)
        self.candidatePicker.delegate = self
        self.candidatePicker.dataSource = self
        //選択画面レイヤー
        self.overlayView.frame = CGRectMake(0,0,self.view.bounds.width,self.view.bounds.height)
        self.overlayView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.9)
        //決定ボタン
        self.subitButton.frame = CGRectMake(self.view.bounds.width-100, 100+CANDIDATE_PICKER_VIEW_HEIGHT
            , 100, 50)
        self.subitButton.setTitle("決定", forState: UIControlState.Normal)
        //決定後の処理
        self.subitButton.addTarget(self, action: #selector(self.decideCalorieCandidate), forControlEvents: UIControlEvents.TouchUpInside)
        self.calorieResultTableView.delegate = self
    }
    
    private func initializeBind(){
        //RxSwiftでバインディング
        self.resultList.asObservable().bindTo(
            calorieResultTableView.rx_itemsWithCellIdentifier("Cell",
                cellType: UITableViewCell.self))
        { (row, element, cell) in
            element[0]["name"].flatMap{ cell.textLabel?.text = "\($0)" }//名前
            element[0]["cal"].flatMap{ cell.detailTextLabel?.text = "\($0)kcal" }//カロリー
            //結果が1件だけの時は、選択アイコンを消す
            cell.accessoryType =
                (element.count > 1) ? UITableViewCellAccessoryType.DetailButton: UITableViewCellAccessoryType.None
            self.updateSum()
            }.addDisposableTo(disposeBag)
        
    }
    
    func decideCalorieCandidate(){
        //複数あった選択肢を1つに決定
        //self.resultList.value[self.selectedCandidateIndex]
        self.resultList.value[self.selectedCandidateIndex] = [self.selectedCandidate[self.selectedCandidateValueIndex]]
        
        self.selectedCandidateIndex = 0;
        self.selectedCandidate = []
        self.hideCandidate()
    }
    
    private func hideCandidate(){
        self.subitButton.removeFromSuperview()
        self.candidatePicker.removeFromSuperview()
        self.overlayView.removeFromSuperview()
    }
    
    private func update() {
        self.updateSum()
        //スキャンしたコードがなかったら何もしない
        if(janCodeList.value.count < 1){
            return
        }
        // ローディング
        SVProgressHUD.show()
        self.getCalorieAPIResult()
    }
    
    private func updateSum(){
    //合計を表示
    let sumCal = self.resultList.value.flatMap{ $0[0] }.flatMap{ $0["cal"] as? Int }
    .reduce(0, combine: { $0 + $1 })
    self.calorieSum.text = "合計:\(sumCal)kcal"
    }
    
    // MARK: delegate method(UITableView)
    //アイコンを選択したら、選択肢を表示
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        //インデックスと候補の参照を記録
        self.selectedCandidateIndex = indexPath.row
        self.selectedCandidate = self.resultList.value[self.selectedCandidateIndex]
        
        self.view.addSubview(self.overlayView)
        self.view.addSubview(self.candidatePicker)
        self.view.addSubview(self.subitButton)
        self.view.bringSubviewToFront(self.overlayView)
        self.view.bringSubviewToFront(self.candidatePicker)
        self.view.bringSubviewToFront(self.subitButton)
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController){
        if( viewController != self){
            //別viewに切り替わったら、掃除
            self.dispose()
            return
        }
        
        self.update()
    }
    
    // MARK: delegate method(UIPickerView)
    
    //表示列
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /*
     pickerに表示する行数を返すデータソースメソッド.
     (実装必須)
     */
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.selectedCandidate.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultList.value.count
    }

    /*
     pickerに表示する値を返すデリゲート
     */
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.selectedCandidate[row]["name"] as? String ?? ""
    }
    
    /*
     pickerが選択された際に呼ばれるデリゲートメソッド.
     */
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedCandidateValueIndex = row
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK:release
    
    func dispose(){
        self.hideCandidate()
        //ローディングの後始末
        SVProgressHUD.dismiss()
    }
    
    deinit{
        self.calorieResultTableView.delegate = nil
        self.calorieResultTableView.dataSource = nil
        self.candidatePicker = nil
    }
}

