import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedIndex = 0;
  final _toDoControler = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Task List"),
            backgroundColor: Colors.blueAccent,
            centerTitle: true),
        body: Column(
          children: <Widget>[
            Container(
                padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _toDoControler,
                        decoration: InputDecoration(
                            labelText: "New Task",
                            labelStyle: TextStyle(color: Colors.blueAccent)),
                      ),
                    ),
                    RaisedButton(
                      color: Colors.blueAccent,
                      child: Text("Add"),
                      textColor: Colors.white,
                      onPressed: _addToDoList,
                    )
                  ],
                )),
            Expanded(
                child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ))
          ],
        ));
  }

  Widget buildItem(context, index) {
    return Dismissible(
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);

          _saveData();

          final snackbar = SnackBar(
            content:
                Text("Task \"${_lastRemoved["title"]}\" has been removed!"),
            action: SnackBarAction(
              label: "Undo",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedIndex, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).showSnackBar(snackbar);
        });
      },
      key: Key(index.toString() + DateTime.now().millisecond.toString()),
      background: Container(
          color: Colors.redAccent,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete_forever, color: Colors.white),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (check) {
          setState(() {
            _toDoList[index]["ok"] = check;
            _saveData();
          });
        },
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child:
              Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error_outline),
        ),
      ),
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
    });
    return null;
  }

  void _addToDoList() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoControler.text;
      _toDoControler.text = "";
      newToDo["ok"] = false;

      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
