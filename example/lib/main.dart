import 'package:flutter/material.dart';

import 'package:flutter_hk/hk_player.dart';
import 'package:flutter_hk/hk_controller.dart';
import 'package:flutter_hk/hk_player_controller.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: FirstPage(),
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                  builder: (context) => FirstPage(), maintainState: false);
            case '/v':
              Map<String, Object> map =
                  settings.arguments is Map<String, Object>
                      ? (settings.arguments as Map<String, Object>)
                      : {};
              return MaterialPageRoute(
                  builder: (context) => SecondPage(map), maintainState: false);
            default:
              return null;
          }
        });
  }
}

class FirstPage extends StatelessWidget {
  String? ip;
  int port = 0;
  String? user, psd;

  GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('海康视频Demo')),
        body: Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10), labelText: '请输入ip'),
                  initialValue: '218.2.210.206',
                  onSaved: (v) => ip = v),
              TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10), labelText: '请输入端口'),
                  initialValue: '8000',
                  onSaved: (v) => port = v != null ? int.parse(v) : 0),
              TextFormField(
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10), labelText: '请输入user'),
                  initialValue: 'admin',
                  onSaved: (v) => user = v),
              TextFormField(
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10), labelText: '请输入密码'),
                  initialValue: 'admin',
                  onSaved: (v) => psd = v),
              IconButton(
                  icon: Icon(Icons.arrow_downward),
                  onPressed: () {
                    if (_formKey.currentState?.validate() == true) {
                      _formKey.currentState!.save();
                      Navigator.pushNamed(context, '/v', arguments: {
                        'ip': ip,
                        'port': port,
                        'user': user,
                        'psd': psd
                      });
                    }
                  }),
              IconButton(
                  icon: Icon(Icons.pages),
                  onPressed: () {
                    HkController.platformVersion
                        .then((v) => print('output:' + v));
                  })
            ])));
  }
}

class SecondPage extends StatefulWidget {
  String? ip;
  int port = 0;
  String? user, psd;

  SecondPage(Map<String, Object> map) {
    ip = map['ip']?.toString();
    port = int.parse(map['port']?.toString() ?? '0');
    psd = map['psd']?.toString();
    user = map['user']?.toString();
  }

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  late HkController hkController;
  late HkPlayerController playerController;
  Map? cameras;
  String? errMsg;

  @override
  void initState() {
    super.initState();

    initPlatformState();
  }

  @override
  void dispose() {
    hkController.logout();
    hkController.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    try {
      hkController = HkController('hk'); // 必须要有名字，如果有多个摄像头或硬盘录像机就要定义多个
      playerController = HkPlayerController(hkController); // 有多个播放器就要定义多个

      await hkController.init();
      await hkController.login(
          widget.ip ?? '', widget.port, widget.user ?? '', widget.psd ?? '');

      var chans = await hkController.getChans();

      if (!mounted) return;

      setState(() {
        cameras = chans;
      });
    } catch (e, _) {
      setState(() {
        errMsg = e.toString();
      });
    }
  }

  Widget buildCameras(Map cameras) {
    List<Widget> list = [];
    List<int> keys = List.from(cameras.keys);
    keys.sort((l, r) => l.compareTo(r));
    for (int key in keys) {
      list.add(TextButton(
          child: Text(cameras[key]),
          onPressed: () {
            if (playerController.isPlaying) {
              playerController.stop();
            }
            playerController.play(key);
          }));
    }
    return Container(
        height: 200,
        child: GridView.count(
            crossAxisCount: 5,
            padding: EdgeInsets.all(4),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: list));
  }

  @override
  Widget build(BuildContext context) {
    Widget loading() {
      if (cameras == null) {
        if (errMsg == null) {
          return Center(child: Text('登录中。。。'));
        } else {
          return Center(child: Text(errMsg!));
        }
      } else {
        return Column(children: [
          buildCameras(cameras!),
          Expanded(
              child: Container(
                  padding: EdgeInsets.all(4),
                  child: HkPlayer(controller: playerController)))
        ]);
      }
    }

    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Plugin example app')),
            body: loading()));
  }
}
