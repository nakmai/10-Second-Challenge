import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart'; // Tickerを使用するためにインポート
import 'package:ten_second_challenge/performance_page.dart';
import 'package:ten_second_challenge/log_page.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:ten_second_challenge/main.dart'; // TimerStateクラスをインポート

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 縦向き
    DeviceOrientation.portraitDown, // 反転縦向き（オプション）
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimerState(),
      child: MaterialApp(
        title: '目指せジャスト',
        theme: ThemeData(),
        home: MyHomePage(),
      ),
    );
  }
}

class TimerState extends ChangeNotifier {
  late Ticker _ticker;
  int _milliseconds = 0;
  bool _isRunning = false;

  // 成績データ
  int _totalPlays = 0;
  int _totalPerfect = 0;
  int _totalSuccess = 0;
  int _totalFails = 0;

  // 履歴データ
  final List<Map<String, String>> _logs = [];

  int get milliseconds => _milliseconds;
  bool get isRunning => _isRunning;

  // 成績データのゲッター
  int get totalPlays => _totalPlays;
  int get totalPerfect => _totalPerfect;
  int get totalSuccess => _totalSuccess;
  int get totalFails => _totalFails;

  // 履歴データのゲッター
  List<Map<String, String>> get logs => _logs;

  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _ticker = Ticker((elapsed) {
      _milliseconds = (elapsed.inMilliseconds ~/ 10) * 10; // 10ms 単位で更新
      notifyListeners();
    });
    _ticker.start();
  }

  void stopTimer(int targetSeconds) {
    if (!_isRunning) return;
    _isRunning = false;
    _ticker.stop();

    double elapsedSeconds = _milliseconds / 1000.0;
    _totalPlays++;

    // 成績の判定
    const successThreshold = 0.15;
    const perfectThreshold = 0.01;

    String result;
    if ((elapsedSeconds - targetSeconds).abs() <= perfectThreshold) {
      _totalPerfect++;
      result = '大成功';
    } else if ((elapsedSeconds - targetSeconds).abs() <= successThreshold) {
      _totalSuccess++;
      result = '成功';
    } else {
      _totalFails++;
      result = '失敗';
    }

    // 履歴を追加
    _logs.insert(0, {
      "time": elapsedSeconds.toStringAsFixed(2),
      "result": result,
    });
    if (_logs.length > 10) {
      _logs.removeLast();
    }

    notifyListeners();
  }

  void resetTimer() {
    _isRunning = false;
    _milliseconds = 0;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _targetSeconds = 10;
  bool _isTimeVisible = true;
  bool _isTimerStopped = true;

  String _getResultText(double elapsedSeconds) {
    const successThreshold = 0.15;
    const perfectThreshold = 0.01;

    if (!_isTimerStopped || elapsedSeconds == 0.0) return '';

    if ((elapsedSeconds - _targetSeconds).abs() <= perfectThreshold) {
      return '🎊 大 成 功 🎊';
    } else if ((elapsedSeconds - _targetSeconds).abs() <= successThreshold) {
      return '成功!';
    } else {
      return '失敗...';
    }
  }

  // 秒数変更用のキーボードを表示する
  void _showNumberKeyboard(BuildContext context) {
    final TextEditingController _controller =
        TextEditingController(text: _targetSeconds.toString());
    final FocusNode _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: EdgeInsets.all(12), // 縦幅を狭くする
            color: Colors.white,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: false,
                      signed: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '1〜59の数字を入力',
                      hintStyle: TextStyle(
                        fontSize: 18,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final int? newSeconds = int.tryParse(_controller.text);
                    if (newSeconds != null &&
                        newSeconds >= 1 &&
                        newSeconds <= 59) {
                      setState(() {
                        _targetSeconds = newSeconds;
                      });
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('1〜59の数字を入力してください'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  child: Text(
                    '変更',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ポップアップメニューの表示
  void _showPopupMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // ダイアログの角丸
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8, // 幅を画面の80%に設定
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 必要なサイズだけ確保
              children: [
                ListTile(
                  title: const Text(
                    '秒数変更',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                    _showNumberKeyboard(context); // 数字変更キーボードを呼び出し
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    '成績',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PerformancePage()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    '履歴',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogPage()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text(
                    'タイトル',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                    setState(() {
                      _targetSeconds = 10; // 目標秒数を初期値に戻す
                      _isTimerStopped = true; // タイマー停止状態に設定
                      context.read<TimerState>().resetTimer(); // タイマーをリセット
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var timerState = context.watch<TimerState>();
    double elapsedSeconds = timerState.milliseconds / 1000;
    String resultText = _getResultText(elapsedSeconds);

    return Scaffold(
      appBar: AppBar(
        title: null,
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/setting_icon.png', // カスタムアイコン画像を設定
              width: 24,
              height: 24,
            ),
            onPressed: () => _showPopupMenu(context), // ポップアップメニューを呼び出し
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '目指せジャスト',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '$_targetSeconds秒',
              style: TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              resultText,
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...((timerState.milliseconds / 1000)
                    .toStringAsFixed(2)
                    .padLeft(5, '0')
                    .split('')
                    .map((char) {
                  return Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: TextStyle(
                        fontSize: 60,
                        color: _isTimeVisible ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 7.0, // 文字間隔を広げる
                      ),
                    ),
                  );
                }).toList()),
                SizedBox(width: 10),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    '秒',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // ボタンを中央に配置
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      timerState.resetTimer();
                      setState(() {
                        _isTimerStopped = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'リセット',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    key: const Key('startButton'),
                    onPressed: () {
                      if (timerState.isRunning) {
                        timerState.stopTimer(_targetSeconds);
                        setState(() {
                          _isTimerStopped = true;
                        });
                      } else {
                        timerState.startTimer();
                        setState(() {
                          _isTimerStopped = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      timerState.isRunning ? 'ストップ' : 'スタート',
                      key: const Key('startButtonText'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            TextButton(
              onPressed: () {
                setState(() {
                  _isTimeVisible = !_isTimeVisible;
                });
              },
              child: Text(
                _isTimeVisible ? '秒数を表示しない' : '秒数を表示する',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
