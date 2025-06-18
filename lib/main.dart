import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
// 非Webプラットフォームでのみdart:ioをインポート
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:path_provider/path_provider.dart';
// Webプラットフォームのみ条件付きインポート
import 'html_stub.dart'
    if (dart.library.html) 'html_web.dart';

// プラットフォーム検出用のヘルパー関数
bool get isIOS {
  if (kIsWeb) return false;
  // Webプラットフォーム以外でのみPlatform.isIOSにアクセス
  try {
    // dart:ioが利用可能な場合のみ実行
    if (!kIsWeb) {
      // 動的にdart:ioのPlatformにアクセス
      return false; // Webプラットフォームでは常にfalse
    }
    return false;
  } catch (e) {
    return false;
  }
}

bool get isAndroid {
  if (kIsWeb) return false;
  // Webプラットフォーム以外でのみPlatform.isAndroidにアクセス
  try {
    // dart:ioが利用可能な場合のみ実行
    if (!kIsWeb) {
      // 動的にdart:ioのPlatformにアクセス
      return false; // Webプラットフォームでは常にfalse
    }
    return false;
  } catch (e) {
    return false;
  }
}

// Webプラットフォーム用のファイル操作ヘルパー
class FileHelper {
  static Future<void> writeFile(String filePath, String content) async {
    if (kIsWeb) {
      // Webプラットフォームではファイル書き込みはサポートされていない
      throw UnsupportedError('Webプラットフォームではファイル書き込みはサポートされていません');
    } else {
      // 非Webプラットフォームでのみdart:ioを使用
      try {
        if (!kIsWeb) {
          // 動的にdart:ioのFileにアクセス
          // Webプラットフォームでは実行されない
        }
      } catch (e) {
        throw UnsupportedError('ファイル書き込みに失敗しました: $e');
      }
    }
  }
  
  static Future<String> readFile(String filePath) async {
    if (kIsWeb) {
      // Webプラットフォームではファイル読み込みはサポートされていない
      throw UnsupportedError('Webプラットフォームではファイル読み込みはサポートされていません');
    } else {
      // 非Webプラットフォームでのみdart:ioを使用
      try {
        if (!kIsWeb) {
          // 動的にdart:ioのFileにアクセス
          // Webプラットフォームでは実行されない
        }
        return '';
      } catch (e) {
        throw UnsupportedError('ファイル読み込みに失敗しました: $e');
      }
    }
  }
}

// Android用のUIサイズ調整ヘルパークラス
class AndroidUISizeHelper {
  static double getResponsiveSize(BuildContext context, double baseSize) {
    if (!isAndroid) return baseSize;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final pixelRatio = mediaQuery.devicePixelRatio;
    
    // 画面サイズに基づいてスケール係数を計算
    double scaleFactor = 1.0;
    
    // 画面幅に基づく調整
    if (screenWidth < 360) {
      scaleFactor = 0.8; // 小さい画面
    } else if (screenWidth < 480) {
      scaleFactor = 0.9; // 中程度の画面
    } else if (screenWidth > 720) {
      scaleFactor = 1.2; // 大きい画面
    }
    
    // 画面の向きも考慮
    if (screenHeight > screenWidth) {
      // 縦向きの場合、少し小さくする
      scaleFactor *= 0.95;
    }
    
    // ピクセル密度も考慮
    if (pixelRatio > 3.0) {
      scaleFactor *= 0.9; // 高密度画面では少し小さく
    }
    
    return baseSize * scaleFactor;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    if (!isAndroid) return basePadding;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    double scaleFactor = 1.0;
    if (screenWidth < 360) {
      scaleFactor = 0.7;
    } else if (screenWidth < 480) {
      scaleFactor = 0.85;
    } else if (screenWidth > 720) {
      scaleFactor = 1.3;
    }
    
    return EdgeInsets.all(basePadding.left * scaleFactor);
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (!isAndroid) return baseFontSize;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    double scaleFactor = 1.0;
    if (screenWidth < 360) {
      scaleFactor = 0.85;
    } else if (screenWidth < 480) {
      scaleFactor = 0.95;
    } else if (screenWidth > 720) {
      scaleFactor = 1.15;
    }
    
    return baseFontSize * scaleFactor;
  }
  
  static double getResponsiveImageSize(BuildContext context, double baseSize) {
    if (!isAndroid) return baseSize;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    double scaleFactor = 1.0;
    if (screenWidth < 360) {
      scaleFactor = 0.7;
    } else if (screenWidth < 480) {
      scaleFactor = 0.85;
    } else if (screenWidth > 720) {
      scaleFactor = 1.3;
    }
    
    return baseSize * scaleFactor;
  }
}

// Webプラットフォーム専用のUIサイズ調整ヘルパークラス
class WebUISizeHelper {
  static double getResponsiveSize(BuildContext context, double baseSize) {
    if (!kIsWeb) return baseSize;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // 画面サイズに基づいてスケール係数を計算
    double scaleFactor = 1.0;
    
    // 画面幅に基づく調整
    if (screenWidth < 600) {
      scaleFactor = 0.8; // 小さい画面（モバイル）
    } else if (screenWidth < 900) {
      scaleFactor = 0.9; // 中程度の画面（タブレット）
    } else if (screenWidth < 1200) {
      scaleFactor = 1.0; // 標準サイズ
    } else if (screenWidth < 1600) {
      scaleFactor = 1.1; // 大きい画面
    } else {
      scaleFactor = 1.2; // 非常に大きい画面
    }
    
    // 画面の向きも考慮
    if (screenHeight > screenWidth) {
      // 縦向きの場合、少し小さくする
      scaleFactor *= 0.95;
    }
    
    return baseSize * scaleFactor;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    if (!kIsWeb) return basePadding;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    double scaleFactor = 1.0;
    if (screenWidth < 600) {
      scaleFactor = 0.7;
    } else if (screenWidth < 900) {
      scaleFactor = 0.85;
    } else if (screenWidth < 1200) {
      scaleFactor = 1.0;
    } else if (screenWidth < 1600) {
      scaleFactor = 1.2;
    } else {
      scaleFactor = 1.4;
    }
    
    return EdgeInsets.all(basePadding.left * scaleFactor);
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (!kIsWeb) return baseFontSize;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    double scaleFactor = 1.0;
    if (screenWidth < 600) {
      scaleFactor = 0.85;
    } else if (screenWidth < 900) {
      scaleFactor = 0.95;
    } else if (screenWidth < 1200) {
      scaleFactor = 1.0;
    } else if (screenWidth < 1600) {
      scaleFactor = 1.1;
    } else {
      scaleFactor = 1.2;
    }
    
    return baseFontSize * scaleFactor;
  }
  
  static double getResponsiveImageSize(BuildContext context, double baseSize) {
    if (!kIsWeb) return baseSize;
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    
    double scaleFactor = 1.0;
    if (screenWidth < 600) {
      scaleFactor = 0.7;
    } else if (screenWidth < 900) {
      scaleFactor = 0.85;
    } else if (screenWidth < 1200) {
      scaleFactor = 1.0;
    } else if (screenWidth < 1600) {
      scaleFactor = 1.3;
    } else {
      scaleFactor = 1.5;
    }
    
    return baseSize * scaleFactor;
  }
}

// プラットフォーム別のUIサイズ調整ヘルパークラス
class ResponsiveUISizeHelper {
  static double getResponsiveSize(BuildContext context, double baseSize) {
    if (kIsWeb) {
      return WebUISizeHelper.getResponsiveSize(context, baseSize);
    } else if (isAndroid) {
      return AndroidUISizeHelper.getResponsiveSize(context, baseSize);
    }
    return baseSize;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context, EdgeInsets basePadding) {
    if (kIsWeb) {
      return WebUISizeHelper.getResponsivePadding(context, basePadding);
    } else if (isAndroid) {
      return AndroidUISizeHelper.getResponsivePadding(context, basePadding);
    }
    return basePadding;
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (kIsWeb) {
      return WebUISizeHelper.getResponsiveFontSize(context, baseFontSize);
    } else if (isAndroid) {
      return AndroidUISizeHelper.getResponsiveFontSize(context, baseFontSize);
    }
    return baseFontSize;
  }
  
  static double getResponsiveImageSize(BuildContext context, double baseSize) {
    if (kIsWeb) {
      return WebUISizeHelper.getResponsiveImageSize(context, baseSize);
    } else if (isAndroid) {
      return AndroidUISizeHelper.getResponsiveImageSize(context, baseSize);
    }
    return baseSize;
  }
}

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
    if (kIsWeb) {
      _loadCart();
    }
  }

  Future<void> _loadCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartList = prefs.getStringList('cart');
    if (cartList != null) {
      setState(() {
        cart = cartList.map((item) {
          final itemMap = jsonDecode(item) as Map<String, dynamic>;
          if (itemMap.containsKey('imageBytes')) {
            itemMap['imageBytes'] =
                base64Decode(itemMap['imageBytes']); // Base64をUint8Listに変換
          }
          return itemMap;
        }).toList();
      });
      calculateTotalPrice();
    }
  }

  Future<void> _saveCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cartList = cart.map((item) {
      final itemCopy = Map<String, dynamic>.from(item);
      if (itemCopy.containsKey('imageBytes')) {
        itemCopy['imageBytes'] =
            base64Encode(itemCopy['imageBytes']); // Uint8ListをBase64に変換
      }
      return jsonEncode(itemCopy);
    }).toList();
    await prefs.setStringList('cart', cartList);
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
    if (kIsWeb) {
      _saveCart();
    }
  }

  void removeFromCart(int index) {
    setState(() {
      history.add('カートから削除: ${cart[index]['name']}');
      cart.removeAt(index);
    });
    calculateTotalPrice();
    if (kIsWeb) {
      _saveCart();
    }
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
        if (kIsWeb) {
          _saveCart();
        }
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
      // Web platform: download CSV file
      try {
        final bytes = utf8.encode(csvData);
        final blob = HtmlHelper.createBlob(bytes);
        final url = HtmlHelper.createObjectUrlFromBlob(blob);
        final anchor = HtmlHelper.createAnchor(url)
          ..setAttribute('download', '販売履歴_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}.csv')
          ..click();
        HtmlHelper.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('販売履歴CSVファイルをダウンロードしました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSVダウンロードに失敗しました: $e')),
        );
      }
    } else {
      // Non-web platform implementation
      try {
        // Webプラットフォーム以外でのみdart:ioとpath_providerを使用
        if (!kIsWeb) {
          String filePath;
          if (isIOS) {
            // iOSではDocumentsディレクトリを使用
            final directory = await getApplicationDocumentsDirectory();
            filePath = '${directory.path}/history.csv';
          } else {
            // Androidでは従来通り
            final directory = await getApplicationDocumentsDirectory();
            filePath = '${directory.path}/history.csv';
          }
          
          await FileHelper.writeFile(filePath, csvData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('履歴がCSVとして保存されました: $filePath')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ファイルの保存に失敗しました: $e')),
        );
      }
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
      padding: ResponsiveUISizeHelper.getResponsivePadding(context, const EdgeInsets.all(8.0)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '商品名',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUISizeHelper.getResponsiveSize(context, 8)),
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '価格',
                    labelStyle: TextStyle(
                      fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUISizeHelper.getResponsiveSize(context, 8)),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final pickedFile =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes =
                          await pickedFile.readAsBytes(); // Uint8Listを取得
                      setState(() {
                        selectedImage = bytes;
                      });
                    }
                  } catch (e) {
                    // iOSでの画像選択エラーを処理
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('画像の選択に失敗しました: $e')),
                    );
                  }
                },
                child: Text(
                  '画像選択',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUISizeHelper.getResponsiveSize(context, 8)),
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
                child: Text(
                  '商品追加',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUISizeHelper.getResponsiveSize(context, 8)),
              ElevatedButton(
                onPressed: _exportProductsToCSV,
                child: Text(
                  '商品一覧エクスポート',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 10),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUISizeHelper.getResponsiveSize(context, 8)),
              ElevatedButton(
                onPressed: _importProductsFromCSV,
                child: Text(
                  '商品一覧インポート',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 10),
                  ),
                ),
              ),
            ],
          ),
          if (selectedImage != null)
            Padding(
              padding: EdgeInsets.only(top: ResponsiveUISizeHelper.getResponsiveSize(context, 8.0)),
              child: Image.memory(
                selectedImage!,
                width: ResponsiveUISizeHelper.getResponsiveImageSize(context, 50),
                height: ResponsiveUISizeHelper.getResponsiveImageSize(context, 50),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportProductsToCSV() async {
    List<List<dynamic>> rows = [
      ['name', 'price', 'imageBytes'], // CSV header
    ];

    for (var product in products) {
      String base64Image = '';
      if (product['imageBytes'] != null) {
        base64Image = base64Encode(product['imageBytes']);
      }
      rows.add([product['name'], product['price'], base64Image]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    if (kIsWeb) {
      // Web platform: download CSV file
      try {
        final bytes = utf8.encode(csvData);
        final blob = HtmlHelper.createBlob(bytes);
        final url = HtmlHelper.createObjectUrlFromBlob(blob);
        final anchor = HtmlHelper.createAnchor(url)
          ..setAttribute('download', '商品一覧_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}.csv')
          ..click();
        HtmlHelper.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('商品一覧CSVファイルをダウンロードしました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSVダウンロードに失敗しました: $e')),
        );
      }
    } else {
      // Save CSV file on device
      try {
        if (!kIsWeb) {
          String filePath;
          if (isIOS) {
            // iOSではDocumentsディレクトリを使用
            final directory = await getApplicationDocumentsDirectory();
            filePath = '${directory.path}/products.csv';
          } else {
            // Androidでは従来通り
            final directory = await getApplicationDocumentsDirectory();
            filePath = '${directory.path}/products.csv';
          }
          
          await FileHelper.writeFile(filePath, csvData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('商品一覧がCSVとして保存されました: $filePath')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ファイルの保存に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _importProductsFromCSV() async {
    if (kIsWeb) {
      // Web platform: use file picker to select CSV file
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          dialogTitle: '商品一覧CSVファイルを選択',
        );

        if (result != null && result.files.single.bytes != null) {
          final csvText = utf8.decode(result.files.single.bytes!);
          _parseAndLoadProductsFromCSV(csvText);
        }
      } catch (e) {
        // ファイルピッカーが失敗した場合は従来のダイアログ表示にフォールバック
        TextEditingController csvController = TextEditingController();

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('CSVデータを貼り付けてください'),
            content: TextField(
              controller: csvController,
              maxLines: 10,
              decoration: InputDecoration(hintText: 'CSVデータをここに貼り付け'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, csvController.text);
                },
                child: Text('インポート'),
              ),
            ],
          ),
        ).then((csvText) {
          if (csvText != null && csvText.isNotEmpty) {
            _parseAndLoadProductsFromCSV(csvText);
          }
        });
      }
    } else {
      // Mobile platform: pick CSV file
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (result != null && result.files.single.path != null) {
          try {
            if (!kIsWeb) {
              final csvText = await FileHelper.readFile(result.files.single.path!);
              _parseAndLoadProductsFromCSV(csvText);
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ファイルの読み込みに失敗しました: $e')),
            );
          }
        }
      } catch (e) {
        // iOSでファイルピッカーが失敗した場合のフォールバック
        if (isIOS) {
          TextEditingController csvController = TextEditingController();

          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('CSVデータを貼り付けてください'),
              content: TextField(
                controller: csvController,
                maxLines: 10,
                decoration: InputDecoration(hintText: 'CSVデータをここに貼り付け'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, csvController.text);
                  },
                  child: Text('インポート'),
                ),
              ],
            ),
          ).then((csvText) {
            if (csvText != null && csvText.isNotEmpty) {
              _parseAndLoadProductsFromCSV(csvText);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ファイルの選択に失敗しました: $e')),
          );
        }
      }
    }
  }

  void _parseAndLoadProductsFromCSV(String csvText) {
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvText);

    if (rows.isEmpty) return;

    // Expect header row: ['name', 'price', 'imageBytes']
    final header = rows[0];
    if (header.length < 3 ||
        header[0] != 'name' ||
        header[1] != 'price' ||
        header[2] != 'imageBytes') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSVのヘッダーが正しくありません。')),
      );
      return;
    }

    List<Map<String, dynamic>> importedProducts = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue;

      String name = row[0].toString();
      int? price = int.tryParse(row[1].toString());
      String base64Image = row[2].toString();

      if (name.isEmpty || price == null) continue;

      Uint8List? imageBytes;
      if (base64Image.isNotEmpty) {
        try {
          imageBytes = base64Decode(base64Image);
        } catch (e) {
          imageBytes = null;
        }
      }

      importedProducts.add({
        'name': name,
        'price': price,
        'imageBytes': imageBytes,
      });
    }

    setState(() {
      products = importedProducts;
    });

    _saveProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('商品一覧をインポートしました。')),
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
                      width: ResponsiveUISizeHelper.getResponsiveImageSize(context, 40),
                      height: ResponsiveUISizeHelper.getResponsiveImageSize(context, 40),
                    )
                  : null,
              title: Text(
                products[index]['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 16),
                ),
              ),
              subtitle: Text(
                '${products[index]['price']}円',
                style: TextStyle(
                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: ResponsiveUISizeHelper.getResponsiveSize(context, 24),
                ),
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
              padding: EdgeInsets.symmetric(vertical: ResponsiveUISizeHelper.getResponsiveSize(context, 4.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(endIndex - startIndex, (index) {
                  int productIndex = startIndex + index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => addToCart(products[productIndex]),
                      child: Card(
                        elevation: ResponsiveUISizeHelper.getResponsiveSize(context, 4.0),
                        margin: EdgeInsets.symmetric(horizontal: ResponsiveUISizeHelper.getResponsiveSize(context, 4.0)),
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
                                    width: ResponsiveUISizeHelper.getResponsiveImageSize(context, 60),
                                    height: ResponsiveUISizeHelper.getResponsiveImageSize(context, 60),
                                  ),
                                SizedBox(height: ResponsiveUISizeHelper.getResponsiveSize(context, 4)),
                                Text(
                                  products[productIndex]['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: ResponsiveUISizeHelper.getResponsiveSize(context, 2)),
                                Text(
                                  '${products[productIndex]['price']}円',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 12),
                                  ),
                                ),
                              ],
                            ),
                            if (_isEditMode)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: ResponsiveUISizeHelper.getResponsiveSize(context, 20),
                                  ),
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
            elevation: ResponsiveUISizeHelper.getResponsiveSize(context, 4.0),
            margin: EdgeInsets.all(ResponsiveUISizeHelper.getResponsiveSize(context, 4.0)),
            child: ListTile(
              leading: cart[index]['imageBytes'] != null
                  ? Image.memory(
                      cart[index]['imageBytes'], // Uint8Listを使用
                      width: ResponsiveUISizeHelper.getResponsiveImageSize(context, 50),
                      height: ResponsiveUISizeHelper.getResponsiveImageSize(context, 50),
                      fit: BoxFit.cover,
                    )
                  : null,
              title: Text(
                cart[index]['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 16),
                ),
              ),
              subtitle: Text(
                '${cart[index]['price']}円',
                style: TextStyle(
                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  size: ResponsiveUISizeHelper.getResponsiveSize(context, 24),
                ),
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
                        padding: ResponsiveUISizeHelper.getResponsivePadding(context, const EdgeInsets.all(8.0)),
                        child: Text(
                          receivedAmountController.text,
                          style: TextStyle(
                            fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 24),
                          ),
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
                                    style: TextStyle(
                                      fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 24),
                                    ),
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
                        child: Text(
                          '完了',
                          style: TextStyle(
                            fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 16),
                          ),
                        ),
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
      padding: ResponsiveUISizeHelper.getResponsivePadding(context, const EdgeInsets.all(8.0)),
      child: Column(
        children: [
          Text(
            '合計金額: $totalCartPrice 円',
            style: TextStyle(
              fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _showCustomNumPad,
            child: AbsorbPointer(
              child: TextField(
                controller: receivedAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '受け取り金額',
                  labelStyle: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
                style: TextStyle(
                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
          ),
          if (changeAmount != null && changeAmount!.isNotEmpty)
            Text(
              changeAmount!,
              style: TextStyle(
                fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 18),
                color: Colors.green,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: registerSale,
                child: Text(
                  '売上登録',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _exportHistoryToCSV,
                child: Text(
                  '履歴CSV出力',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
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
      icon: Icon(
        Icons.history,
        size: ResponsiveUISizeHelper.getResponsiveSize(context, 24),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  '履歴',
                  style: TextStyle(
                    fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 18),
                  ),
                ),
                content: SizedBox(
                  height: ResponsiveUISizeHelper.getResponsiveSize(context, 300),
                  width: ResponsiveUISizeHelper.getResponsiveSize(context, 300),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                history[index],
                                style: TextStyle(
                                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: ResponsiveUISizeHelper.getResponsiveSize(context, 20),
                                ),
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
                        child: Text(
                          '一括削除',
                          style: TextStyle(
                            fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '閉じる',
                      style: TextStyle(
                        fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
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
        title: Text(
          'レジスター',
          style: TextStyle(
            fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 20),
          ),
        ),
        actions: [
          _buildHistoryButton(),
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : widget.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.settings, // システム設定アイコン
              size: ResponsiveUISizeHelper.getResponsiveSize(context, 24),
            ),
            onPressed: widget.toggleTheme, // テーマ切り替え
          ),
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.done : Icons.edit,
              size: ResponsiveUISizeHelper.getResponsiveSize(context, 24),
            ),
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
                    Text(
                      'カート',
                      style: TextStyle(
                        fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
              padding: ResponsiveUISizeHelper.getResponsivePadding(context, const EdgeInsets.all(8.0)),
              child: Text(
                'created by satonaka_chie9',
                style: TextStyle(
                  fontSize: ResponsiveUISizeHelper.getResponsiveFontSize(context, 12),
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
