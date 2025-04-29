import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/services/firestore_service.dart';

class ListifyWidgetManager {
  static String _appGroupId = 'GroupId1'; // Add from here
  static String _iOSWidgetName = 'NewsWidgets';
  static String _androidWidgetName = 'ListifyWidget';
  static final fireStore = FirestoreService();

  static updateHeadline(BuyList newHeadline) {
    // Add from here
    var buylist = fireStore.getBuyLists();
    buylist.listen((onData) {
      print("avant home update");
      HomeWidget.saveWidgetData<String>(
        "names",
        jsonEncode(
          onData
              .map(
                (toElement) => {
                  'name': toElement.name,
                  'description': toElement.description,
                },
              )
              .toList(),
        ),
      );
      print("apres home update");

      HomeWidget.updateWidget(androidName: _androidWidgetName);
    });

    // Save the headline data to the widget

    // HomeWidget.updateWidget(androidName: _androidWidgetName);
  } //

  static setGroupId() {
    HomeWidget.setAppGroupId(_appGroupId);
  } // To here.
}
