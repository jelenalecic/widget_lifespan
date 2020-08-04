import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(RootWidget());
}

class RootWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget lifespan',
      theme: ThemeData.light(),
      home: Material(child: MainScreen()),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  StreamController<int> _streamController;
  Timer refreshUiTimer;
  Timer sendToStreamTimer;
  int iterationNo = 0;

  @override
  void initState() {
    _streamController = StreamController<int>.broadcast();

    //trigger ui redraw
    refreshUiTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        ++iterationNo;
      });

      if (iterationNo == 5) {
        t.cancel();
      }
    });

    sendToStreamTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      //add whatever in the stream, we do not care what it is
      _streamController.sink.add(-1);

      if (iterationNo == 5) {
        t.cancel();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    refreshUiTimer.cancel();
    sendToStreamTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('UI redraw number: $iterationNo');
    return Container(
      alignment: Alignment.center,
      color: Colors.blueGrey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: getItems(),
      ),
    );
  }

  getItems() {
    List<Widget> items = <Widget>[
      Text(
        '$iterationNo',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      SizedBox(
        height: 50,
      ),
      DisposableWidget(
        iterationNo: iterationNo,
        streamController: _streamController,
      )
    ];

    //IMPORTANT!!!
    //to force the disposal of widgets in previous iteration,
    //you need to change hierarchy(order of widgets),
    // not just values, cos it will not
    //dispose old widgets - flutter will try to reuse old ones
    //(dispose, init state will not be called)
    if (iterationNo % 2 == 0) {
      items = items.reversed.toList();
    }

    return items;
  }
}

class DisposableWidget extends StatefulWidget {
  const DisposableWidget({Key key, this.iterationNo = 0, this.streamController})
      : super(key: key);
  final int iterationNo;
  final StreamController<int> streamController;

  @override
  _DisposableWidgetState createState() => _DisposableWidgetState();
}

class _DisposableWidgetState extends State<DisposableWidget> {

  void initState() {
    print('DisposableWidget(${widget.iterationNo}) initState');

    widget.streamController.stream.listen((int number) {
      print('DisposableWidget(${widget.iterationNo})stream listener, mounted: $mounted');
    });

    Future.delayed(Duration(seconds: 10), () {
      print('DisposableWidget(${widget.iterationNo}) future finished!! mounted: $mounted');
    });

    super.initState();
  }

  @override
  void dispose() {
    print('DisposableWidget(${widget.iterationNo}) dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle
      ),
      width: 50,
      height: 50,
      alignment: Alignment.center,

      child: Text(
        '${widget.iterationNo}',
        textAlign: TextAlign.center,
      ),
    );
  }
}
