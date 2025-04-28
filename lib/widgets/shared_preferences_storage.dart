import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class SharedPreferencesStorage{
  static Future< String? > setValue( String key, String value) async {
    /// Définir le nom du canal sur l'ID du bundle d'applications
    const platformChannel =
    MethodChannel( 'ListifyStorageWidget' );

    try {
      /// Appeler la méthode pour enregistrer les préférences côté natif
      final result = await platformChannel.invokeMethod( 'savePreferences' , {
        'key' : key,
        'value' : value,
      });

      return result;
    } catch (err) {
      debugPrint( 'Error $err ' );
      return  null ;
    }
  }
}