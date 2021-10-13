import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gtk_flutter/components/application_state.dart';
import 'package:gtk_flutter/components/authentication.dart';
import 'package:gtk_flutter/components/guest_book.dart';
import 'package:provider/provider.dart';

const String token = '';
const String appId = '8d98fb1cbd094508bff710b6a2d199ef';
const String channelName = 'test';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Project X'),
      ),
      child: Material(
        child: ListView(
          children: [
            Image.asset('assets/codelab.png'),
            const SizedBox(height: 8),
            Consumer<ApplicationState>(
              builder: (context, appState, _) => Authentication(
                email: appState.email,
                loginState: appState.loginState,
                startLoginFlow: appState.startLoginFlow,
                verifyEmail: appState.verifyEmail,
                signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
                cancelRegistration: appState.cancelRegistration,
                registerAccount: appState.registerAccount,
                signOut: appState.signOut,
              ),
            ),
            Consumer<ApplicationState>(
              builder: (context, appState, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (appState.loginState ==
                      ApplicationLoginState.loggedIn) ...[
                    Chat(
                      addMessage: (message) =>
                          appState.addMessageToGuestBook(message),
                      messages: appState.guestBookMessages,
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
