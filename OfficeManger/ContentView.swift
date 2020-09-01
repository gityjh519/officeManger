//
//  ContentView.swift
//  OfficeManger
//
//  Created by yaojinhai on 2020/8/18.
//  Copyright © 2020 yaojinhai. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    
    @EnvironmentObject var model: DateItemModel
    
    @State var isAlert = false
    
    @State var alertTitle = ""
    @State var buttonAction: (()->Void)?
    
    @State var selectedSet = IndexSet.init()
    
    
    
    var body: some View {
        NavigationView {
            contentView
            
        }.alert(isPresented: $isAlert) { 
            Alert(title: Text(alertTitle), message: nil, primaryButton: .cancel(), secondaryButton: .default(Text("确定"), action: { 
                self.buttonAction?()
            }))
        }
    }
    
    
    
    var contentView: some View {
        
        VStack {
            
            List{ 
                
                ForEach(model.list) { (item: DateModel) in
                    
                    DateTimeItem(model: .constant(item), date: self.model.currentDate)
                    
                }.onDelete { (set: IndexSet) in
                    if let index = set.first {
                        let item = self.model.list[index];
                        self.tapGestureAction(item: item)
                    }
                }
                
            }
            
            ButtonItems(model: .constant(self.model)) { (tag) in
                
                if tag == 0 {
                    self.enterLocation()
                }else if tag == 1 {
                    self.outLocation()
                }
                
            }
            
            
            
        }.navigationBarTitle(Text("打卡记录"), displayMode: .inline).navigationBarItems(trailing: Button(action: { 
            self.qingJiaAM()
            
        }, label: { 
            Text("请假")
        }))
        
        
    }
    
}

extension ContentView {
    
    
    
    func tapGestureAction(item: DateModel) {
        let itemModel = model.list.first { (subItem) -> Bool in
            subItem.id == item.id
        }
        guard let selectedModel = itemModel else {
            return
        }
        alertTitle = "是否删除\(selectedModel.date ?? "")记录"
        buttonAction = {
            () in
            self.model.list.removeAll { (sItem) -> Bool in
                sItem.id == selectedModel.id
            }
        }
        isAlert.toggle()
    }
    
    
    
    func deleteLastDate() {
        
        if model.list.isEmpty {
            return
        }
        alertTitle = "是否删除\(self.model.list.first?.date ?? "")记录"
        buttonAction = {
            () in
            if self.model.list.count > 0 {
                self.model.list.removeLast()
            }
            
        }
        isAlert.toggle()
        
        
    }
    
    func enterLocation() {
        
        let json = model.list.first
        let count = 0
        
        let currentDate = model.currentDate
        
        if !currentDate.contains(json?.date ?? "ppd") {
            
            let nextjson = DateModel(beginTime: json?.currentTime, endTime: nil, date: currentDate)
            self.model.list.insert(nextjson, at: 0)
        }else {
            var next = DateModel(beginTime: json?.beginTime, endTime: json?.endTime, date: json?.date)
            
            if let time = json?.beginTime {
                alertTitle = "上班：重新打卡\(time)"
                buttonAction = {
                    () in
                    next.beginTime = json?.currentTime
                    self.model.list[count] = next
                }
                isAlert.toggle()
            }else {
                next.beginTime = json?.currentTime
                self.model.list[count] = next
                
            }
        }
    }
    
    func outLocation()  {
        
        if model.list.isEmpty {
            alertTitle = "请先打卡上班"
            buttonAction = nil
            isAlert.toggle()
            return
        }
        
        let json = model.list.first
        let count = 0
        
        let currentJson = DateModel(beginTime: json?.beginTime, endTime: json?.currentTime, date: json?.date);
        
        
        if let time = json?.endTime {
            alertTitle = "下班：重新打卡\(time)"
            isAlert.toggle()
            
            buttonAction = {
                () in
                self.model.list[count] = currentJson
            }
        }else {
            model.list[count] = currentJson
        }
    }
    func qingJiaAM() {
        
        let json = model.list.first
        let count = 0
        
        let currentDate = model.currentDate
        
        if !currentDate.contains(json?.date ?? "ppd") {
            
            let nextjson = DateModel(beginTime: "请假", endTime: "请假", date: currentDate)
            self.model.list.insert(nextjson, at: 0)
        }else {
            var next = DateModel(beginTime: "请假", endTime: "请假", date: json?.date)
            
            if json?.beginTime?.contains("请假") == false {
                alertTitle = (json?.date ?? "今天") + " 请假"
                buttonAction = {
                    () in
                    next.beginTime = "请假"
                    next.beginTime = "请假"
                    
                    self.model.list[count] = next
                }
                isAlert.toggle()
            }
        }
    }
    
    func qingjiaPM()  {
        
        let json = model.list.last
        let count = model.list.count - 1
        
        let currentDate = model.currentDate
        
        if !currentDate.contains(json?.date ?? "ppd") {
            
            let nextjson = DateModel(beginTime: "未打卡", endTime: nil, date: currentDate)
            self.model.list.append(nextjson)
        }else {
            var next = DateModel(beginTime: "请假", endTime: json?.endTime, date: json?.date)
            
            alertTitle = "今天下午请假"
            
            if json?.endTime?.contains("请假") == false {
                buttonAction = {
                    () in
                    next.endTime = "请假"
                    self.model.list[count] = next
                }
                isAlert.toggle()
            }
        }
        
    }
}

struct ButtonItems: View {
    private let listText = ["上班打卡","下班打卡"]
    
    @Binding var model: DateItemModel
    var finishedBlock: (_ tag: Int) -> Void
    
    
    var body: some View {
        HStack {
            
            ForEach(0..<listText.count) { index in
                self.createButton(index: index, title: self.listText[index])
            }
        }
    }
    
    func createButton(index: Int,title: String) -> some View {
        
        Button(action: { 
            self.finishedBlock(index)
        }) { 
            Text(title)
        }.padding()
    }
}





struct DateTimeItem: View {
    @Binding var model: DateModel
    let date: String
    
    
    
    var body: some View {
        VStack{
            HStack {
                Text(getCurrentDate()).foregroundColor(model.color).font(Font.system(size: 18, weight: .bold, design: .serif))
                Spacer()
                
            }.padding(.bottom, 12)
            
            HStack {
                Text(model.beginTimeValue)
                Spacer()
                Text(model.endTimeValue)
            }
        }
    }
    
    func getCurrentDate() -> String {
        if let sDate = model.dateWeek {
            return sDate
        }
        return date
    }
    
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView().environmentObject(DateItemModel())
        //        ContentView(isShowText: false, model: DateItemModel(), isAlert: false)
        
    }
}

