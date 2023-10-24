import 'dart:convert';
import 'dart:math';
import 'package:chess_bot/apiconstant.dart';
import 'package:chess_bot/test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart ' as http;
import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess_sub;
import 'package:chess_bot/generated/i18n.dart';
import 'package:chess_bot/routing/routing.dart';
import 'package:chess_bot/util/online_game_utils.dart';
import 'package:chess_bot/util/utils.dart';
import 'package:chess_bot/util/widget_utils.dart';
import 'package:chess_bot/widgets/divider.dart';
import 'package:chess_bot/widgets/fancy_button.dart';
import 'package:chess_bot/widgets/fancy_options.dart';
import 'package:chess_bot/widgets/modal_progress_hud.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chess_board/chess.dart';
import 'chess_board/src/chess_board.dart';
import 'chess_control/chess_controller.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:beamer/beamer.dart';



S strings;
ChessController _chessController;
OnlineGameController _onlineGameController;
SharedPreferences prefs;
String uuid;
String uid;
String oid;

void main() async {
  setPathUrlStrategy();
  MyRoutes.setupRouter();

  //ensure binding to native code
  WidgetsFlutterBinding.ensureInitialized();

  // setPathUrlStrategy();
  //run the app
  runApp(MyApp());
  //init firebase app
  Firebase.initializeApp();
  //add all licenses
  addLicenses();
}

class MyApp extends StatelessWidget {

  final routerDelegate = BeamerDelegate(
    locationBuilder: BeamerLocationBuilder(
      beamLocations: [BooksLocation()],
    ),
    notFoundRedirectNamed: '/books',
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //set fullscreen
    SystemChrome.setEnabledSystemUIOverlays([]);
    //and portrait only
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    //create the material app
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerDelegate: routerDelegate,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
        supportedLocales: S.delegate.supportedLocales,

      routeInformationParser: BeamerParser(),
      backButtonDispatcher:
      BeamerBackButtonDispatcher(delegate: routerDelegate),
    );

    //   MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   localizationsDelegates: [
    //     S.delegate,
    //     GlobalMaterialLocalizations.delegate,
    //     GlobalWidgetsLocalizations.delegate,
    //   ],
    //   supportedLocales: S.delegate.supportedLocales,
    //   //define title etc.
    //   title: app_name,
    //   theme: ThemeData(
    //     primarySwatch: Colors.indigo,
    //     visualDensity: VisualDensity.adaptivePlatformDensity,
    //   ),
    //   // home: SoundpoolInitializer()
    //   // MyHomePage(),
    //   // initialRoute: '/',
    //   // initialRoute: '/MyHomePage/1/2/3/12345',
    //   // onGenerateRoute: MyRoutes.router.generator,
    //
    // );
  }
}
class BooksLocation extends BeamLocation<BeamState> {
  @override
  List<Pattern> get pathPatterns => ['/match/:id/'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) {
    final pages = [
      const BeamPage(
        key: ValueKey('home'),
        title: 'Home',
        child: MyHomePage(),
      ),
    ];
    final String id = state.pathParameters['id'];
    // final String oid = state.pathParameters['oid'];
    // final String type = state.pathParameters['type'];
    // final String roomcode = state.pathParameters['roomcode'];
    if (id != null) {
      // final bookId = int.tryParse(bookIdParameter);
      // final book = books.firstWhereOrNull((book) => book.id == bookId);
      pages.add(
        BeamPage(
          key: ValueKey('book-$id'),
          title: 'Book #$id',
          child: MyHomePage(id: id),
        ),
      );
    }
    return pages;
  }
}

class MyHomePage extends StatefulWidget {
  // final String id;
  // final String oid;
  // final String type;
  // final String roomcode;
  // MyHomePage({Key key, this.id, this.oid, this.type, this.roomcode,}) : super(key: key);
  const MyHomePage({Key key, this.id, this.oid, this.type, this.roomcode,}) : super(key: key);

  final String id;
  final String oid;
  final String type;
  final String roomcode;

  @override
  _MyHomepageState createState() => _MyHomepageState();
}

class _MyHomepageState extends State<MyHomePage> {
  Future<void> _loadEverythingUp() async {



    //load the old game
    await _chessController.loadOldGame();
    //set the king in chess board
    _chessController.setKingInCheckSquare();
    //await prefs
    prefs = await SharedPreferences.getInstance();
    //load values from prefs

    //the chess controller has already been set here!
    _chessController.botColor =
        chess_sub.Color.fromInt(prefs.getInt('bot_color') ?? 1);
    _chessController.whiteSideTowardsUser =
        prefs.getBool('whiteSideTowardsUser') ?? true;
    _chessController.botBattle = prefs.getBool('botbattle') ?? false;
    //load user id and if not available create and save one


    uuid = prefs.getString('uid');
    uid = prefs.getString('uid');
    oid = prefs.getString('oid');
    if (uuid == null) {
      prefs.setString('uid', widget.id);
      prefs.setString('oid', widget.oid);
    }
  }

  // Sound(String sound)async{
  //   await _player.load(sound);
  //   //.play(sound);
  // }
  // final AudioCache  _player = AudioCache(fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP),
  // );

  @override
  Widget build(BuildContext context) {
    print(widget.id);
    print(widget.oid);
    print(widget.type);
    print(widget.roomcode);
    //set strings object
    strings ??= S.of(context);
    //init the context singleton object
    ContextSingleton(context);
    //build the chess controller,
    //if needed set context newly
    if (_chessController == null)
      _chessController = ChessController(context);
    else
      _chessController.context = context;
    //create the online game controller if is null
    _onlineGameController ??= OnlineGameController(_chessController);
    //future builder: load old screen and show here on start the loading screen,
    //when the future is finished,
    //with setState show the real scaffold
    //return the view
    return
      // (_chessController.game == null)
      //   ?
    FutureBuilder(
            future: _loadEverythingUp(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  var error = snapshot.error;
                  print('$error');
                  return Center(child: Text(strings.error));
                }

                return MyHomePageAfterLoading(id:widget.id,oid:widget.oid, type:widget.type, roomcode:widget.roomcode);
              } else {
                return Center(
                    child: ModalProgressHUD(
                  child: Container(),
                  inAsyncCall: true,
                ));
              }
            },
          );
        // : MyHomePageAfterLoading();
  }
}

class MyHomePageAfterLoading extends StatefulWidget {
  final String id;
  final String oid;
  final String type;
  final String roomcode;

  MyHomePageAfterLoading({Key key, this.id, this.oid, this.type, this.roomcode, }) : super(key: key);

  @override
  _MyHomePageAfterLoadingState createState() => _MyHomePageAfterLoadingState();
}

class _MyHomePageAfterLoadingState extends State<MyHomePageAfterLoading>
    with WidgetsBindingObserver {

  @override
  void initState() {

    // final FlutterSoundPlayer _soundPlayer = FlutterSoundPlayer();
    checkPlayer();
    super.initState();
    prefs.setBool('bot', true);

    viewprofile();


    WidgetsBinding.instance.addObserver(this);
    changecolor();
  }

  // // String filePath= "res/audio/audioo.mpeg";
  // // void startPlayback() async {
  // //   print("aaaaaaaa");
  // //   FlutterSound flutterSound = FlutterSound();
  // //   await flutterSound.startPlayer("res/audio/audioo.mpeg");
  // //   print(flutterSound.startPlayer("res/audio/audioo.mpeg"));
  // // }
  //
  // Future<void> _loadAndPlayAudio() async {
  //   final FlutterSound _soundPlayer = FlutterSound();
  //   try {
  //     // Replace 'audio_url' with the actual URL of the audio file you want to play
  //     String audioUrl = 'https://example.com/audio.mp3';
  //
  //     // Start playing the audio
  //     await _soundPlayer.startPlayer(
  //       fromURI: audioUrl,
  //       codec: Codec.mp3,
  //     );
  //   } catch (e) {
  //     print('Error loading audio: $e');
  //   }
  // }

  

  checkPlayer() {
    print("cond run");
    if(widget.oid == '0'){
      prefs.setBool('bot', true);
    }
    else{
      // currentGameDoc();
          // return FirebaseFirestore.instance.collection('games').doc("SAHILJ");
        // return FirebaseFirestore.instance.collection('games').doc(_currentGameCode);


      // createRoomCode();
    }
  }

  DocumentReference get currentGameDoc {
    if (inOnlineGame)
      return FirebaseFirestore.instance.collection('games').doc("ASHUTO");
    // return FirebaseFirestore.instance.collection('games').doc(_currentGameCode);
    else
      return null;
  }

  changecolor(){
    print(widget.type);
    if(widget.type==2){
      setState(() {
        _chessController.switchColors;
      });

    }
    else{
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _chessController.saveOldGame();
        break;
      default:
        break;
    }
  }

  void update() {
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    _chessController.saveOldGame();
    return true;
  }

  void _onAbout() async {
    //show the about dialog
    showAboutDialog(
      context: context,
      applicationVersion: version,
      applicationIcon: Image.asset(
        'res/drawable/ic_launcher.png',
        width: 50,
        height: 50,
      ),
      applicationLegalese: await rootBundle.loadString('res/licenses/this'),
      children: [
        FancyButton(
          onPressed: () => launch(strings.privacy_url),
          text: strings.privacy_title,
        )
      ],
    );
  }

  void _onWarning() {
    showAnimatedDialog(
        title: strings.warning,
        forceCancelText: 'no',
        onDoneText: 'yes',
        icon: Icons.warning,
        onDone: (value) {},
        children: [Image.asset('res/drawable/moo.png')]);
  }

  void _onJoinCode() {
    //dialog to enter a code
    showAnimatedDialog(
        title: strings.enter_game_id,
        onDoneText: strings.join,
        icon: Icons.transit_enterexit,
        withInputField: true,
        inputFieldHint: strings.game_id_ex,
        onDone: (value) {
          _onlineGameController.joinGame(value);
        });
  }

  void _onCreateCode() {
    //if is currently in a game, this will disconnect from all local games, reset the board and create a firestore document
    showAnimatedDialog(
      title: strings.warning,
      text: strings.game_reset_join_code_warning,
      onDoneText: strings.proceed,
      icon: Icons.warning,
      onDone: (value) {
        if (value == 'ok') _onlineGameController.finallyCreateGameCode();
      },
    );
  }

  void _onLeaveOnlineGame() {
    //show dialog to leave the online game
    showAnimatedDialog(
      title: strings.leave_online_game,
      text: strings.deleting_as_host_info,
      icon: Icons.warning,
      onDoneText: strings.ok,
      onDone: (value) {
        if (value == 'ok') _onlineGameController.leaveGame();
        print(currentGameCode);

      },
    );
    createRoomCode();
  }

  // Future<void> _deleteCacheDir() async {
  //   var tempDir = await getTemporaryDirectory();
  //
  //   if (tempDir.existsSync()) {
  //     tempDir.deleteSync(recursive: true);
  //   }
  // }
  //
  // Future<void> _deleteAppDir() async {
  //   var appDocDir = await getApplicationDocumentsDirectory();
  //
  //   if (appDocDir.existsSync()) {
  //     appDocDir.deleteSync(recursive: true);
  //   }
  // }
  createRoomCode() async {
    // _onlineGameController.finallyCreateGameCode();
    // _onCreateCode();
    print("code  insert api hit");
    print(currentGameCode);
    print(uuid);
    print('https://apponrent.co.in/chess/api/createrooms.php?uuid=$uuid&roomid=$currentGameCode&levelid=1');
    final res= await http.get(
        Uri.parse('https://apponrent.co.in/chess/api/createrooms.php?uuid=19&roomid=$currentGameCode&levelid=1'));
    final data=json.decode(res.body);
    // Share.share("RealmoneyChess ♟\nReferral code:$roomcode please join as soon as possible we are waiting for you !!!",);
    print(data);
  }

  @override
  Widget build(BuildContext context) {
    prefs.setString('uid', widget.id.toString());
    prefs.setString('oid', widget.oid.toString());
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    //get the available height for the chess board
    double availableHeight = MediaQuery.of(context).size.height - 184.3;
    //set the update method
    _chessController.update = update;
    //set the update method in the online game controller
    _onlineGameController.update = update;
    //the default scaffold
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ModalProgressHUD(
        inAsyncCall: ChessController.loadingBotMoves,
        progressIndicator: kIsWeb
            ? Text(
          '',
                // strings.loading_moves_web,
                style: Theme.of(context).textTheme.subtitle2,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Text(
                    strings.moves_done(_chessController.progress),
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ],
              ),
        child: SafeArea(
          child: Scaffold(
            // backgroundColor: Colors.brown[50],
            backgroundColor: Colors.white,
            body: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image:AssetImage("res/chess_board/bgimg.jpg"),
                    fit: BoxFit.cover
                  )
              ),
              child: Stack(
                children: [
                  // Positioned(
                  //     top:5, left:25,
                  //     child: Text(widget.id.toString(), style:TextStyle(color:Colors.white))),
                  // Positioned(
                  //     top:15, left:25,
                  //
                  //     child: Text(widget.oid.toString(), style:TextStyle(color:Colors.white))),
                  Column(
                    children: [

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Visibility(
                                visible: !inOnlineGame,
                                child: Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    map==null?Container(
                                      height: height*0.1,
                                      width: width*0.12,
                                      // padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        // color: Colors.yellow,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: Colors.white)
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                            height:  height/15,
                                            width:  height/15,
                                            decoration: BoxDecoration(
                                              // color: Colors.yellow,
                                                borderRadius: BorderRadius.circular(5),
                                                gradient: LinearGradient(
                                                    colors: [Color(0xff49001e),Color(0xff1F1C18)],
                                                    end: Alignment.bottomCenter,
                                                    begin: Alignment.topCenter

                                                ),
                                                border: Border.all(color: Colors.yellow,width: 2)
                                            ),
                                            child: Center(child: Icon(Icons.person, color: Colors.grey, size: 35,))),
                                        title: Text("Guest",
                                          style: TextStyle(color: Colors.white,fontSize: 15),),
                                        subtitle: Text('kkbk',
                                          style: TextStyle(color: Colors.white,fontSize: 15),),
                                      ),
                                    ):
                                    map["image"]==null?Container(
                                      height: height*0.1,
                                      width: width*0.12,
                                      // padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        // color: Colors.yellow,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: Colors.white)
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                            height:  height/15,
                                            width:  height/15,
                                            decoration: BoxDecoration(
                                              // color: Colors.yellow,
                                                borderRadius: BorderRadius.circular(5),
                                                gradient: LinearGradient(
                                                    colors: [Color(0xff49001e),Color(0xff1F1C18)],
                                                    end: Alignment.bottomCenter,
                                                    begin: Alignment.topCenter

                                                ),
                                                border: Border.all(color: Colors.yellow,width: 2)
                                            ),
                                            child: Center(child: Icon(Icons.person, color: Colors.grey, size: 35,))),
                                        title: Text("Guest",
                                          style: TextStyle(color: Colors.white,fontSize: 15),),
                                        subtitle: Text('kkbk',
                                          style: TextStyle(color: Colors.white,fontSize: 15),),
                                      ),
                                    ):
                                    Container(
                                      height: height*0.1,
                                      width: width*0.12,
                                      decoration: BoxDecoration(
                                        // color: Colors.yellow,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: Colors.white)
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                            height:  height/15,
                                            width:  height/15,
                                            decoration: BoxDecoration(
                                              // color: Colors.yellow,
                                                borderRadius: BorderRadius.circular(5),
                                                gradient: LinearGradient(
                                                    colors: [Color(0xff49001e),Color(0xff1F1C18)],
                                                    end: Alignment.bottomCenter,
                                                    begin: Alignment.topCenter

                                                ),
                                                border: Border.all(color: Colors.yellow,width: 2)
                                            ),
                                            child: Center(child: Image.network(Apiconst.Imageurl+map["image"]))),
                                        title: Text(map['fullname']==null?'':map['fullname'].toString(),
                                          style: TextStyle(color: Colors.white,fontSize: 15),),
                                        subtitle: Text('kkbk',style: TextStyle(color: Colors.white,fontSize: 15),),
                                      ),
                                    ),
                                    Container(
                                        height: height*0.08,
                                        width: width*0.12,
                                      padding: EdgeInsets.only(left: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              colors: [Colors.pink,Colors.red],
                                              end: Alignment.bottomCenter,
                                              begin: Alignment.topCenter

                                          ),
                                        border: Border.all(color: Colors.white,width: 2),
                                        borderRadius: BorderRadius.all(Radius.circular(30),
                                       ),
                                        // border: Border(
                                        //   top: BorderSide(
                                        //     color: Color(0xff6ae792),
                                        //     width: 3.0,
                                        //   ),
                                        //   bottom: BorderSide(
                                        //     color: Color(0xff6ae792),
                                        //     width: 3.0,
                                        //   ),
                                        // ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text("🏆",style: TextStyle(color: Color(0xffffdf00),
                                              fontSize: 18,fontWeight: FontWeight.w600),),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: Row(
                                              children: [
                                                Text("Prize: ",
                                                  style: TextStyle(color: Color(0xffffdf00),
                                                      fontSize: width*0.013,fontWeight: FontWeight.w600),
                                                ),
                                                Text(" ₹0.0",style: TextStyle(color: Colors.white,
                                                    fontSize: width*0.013,fontWeight: FontWeight.w600))
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    ),

                                    Container(
                                      height: height*0.1,
                                      width: width*0.12,
                                      // padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          // color: Colors.yellow,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: Colors.white)
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                            height:  height/15,
                                            width:  height/15,
                                            decoration: BoxDecoration(
                                              // color: Colors.yellow,
                                                borderRadius: BorderRadius.circular(5),
                                                gradient: LinearGradient(
                                                    colors: [Color(0xff49001e),Color(0xff1F1C18)],
                                                    end: Alignment.bottomCenter,
                                                    begin: Alignment.topCenter

                                                ),
                                                border: Border.all(color: Colors.yellow,width: 2)
                                            ),
                                            child: Center(child: Icon(Icons.person, color: Colors.grey, size: 35,))),
                                        title: Text("Guest",
                                          style: TextStyle(color: Colors.white,fontSize: width*0.013),),
                                        subtitle: Text('kkbk',
                                          style: TextStyle(color: Colors.white,fontSize: width*0.013),),
                                      ),
                                    ),
                                   // FlatButton(
                                   //    shape: roundButtonShape,
                                   //    onPressed: () {
                                   //      //inverse the bot color and save it
                                   //      _chessController.botColor =
                                   //          chess_sub.Color.flip(
                                   //              _chessController.botColor);
                                   //      //save value int to prefs
                                   //      prefs.setInt('bot_color',
                                   //          _chessController.botColor.value);
                                   //      //set state, update the views
                                   //      setState(() {});
                                   //      //make move if needed
                                   //      _chessController.makeBotMoveIfRequired();
                                   //    },
                                   //    child:
                                   //    Text(
                                   //        (_chessController.botColor ==
                                   //                chess_sub.Color.WHITE)
                                   //            ? strings.white
                                   //            : strings.black,
                                   //        style:
                                   //            Theme.of(context).textTheme.button,
                                   //    ),
                                   //  ),
                                   //  SizedBox(
                                   //    width: 8,
                                   //  ),
                                   //  LiteRollingSwitch(
                                   //    value: (prefs?.getBool("bot") ?? true),//false
                                   //    onChanged: (pos) {
                                   //      prefs.setBool("bot", pos);
                                   //      //make move if needed
                                   //      _chessController?.makeBotMoveIfRequired();
                                   //    },
                                   //    // iconOn: Icons.done,
                                   //    // iconOff: Icons.close,
                                   //    // textOff: strings.bot_off,
                                   //    // textOn: strings.bot_on,
                                   //    colorOff: Colors.black,
                                   //    colorOn: Colors.black,
                                   //  ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right:8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SelectableText(
                                    currentGameCode,
                                    style: TextStyle(
                                      color:Colors.white
                                    ),
                                  ),
                                  Text(
                                      strings.turn_of_x(
                                          (_chessController?.game?.game?.turn ==
                                                  chess_sub.Color.BLACK)
                                              ? strings.black
                                              : strings.white),
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1
                                          .copyWith(
                                            inherit: true,
                                            color: (_chessController?.game
                                                        ?.in_check() ??
                                                    false)
                                                ? ((_chessController.game
                                                        .inCheckmate(
                                                            _chessController.game
                                                                .moveCountIsZero()))
                                                    ? Colors.purple
                                                    : Colors.red)
                                                : Colors.white,
                                          )),
                                ],
                              ),
                            ),
                            //
                            Center(
                              // Center is a layout widget. It takes a single child and positions it
                              // in the middle of the parent.
                              child: SafeArea(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      // image: DecorationImage(
                                      //     image:AssetImage("res/chess_board/chessboard_frame.png")
                                      // )
                                  ),
                                  child: ChessBoard(
                                    boardType: boardTypeFromString(
                                        prefs.getString('board_style') ?? 'd'),
                                    size: min(MediaQuery.of(context).size.width,
                                        availableHeight),
                                    onCheckMate: _chessController.onCheckMate,
                                    onDraw: _chessController.onDraw,
                                    onMove: _chessController.onMove,
                                    onCheck: _chessController.onCheck,
                                    chessBoardController:
                                        _chessController.controller,
                                    chess: _chessController.game,
                                    whiteSideTowardsUser:
                                        _chessController.whiteSideTowardsUser,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                  // GestureDetector(
                  //   onTap: () {
                  //     collapseFancyOptions = true;
                  //     setState(() {});
                  //   },
                  //   child: Container(
                  //     width: MediaQuery.of(context).size.width,
                  //     height: MediaQuery.of(context).size.height,
                  //     child: Align(
                  //       alignment: Alignment.bottomCenter,
                  //       child: Column(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Padding(
                  //             padding: const EdgeInsets.all(8.0),
                  //             child: SingleChildScrollView(
                  //               scrollDirection: Axis.horizontal,
                  //               child: Row(
                  //                 mainAxisSize: MainAxisSize.min,
                  //                 crossAxisAlignment: CrossAxisAlignment.end,
                  //                 children: [
                  //                   FancyOptions(
                  //                     up: true,
                  //                     rootIcon: Icons.online_prediction,
                  //                     rootText: strings.online_game_options,
                  //                     children: [
                  //                       FancyButton(
                  //                         onPressed: _onJoinCode,
                  //                         text: strings.join_code,
                  //                         icon: Icons.transit_enterexit,
                  //                         animation: FancyButtonAnimation.pulse,
                  //                       ),
                  //                       FancyButton(
                  //                         onPressed: _onCreateCode,
                  //                         text: strings.create_code,
                  //                         icon: Icons.add,
                  //                         animation: FancyButtonAnimation.pulse,
                  //                       ),
                  //                       FancyButton(
                  //                         text: strings.leave_online_game,
                  //                         animation: FancyButtonAnimation.pulse,
                  //                         icon: Icons.exit_to_app,
                  //                         visible: inOnlineGame,
                  //                         onPressed: _onLeaveOnlineGame,
                  //                       ),
                  //                     ],
                  //                   ),
                  //                   Divider8(),
                  //                   FancyButton(
                  //                     visible: !inOnlineGame,
                  //                     onPressed: _chessController.undo,
                  //                     animation: FancyButtonAnimation.pulse,
                  //                     icon: Icons.undo,
                  //                     text: strings.undo,
                  //                   ),
                  //                   DividerIfOffline(),
                  //                   FancyButton(
                  //                     onPressed: _chessController.resetBoard,
                  //                     icon: Icons.autorenew,
                  //                     text: strings.replay,
                  //                   ),
                  //                   Divider8(),
                  //                   FancyButton(
                  //                     visible: !inOnlineGame,
                  //                     onPressed: _chessController.switchColors,
                  //                     icon: Icons.switch_left,
                  //                     text: strings.switch_colors,
                  //                   ),
                  //                   DividerIfOffline(),
                  //                   FancyButton(
                  //                     visible: !inOnlineGame,
                  //                     onPressed: _chessController.onSetDepth,
                  //                     icon: Icons.upload_rounded,
                  //                     animation: FancyButtonAnimation.pulse,
                  //                     text: strings.difficulty,
                  //                   ),
                  //                   DividerIfOffline(),
                  //                   FancyButton(
                  //                     onPressed:
                  //                         _chessController.changeBoardStyle,
                  //                     icon: Icons.style,
                  //                     animation: FancyButtonAnimation.pulse,
                  //                     text: strings.choose_style,
                  //                   ),
                  //                   Divider8(),
                  //                   FancyButton(
                  //                     visible: !inOnlineGame,
                  //                     onPressed: _chessController.onFen,
                  //                     text: 'fen',
                  //                   ),
                  //                   DividerIfOffline(),
                  //                   Visibility(
                  //                     visible: !inOnlineGame,
                  //                     child: Container(
                  //                       width: 150,
                  //                       child: CheckboxListTile(
                  //                         shape: roundButtonShape,
                  //                         title: Text(strings.bot_vs_bot),
                  //                         value: _chessController.botBattle,
                  //                         onChanged: (value) {
                  //                           prefs.setBool('botbattle', value);
                  //                           _chessController.botBattle = value;
                  //                           setState(() {});
                  //                           //check if has to make bot move
                  //                           if (!_chessController
                  //                               .makeBotMoveIfRequired()) {
                  //                             //since move has not been made, inverse the bot color and retry
                  //                             _chessController.botColor =
                  //                                 Chess.swap_color(
                  //                                     _chessController.botColor);
                  //                             _chessController
                  //                                 .makeBotMoveIfRequired();
                  //                           }
                  //                         },
                  //                       ),
                  //                     ),
                  //                   ),
                  //                   DividerIfOffline(),
                  //                   FancyOptions(
                  //                     up: true,
                  //                     rootIcon: Icons.devices,
                  //                     rootText:
                  //                         strings.availability_other_devices,
                  //                     children: [
                  //                       FancyButton(
                  //                         onPressed: () =>
                  //                             launch(strings.playstore_url),
                  //                         text: strings.android,
                  //                         icon: Icons.android,
                  //                         animation: FancyButtonAnimation.pulse,
                  //                       ),
                  //                       FancyButton(
                  //                         onPressed: () =>
                  //                             launch(strings.website_url),
                  //                         text: strings.web,
                  //                         icon: Icons.web,
                  //                         animation: FancyButtonAnimation.pulse,
                  //                       ),
                  //                     ],
                  //                   ),
                  //                   Divider8(),
                  //                   FancyButton(
                  //                     onPressed: () =>
                  //                         (random.nextInt(80100) == 420)
                  //                             ? _onWarning()
                  //                             : _onAbout(),
                  //                     icon: Icons.info,
                  //                     animation: FancyButtonAnimation.pulse,
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  var map;
  viewprofile() async {
    print("😂😂😂😂😂");
    print(Apiconst.profile+"id=19");
    final prefs = await SharedPreferences.getInstance();
    final userid=widget.id;
    ///prefs.getString("userId");
    final response = await http.get(
      Uri.parse(Apiconst.profile+"id=19"),
    );
    var data = jsonDecode(response.body);
    print(data);
    print("mmmmmmmmmmmm");
    if (data["error"] == '200') {
      setState(() {
        map =data['data'];
      });
      print(map);
    }
  }
}

