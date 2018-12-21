import 'package:flutter/material.dart';
import 'package:coffie/draw_widget.dart';

void main() => runApp(new MaterialApp(
      home: new HomePage(),
      debugShowCheckedModeBanner: false,
    ));

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CoffieWidget _drawWidget;

  @override
  void initState() {
    super.initState();

    _drawWidget = new CoffieWidget();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(),
      body: Container(
        width: 250,
        height: 250,
        child: _drawWidget,
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new FloatingActionButton(
            child: StreamBuilder<bool>(
              stream: _drawWidget.getStream(),
              initialData: false,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
                return Icon(snapshot.data ? Icons.stop : Icons.fiber_manual_record, color: snapshot.data ? Colors.white : Colors.red);
              },
            ),
            onPressed: () => _drawWidget.record(),
          ),
          SizedBox(width: 10),
          new FloatingActionButton(
            child: new Icon(Icons.play_arrow),
            onPressed: () => _drawWidget.play(),
          ),
          SizedBox(width: 10),
          new FloatingActionButton(
            child: new Icon(Icons.clear),
            onPressed: () => _drawWidget.remove(),
          )
        ],
      ),
    );
  }
}

