import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart';

import 'dart:html' as html;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // デフォルトはシステム設定に従う

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.system; // システム設定に戻す
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'レジスター',
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: RegisterScreen(
        themeMode: _themeMode,
        toggleTheme: _toggleTheme, // テーマ切り替え関数を渡す
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  RegisterScreen({required this.themeMode, required this.toggleTheme});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> cart = [];
  List<String> history = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController receivedAmountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? selectedImage; // FileからUint8Listに変更
  String? changeAmount = '';
  int totalCartPrice = 0; // カートの合計金額
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadHistory();
  }

  void calculateTotalPrice() {
    setState(() {
      totalCartPrice =
          cart.fold(0, (sum, item) => (sum + (item['price'] ?? 0)).toInt());
    });
  }

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      cart.add(product);
      history.add('カートに追加: ${product['name']} ${product['price']}円');
    });
    calculateTotalPrice();
  }

  void removeFromCart(int index) {
    setState(() {
      history.add('カートから削除: ${cart[index]['name']}');
      cart.removeAt(index);
    });
    calculateTotalPrice();
  }

  void registerSale() {
    int? receivedAmount = int.tryParse(receivedAmountController.text);
    int totalPrice = totalCartPrice;

    if (receivedAmount != null) {
      if (receivedAmount >= totalPrice) {
        setState(() {
          int change = receivedAmount - totalPrice;
          changeAmount = 'おつり: $change円';

          DateTime now = DateTime.now();
          String dateTime =
              "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}:${now.second}";

          Map<String, int> productCount = {};
          for (var product in cart) {
            if (productCount.containsKey(product['name'])) {
              productCount[product['name']] =
                  productCount[product['name']]! + 1;
            } else {
              productCount[product['name']] = 1;
            }
          }

          productCount.forEach((name, count) {
            history.add(
                '売上登録: $dateTime $name $count ${products.firstWhere((product) => product['name'] == name)['price']}円');
          });

          cart.clear();
          receivedAmountController.clear();
          totalCartPrice = 0;
        });
        _saveHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('受け取った金額が不足しています。')),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? productList = prefs.getStringList('products');
    if (productList != null) {
      setState(() {
        products = productList.map((product) {
          final productMap = jsonDecode(product) as Map<String, dynamic>;
          if (productMap.containsKey('imageBytes')) {
            productMap['imageBytes'] =
                base64Decode(productMap['imageBytes']); // Base64をUint8Listに変換
          }
          return productMap;
        }).toList();
      });
    }
  }

  Future<void> _saveProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> productList = products.map((product) {
      final productCopy = Map<String, dynamic>.from(product);
      if (productCopy.containsKey('imageBytes')) {
        productCopy['imageBytes'] =
            base64Encode(productCopy['imageBytes']); // Uint8ListをBase64に変換
      }
      return jsonEncode(productCopy);
    }).toList();
    await prefs.setStringList('products', productList);
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedHistory = prefs.getStringList('history');
    if (savedHistory != null) {
      setState(() {
        history = savedHistory;
      });
    }
  }

  Future<void> _saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history);
  }

  Future<void> _exportHistoryToCSV() async {
    // CSVのヘッダー
    List<List<dynamic>> rows = [
      ['販売日時', '商品名', '合計購入個数', '単価'], // ヘッダー
    ];

    // 履歴データを追加
    for (var record in history) {
      var parts = record.split(': ');
      if (parts.length == 2 && parts[0] == '売上登録') {
        var details = parts[1].split(' ');
        if (details.length >= 4) {
          String dateTime = details[0] + ' ' + details[1];
          String productName = details[2];
          int quantity = int.parse(details[3]);
          int unitPrice = int.parse(details[4].replaceAll('円', ''));

          rows.add([dateTime, productName, quantity, unitPrice]);
        }
      }
    }

    // CSVデータを作成
    String csvData = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Web platform implementation
      final blob = html.Blob([csvData], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'history.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('履歴がCSVとしてダウンロードされました')),
      );
    } else {
      // Non-web platform implementation
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/history.csv';
      final file = File(filePath);
      await file.writeAsString(csvData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('履歴がCSVとして保存されました: $filePath')),
      );
    }
  }

  // 履歴の個別削除
  void _removeHistory(int index) {
    setState(() {
      history.removeAt(index);
    });
    _saveHistory(); // 履歴の変更を保存
  }

  // 履歴の一括削除
  void _clearHistory() {
    setState(() {
      history.clear();
    });
    _saveHistory(); // 履歴の変更を保存
  }

  void _removeProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
    _saveProducts(); // 商品の変更を保存
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = products.removeAt(oldIndex);
      products.insert(newIndex, item);
    });
    _saveProducts(); // 並べ替え後の順序を保存
  }

  Widget _buildProductInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: '商品名'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '価格'),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes =
                        await pickedFile.readAsBytes(); // Uint8Listを取得
                    setState(() {
                      selectedImage = bytes;
                    });
                  }
                },
                child: Text('画像選択'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  String name = nameController.text;
                  int? price = int.tryParse(priceController.text);

                  if (name.isNotEmpty &&
                      price != null &&
                      selectedImage != null) {
                    setState(() {
                      products.add({
                        'name': name,
                        'price': price,
                        'imageBytes': selectedImage, // Uint8Listを保存
                      });
                    });

                    nameController.clear();
                    priceController.clear();
                    selectedImage = null;

                    await _saveProducts();
                  }
                },
                child: Text('商品追加'),
              ),
            ],
          ),
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.memory(selectedImage!,
                  width: 50, height: 50), // Image.fileからImage.memoryに変更
            ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isEditMode) {
      // 編集モードの場合：並べ替えリスト表示（1アイテムずつ）
      return Expanded(
        child: ReorderableListView(
          onReorder: _onReorder,
          children: List.generate(products.length, (index) {
            return ListTile(
              key: ValueKey('product_$index'),
              leading: products[index]['imageBytes'] != null
                  ? Image.memory(
                      products[index]['imageBytes'], // Uint8Listを使用
                      width: 40,
                      height: 40,
                    )
                  : null,
              title: Text(
                products[index]['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${products[index]['price']}円'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeProduct(index),
              ),
            );
          }),
        ),
      );
    } else {
      // 通常モード：既存のグリッド表示（3列）
      return Expanded(
        child: ListView.builder(
          itemCount: (products.length / 3).ceil(),
          itemBuilder: (context, rowIndex) {
            int startIndex = rowIndex * 3;
            int endIndex = (startIndex + 3) > products.length
                ? products.length
                : startIndex + 3;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(endIndex - startIndex, (index) {
                  int productIndex = startIndex + index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => addToCart(products[productIndex]),
                      child: Card(
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (products[productIndex]['imageBytes'] !=
                                    null)
                                  Image.memory(
                                    products[productIndex]
                                        ['imageBytes'], // Uint8Listを使用
                                    width: 60,
                                    height: 60,
                                  ),
                                SizedBox(height: 4),
                                Text(
                                  products[productIndex]['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${products[productIndex]['price']}円',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            if (_isEditMode)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeProduct(productIndex),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildCartList() {
    return Expanded(
      child: ListView.builder(
        itemCount: cart.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            margin: EdgeInsets.all(4.0),
            child: ListTile(
              leading: cart[index]['imageBytes'] != null
                  ? Image.memory(
                      cart[index]['imageBytes'], // Uint8Listを使用
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : null,
              title: Text(
                cart[index]['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${cart[index]['price']}円'),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => removeFromCart(index),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCustomNumPad() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                double buttonHeight = constraints.maxHeight / 5;
                double buttonWidth = constraints.maxWidth / 3;

                return Container(
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          receivedAmountController.text,
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: buttonWidth / buttonHeight,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            String text;
                            if (index < 9) {
                              text = '${index + 1}';
                            } else if (index == 9) {
                              text = '0';
                            } else if (index == 10) {
                              text = '00';
                            } else {
                              text = '削除';
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (text == '削除') {
                                    if (receivedAmountController
                                        .text.isNotEmpty) {
                                      receivedAmountController.text =
                                          receivedAmountController.text
                                              .substring(
                                                  0,
                                                  receivedAmountController
                                                          .text.length -
                                                      1);
                                    }
                                  } else {
                                    receivedAmountController.text += text;
                                  }
                                });
                              },
                              child: Card(
                                child: Center(
                                  child: Text(
                                    text,
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('完了'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('合計金額: $totalCartPrice 円',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: _showCustomNumPad,
            child: AbsorbPointer(
              child: TextField(
                controller: receivedAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: '受け取り金額'),
              ),
            ),
          ),
          if (changeAmount != null && changeAmount!.isNotEmpty)
            Text(changeAmount!,
                style: TextStyle(fontSize: 18, color: Colors.green)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: registerSale,
                child: Text('売上登録'),
              ),
              ElevatedButton(
                onPressed: _exportHistoryToCSV,
                child: Text('履歴CSV出力'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 履歴表示ボタン
  Widget _buildHistoryButton() {
    return IconButton(
      icon: Icon(Icons.history),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('履歴'),
                content: SizedBox(
                  height: 300,
                  width: 300,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(history[index]),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _removeHistory(index);
                                  setDialogState(() {}); // ダイアログを更新
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _clearHistory();
                          setDialogState(() {}); // ダイアログを更新
                        },
                        child: Text('一括削除'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('閉じる'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('レジスター'),
        actions: [
          _buildHistoryButton(),
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : widget.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.settings, // システム設定アイコン
            ),
            onPressed: widget.toggleTheme, // テーマ切り替え
          ),
          IconButton(
            icon: Icon(_isEditMode ? Icons.done : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ], // 履歴表示ボタンを右上に配置
      ),
      body: Column(
        children: [
          _buildProductInput(),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildProductList()),
                VerticalDivider(),
                Expanded(
                    child: Column(
                  children: [
                    Text('カート',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildCartList(),
                    _buildCartControls(),
                  ],
                )),
              ],
            ),
          ),
          Divider(),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'created by satonaka_chie9',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
