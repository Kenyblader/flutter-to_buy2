import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_buy/models/buy_item.dart';
import 'package:to_buy/models/buy_list.dart';
import 'package:to_buy/models/syncable.dart';
import 'package:to_buy/models/user.dart';
import 'package:to_buy/services/backendServices.dart';
import 'package:to_buy/services/sqligthServices.dart';

class SyncService {
  final DatabaseHelper sqliteService;
  final BackendServices nestService;

  // Paramètres de synchronisation
  final Duration syncInterval;
  bool isSyncActive = false;
  Timer? _syncTimer;

  // Tables à synchroniser et leur mappage avec des modèles
  final Map<String, Function(Map<String, dynamic>)> modelFactories = {
    'users': (json) => User.fromMap(json),
    'lists': (json) => BuyList.fromJson(json),
    'items': (json) => BuyItem.fromMap(json),
  };

  SyncService({
    required this.sqliteService,
    required this.nestService,
    this.syncInterval = const Duration(minutes: 15),
  }) {
    // Initialiser l'écoute des changements de connectivité
  }

  // Démarrer les synchronisations périodiques
  void startPeriodicSync() {
    if (_syncTimer != null) return;

    isSyncActive = true;
    _syncTimer = Timer.periodic(syncInterval, (_) => syncAll());
  }

  // Arrêter les synchronisations périodiques
  void stopPeriodicSync() {
    isSyncActive = false;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Synchroniser toutes les tables
  Future<void> syncAll() async {
    try {
      // Vérifier la connectivité

      // Pour chaque table à synchroniser
      for (String table in modelFactories.keys) {
        print("synchorinsation de la table $table");
        await _syncTable(table);
      }

      // Mettre à jour la date de dernière synchronisation
      await _updateLastSyncTime();
    } catch (e) {
      print('Error during synchronization: $e');
    }
  }

  // Synchroniser une table spécifique
  Future<void> _syncTable(String table) async {
    try {
      // 1. Pousser les modifications locales vers le serveur
      await _pushLocalChanges(table);

      // 2. Récupérer les modifications du serveur
      await _pullRemoteChanges(table);
    } catch (e, st) {
      print('Error syncing table $table: $e');
      print('stack trace: $st');
    }
  }

  // Envoyer les modifications locales au serveur
  Future<void> _pushLocalChanges(String table) async {
    // Récupérer les changements locaux en attente
    List<Map<String, dynamic>> pendingChanges = await sqliteService
        .getPendingChanges(table);

    if (pendingChanges.isEmpty) return;

    try {
      // Envoyer les changements en lot
      await nestService.pushChanges(table, pendingChanges);

      // Marquer les éléments comme synchronisés
      for (var change in pendingChanges) {
        await sqliteService.markAsSynced(table, change['id']);
      }
    } catch (e) {
      print('Error pushing changes for $table: $e');
      // Ici, vous pouvez implémenter une logique de retry ou de notification
    }
  }

  // Récupérer les modifications du serveur
  Future<void> _pullRemoteChanges(String table) async {
    try {
      // Récupérer la date de dernière synchronisation
      DateTime lastSyncTime = await _getLastSyncTime();

      // Récupérer les changements du serveur depuis la dernière synchronisation
      List<Map<String, dynamic>> remoteChanges = await nestService.getChanges(
        table,
        lastSyncTime,
      );

      // Traiter chaque changement
      for (var remoteChange in remoteChanges) {
        await _processRemoteChange(table, remoteChange);
      }
    } catch (e) {
      print('Error pulling changes for $table: $e');
    }
  }

  // Traiter un changement distant
  Future<void> _processRemoteChange(
    String table,
    Map<String, dynamic> remoteChange,
  ) async {
    String id = remoteChange['id'];

    // Vérifier si l'élément existe déjà localement
    Map<String, dynamic>? localData = await sqliteService.getById(table, id);

    if (localData == null) {
      // Si l'élément n'existe pas localement, l'ajouter
      remoteChange['sync_status'] = 'synced';
      await sqliteService.insert(table, remoteChange);
    } else {
      // Si l'élément existe localement, vérifier les conflits
      DateTime localModified = DateTime.parse(localData['last_modified']);
      DateTime remoteModified = DateTime.parse(remoteChange['last_modified']);

      if (localData['sync_status'] == 'pending') {
        // Si l'élément local est en attente de synchronisation, il y a un conflit potentiel
        Syncable localModel = modelFactories[table]!(localData);
        Syncable remoteModel = modelFactories[table]!(remoteChange);

        if (localModel.hasConflictWith(remoteModel)) {
          // Marquer comme conflit pour une résolution manuelle
          await sqliteService.markAsConflict(table, id);
        } else if (remoteModified.isAfter(localModified)) {
          // La version distante est plus récente, l'appliquer
          remoteChange['sync_status'] = 'synced';
          await sqliteService.update(table, remoteChange);
        }
      } else {
        // Si l'élément local est synchronisé ou en conflit, mettre à jour s'il est plus ancien
        if (remoteModified.isAfter(localModified)) {
          remoteChange['sync_status'] = 'synced';
          await sqliteService.update(table, remoteChange);
        }
      }
    }
  }

  // Récupérer la date de dernière synchronisation
  Future<DateTime> _getLastSyncTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastSyncStr = prefs.getString('last_sync_time');

    if (lastSyncStr == null) {
      // Si pas de synchronisation précédente, utiliser une date très ancienne
      return DateTime(2000);
    }

    return DateTime.parse(lastSyncStr);
  }

  // Mettre à jour la date de dernière synchronisation
  Future<void> _updateLastSyncTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
  }

  // Résoudre manuellement un conflit
  Future<void> resolveConflict(
    String table,
    String id,
    Map<String, dynamic> resolvedData,
  ) async {
    // Mettre à jour localement
    resolvedData['sync_status'] = 'pending';
    resolvedData['last_modified'] = DateTime.now().toIso8601String();

    await sqliteService.update(table, resolvedData);

    // Déclencher une synchronisation pour envoyer la résolution
    await _pushLocalChanges(table);
  }
}
