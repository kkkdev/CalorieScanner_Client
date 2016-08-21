//
//  BarCodeReaderViewController.swift
//  CalorieScanner
//
//  Created by kkkdev on 2016/06/22.
//  Copyright © 2016年 kkkdev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

import RxSwift
import RxCocoa

/**
 
 */
class BarCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var barCodeTableView: UITableView!
    @IBOutlet weak var dummyLabel: UILabel!
    
    let disposeBag = DisposeBag()
    let session = AVCaptureSession()

    var janCodeList:Variable<[String]>  = JanCodeMyMvcViewModel.getInstance().list
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //RxSwiftでバインディング
        janCodeList.asObservable().bindTo(
            barCodeTableView.rx_itemsWithCellIdentifier("Cell",
            cellType: UITableViewCell.self))
        { (row, element, cell) in
            cell.textLabel?.text = "\(element)"
        }.addDisposableTo(disposeBag)

        
        //バーコード関係
        var input:AVCaptureDeviceInput
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            print("error")
            return
        }
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        session.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.frame = CGRect(x: 0, y: 0,
                             width: self.view.bounds.width, height: 250)
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(layer)
        session.startRunning()
    }
    
    /**
     バーコードを読み取り、ユニークなレコードを表示する
     */
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        metadataObjects.flatMap { $0.stringValue }
            //バッチリURLとかも入ってくるので、先にバリデーション必須
            .filter{ JanCodeUtil.isValidFormat($0)}
            .flatMap{ JanCodeMyMvcViewModel.getInstance().add($0) }        
    }
}
