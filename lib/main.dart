import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_model.dart';
import 'firebase_options.dart';
import 'fork_lobby.dart';
import 'game_model.dart';
import 'game_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  String appName = "Forkball";
  ZugUtils.getIniDefaults("defaults.ini").then((defaults) {
    ZugUtils.getPrefs().then((prefs) {
      String domain = defaults["domain"] ?? "localhost";
      int port = int.parse(defaults["port"] ?? "6789");
      String endPoint = defaults["endpoint"] ?? "zugballsrv";
      bool localServer = bool.parse(defaults["localServer"] ?? "true");
      log("Starting $appName Client, domain: $domain, port: $port, endpoint: $endPoint, localServer: $localServer");
      GameModel model = GameModel(domain,port,endPoint,prefs,
          firebaseOptions: DefaultFirebaseOptions.web,
          localServer : localServer,showServMess : false, javalinServer: true);
      runApp(GameApp(model,appName));
    });
  });
}

class GameApp extends ZugApp {
  GameApp(super.model, super.appName,
      {super.key,
        super.splashLandscapeImgPath = "images/forksplash.gif",
        super.splashPortraitImgPath = "images/forksplash.gif",
        super.logLevel = Level.INFO, super.noNav = false, super.isDark = true});

  @override
  Widget createLobbyPage(ZugModel model) => ForkLobby(model, zugChat: ZugChat(model));

  @override
  Widget createMainPage(model) => GamePage(model as GameModel);

}


