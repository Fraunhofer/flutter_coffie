import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

final GlobalKey<_CoffieWidgetState> key = GlobalKey<_CoffieWidgetState>();

class CoffieWidget extends StatefulWidget {
  StreamController<bool> isRecording = StreamController<bool>.broadcast();

  CoffieWidget() : super(key: key);

  @override
  _CoffieWidgetState createState() => _CoffieWidgetState();

  void record() {
    key.currentState.record();
  }

  void play() {
    key.currentState.play();
  }

  void remove() {
    key.currentState.remove();
  }

  Stream<bool> getStream() {
    return isRecording.stream;
  }

  dismiss() {
    isRecording.close();
  }
}

class _CoffieWidgetState extends State<CoffieWidget> with TickerProviderStateMixin {
  FlutterSound flutterSound = new FlutterSound();
  Record _save;
  Record _record;
  AnimationController _recController;
  bool _isRecording = false;
  Stopwatch drawTime = new Stopwatch();
  Stopwatch touchTime = new Stopwatch();
  int click = 0;

  @override
  void initState() {
    super.initState();
    _record = Record();

    _recController = new AnimationController(vsync: this, duration: Duration(seconds: 1));
    _recController.addListener(() {
      if (_recController.isCompleted)
        _recController.reverse();
      else if (_recController.isDismissed) _recController.forward();
    });

    widget.isRecording.sink.add(_isRecording);
  }

  @override
  void dispose() {
    super.dispose();
    widget.dismiss();
  }

  void record() {
    setState(() {
      if (_isRecording) {
        flutterSound.stopRecorder().then((String result){
          print(result);
          _isRecording = false;
          widget.isRecording.sink.add(_isRecording);
          _recController.reset();
          _recController.stop(canceled: true);
          _save = _record.clone();
          _record = Record();
        });
      } else {
        flutterSound.startRecorder(null).then((String path){
          print(path);
          _isRecording = true;
          widget.isRecording.sink.add(_isRecording);
          _recController.forward();
          _record = Record();
        });
      }
    });
  }

  void play() {
    if(_save == null)
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('Kayıt Yok', textAlign: TextAlign.center,),));
    else{
      setState(() {
        _record = Record();
      });

      flutterSound.startPlayer(null).then((String path){
        showFrame(points: _save.getPoints, times: _save.getTimes, click: _save.getClick);
      });
    }
  }

  void showFrame({List<Offset> points, List<int> times, List<int> click}){
    print(times);
    print(click);

    Future.delayed(Duration(milliseconds: times.removeAt(0)), (){
      int _click = click.removeAt(0);
      int totalTime = times.removeAt(0);
      double time = totalTime / _click;

      for(int i = 0; i < _click ; i++){
        Future.delayed(Duration(milliseconds: (time * i).toInt()), (){
          setState(() {
            _record.points = new List.from(_record.points)..add(points.removeAt(0));
          });
        });
      }

      Future.delayed(Duration(milliseconds: totalTime), (){
        print('new Frame');
        showFrame(points: points, times: times, click: click);
      });

    });
  }

  void remove() {}

  @override
  Widget build(BuildContext context) {
    Image image = Image.asset('assets/image.jpg');
    Completer<ui.Image> completer = Completer<ui.Image>();
    image.image.resolve(ImageConfiguration()).addListener((ImageInfo info, bool _) => completer.complete(info.image));

    return FutureBuilder<ui.Image>(
      future: completer.future,
      builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(),
          );

        Size widgetSize = (key.currentContext.findRenderObject() as RenderBox).size;
        Size imageSize = Size(snapshot.data.width.toDouble(), snapshot.data.height.toDouble());
        double scale = math.min(imageSize.width, imageSize.height) / math.max(imageSize.width, imageSize.height);


        widget.getStream().listen((bool isRecording){
          if(isRecording)
            touchTime.start();
          else{
            drawTime.stop();
            touchTime.stop();
          }
        });

        return Stack(
          children: <Widget>[
            Container(color: Colors.black),
            Align(
              alignment: Alignment.center,
              child: Image.asset('assets/image.jpg', fit: BoxFit.scaleDown),
            ),
            Align(
              alignment: Alignment.topRight,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _recController, curve: Interval(0, 1)),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.only(right: 10, top: 10),
                ),
              ),
            ),
            Container(
              width: widgetSize.width,
              height: widgetSize.height,
              child: new GestureDetector(
                onPanUpdate: (DragUpdateDetails details) {
                  if (_isRecording) {
                    if(touchTime.isRunning){
                      _record.times.add(touchTime.elapsedMilliseconds);
                      touchTime.stop();
                      drawTime.start();
                    }

                    setState(() {
                      RenderBox object = context.findRenderObject();
                      Offset _localPosition = Offset(
                        object.globalToLocal(details.globalPosition).dx > widgetSize.width ? widgetSize.width : object.globalToLocal(details.globalPosition).dx,
                        object.globalToLocal(details.globalPosition).dy > widgetSize.height
                            ? widgetSize.height
                            : object.globalToLocal(details.globalPosition).dy,
                      );
                      _record.points = new List.from(_record.points)..add(_localPosition);
                      click++;
                    });
                  }
                },
                onPanEnd: (DragEndDetails details) {
                  if (_isRecording) {
                    print('click $click' );
                    _record.points.add(null);
                    _record.times.add(drawTime.elapsedMilliseconds);
                    _record.click.add(click);
                    click = 0;
                    drawTime.stop();
                    touchTime.start();
                  }
                },
                child: new CustomPaint(
                  painter: new Signature(points: _record.points, thickness: 2),
                  size: Size.infinite,
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class Record {
  List<Offset> points = <Offset>[];
  List<int> click = [];
  List<int> times = [];

  Record clone() {
    Record rec = new Record();
    rec.points = points.map((_) => _).toList();
    rec.times = times.map((_) => _).toList();
    rec.click = click.map((_) => _).toList();

    return rec;
  }

  List<Offset> get getPoints => points.map((_) => _).toList();
  List<int> get getClick => click.map((_) => _).toList();
  List<int> get getTimes => times.map((_) => _).toList();
}

class Signature extends CustomPainter {
  double thickness;
  List<Offset> points;

  Signature({this.points, this.thickness = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => oldDelegate.points != points;
}
