import 'package:flutter/material.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class SoundpoolInitializer extends StatefulWidget {
  @override
  _SoundpoolInitializerState createState() => _SoundpoolInitializerState();
}

class _SoundpoolInitializerState extends State<SoundpoolInitializer> {
  Soundpool _pool;
  Soundpool pool;
  SoundpoolOptions _soundpoolOptions = SoundpoolOptions();

  @override
  void initState() {
    pj();
    super.initState();
    if (!kIsWeb) {
      pj();
      _initPool(_soundpoolOptions);
    }
  }
  pj()async{
    int soundId = await rootBundle.load("res/audio/audioo.mpeg").then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);}
  @override
  Widget build(BuildContext context) {
    if (_pool == null) {
      return Material(
        child: Center(
          child: ElevatedButton(
            onPressed: () => _initPool(_soundpoolOptions),
            child: Text("Init Soundpool"),
          ),
        ),
      );
    } else {
      return SimpleApp(
        pool: _pool,
        onOptionsChange: _initPool,
      );
    }
  }

  void _initPool(SoundpoolOptions soundpoolOptions) {
    _pool?.dispose();
    setState(() {
      _soundpoolOptions = soundpoolOptions;
      _pool = Soundpool.fromOptions(options: _soundpoolOptions);
      print('pool updated: $_pool');
    });
  }
}

class SimpleApp extends StatefulWidget {
  final Soundpool pool;
  final ValueSetter<SoundpoolOptions> onOptionsChange;
  SimpleApp({Key key,  this.pool,  this.onOptionsChange})
      : super(key: key);

  @override
  _SimpleAppState createState() => _SimpleAppState();
}

class _SimpleAppState extends State<SimpleApp> {
  int _alarmSoundStreamId;
  int _cheeringStreamId = -1;

  String get _cheeringUrl => kIsWeb
      ? 'res/audio/audioo.mpeg'
      : 'https://raw.githubusercontent.com/ukasz123/soundpool/feature/web_support/example/web/c-c-1.mp3';

  Soundpool get _soundpool => widget.pool;

  void initState() {
    super.initState();

    _loadSounds();
  }

  void _loadSounds() {
    _cheeringId = _loadCheering();
  }

  @override
  void didUpdateWidget(SimpleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pool != widget.pool) {
      _loadSounds();
    }
  }

  double _volume = 1.0;
  double _rate = 1.0;
   Future<int> _soundId;
   Future<int> _cheeringId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: kIsWeb ? 450 : double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _playCheering,
                child: Text("Play cheering"),
              ),


            ],
          ),
        ),
      ),
    );
  }
  Future<int> _loadCheering() async {
    return await _soundpool.loadUri("res/audio/audioo.mpeg");
  }

  Future<void> _playCheering() async {
    var _sound = await _cheeringId;
    _cheeringStreamId = await _soundpool.play(
      _sound,
      repeat: 100,
      rate: 0.5,
    );
  }


}