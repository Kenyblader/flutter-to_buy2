import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';

class ListifyWidgetManager {
  static String _appGroupId = 'GroupId1';              // Add from here
  static String _iOSWidgetName = 'NewsWidgets';
  static String _androidWidgetName = 'ListifyWidget';
  static final fireStore=FirestoreService();
  

  static updateHeadline(BuyList newHeadline)  {
    // Add from here
    // var buylist=  fireStore.getBuyLists();
    // buylist.listen((onData){
    //   print("avant home update");
    //   HomeWidget.saveWidgetData<String>("names", jsonEncode(onData.map((toElement)=>toElement.toJson()).toList()));
    //   print("apres home update");
    //
    // });

    var buylist=[
      BuyList(name: "liste1", description: "description1",id: "1"),

      BuyList(name: "liste2", description: "description2",id: "2"),
    ];
print ('==========================================================================================');
    print("avant home update:${buylist[0].id}");

    HomeWidget.saveWidgetData<String>("names", jsonEncode(buylist.map((toElement)=>toElement.toJson()).toList()));

    // Save the headline data to the widget
    
    HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  } //

static setGroupId(){
    HomeWidget.setAppGroupId(_appGroupId);
}// To here.


}
