import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trading view',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const MyHomePage(title: 'Crypto'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Color _backgroundColor = const Color.fromRGBO(15, 19, 24, 1);
  final Map<int, WebViewController> _webViewControllerList = HashMap();
  final List<String> _perpetual = <String>[
    'BTCUSDT',
    'ETHUSDT',
  ];

  late String _interval;

  @override
  void initState() {
    _interval = '1D';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_webViewControllerList.isNotEmpty) {
      _webViewControllerList.forEach((key, value) {
        _loadHtmlFromAssets(value, _perpetual[key], _interval);
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: Row(children: [
            Expanded(
                child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white),
            )),
            _getButtonView('R', _interval),
            _getButtonView('5M', _interval),
            _getButtonView('1H', _interval),
            _getButtonView('1D', _interval),
            _getButtonView('+', _interval),
          ]),
          backgroundColor: Colors.black,
        ),
        body: Container(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            color: _backgroundColor,
            child: Column(
              children: [
                // Row(
                //   children: [
                //     Expanded(child: _getTitleView(_perpetual[0])),
                //     Expanded(child: _getTitleView(_perpetual[1])),
                //   ],
                // ),
                Expanded(
                    child: Row(
                  children: [
                    Expanded(child: _getWebView(0, _perpetual[0], _interval)),
                    Expanded(child: _getWebView(1, _perpetual[1], _interval)),
                  ],
                )),
              ],
            )));
  }

  Widget _getWebView(int id, String pair, String interval) {
    return WebView(
      backgroundColor: _backgroundColor,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _webViewControllerList.putIfAbsent(id, () => webViewController);
        _loadHtmlFromAssets(webViewController, pair, interval);
      },
      onPageFinished: (_) {
        _webViewControllerList[id]?.scrollTo(0, 0);
      },
    );
  }

  Widget _getButtonView(String text, String interval) {
    return InkWell(
      onTap: () {
        if (text.contains('+')) {
          _displayTextInputDialog(context);
        } else {
          setState(() {
            if (!text.contains('R') && !text.contains('+')) {
              _interval = text;
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text,
            style: TextStyle(
                color: interval == text ? Colors.brown : Colors.white)),
      ),
    );
  }

  Widget _getTitleView(String title) {
    return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
        ),
        child: Text(title, style: const TextStyle(color: Colors.white)));
  }

  _loadHtmlFromAssets(
      WebViewController controller, String pair, String interval) async {
    switch (interval) {
      case '1D':
        interval = 'D';
        break;
      case '1H':
        interval = '60';
        break;
      case '5M':
        interval = '5';
        break;
    }
    final String fileText =
        await rootBundle.loadString('assets/trading_view_widget.html');
    controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString()
        .replaceAll('PAIR', pair)
        .replaceAll('INTERVAL', interval));
  }

  Future<void> _displayTextInputDialog(final BuildContext context) async {
    TextEditingController textFieldController = TextEditingController();
    String valueText = '';

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Write your pair'),
            content: TextField(
              onChanged: (value) {
                valueText = value;
              },
              controller: textFieldController,
              decoration: InputDecoration(hintText: _perpetual[1]),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  valueText = valueText.toUpperCase().replaceAll(' ', '');

                  if (valueText.isEmpty) {
                    return;
                  }

                  if (!valueText.endsWith('USDT')) {
                    valueText += 'USDT';
                  }

                  setState(() {
                    _perpetual[1] = valueText;
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }
}
