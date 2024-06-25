// ignore_for_file: unrelated_type_equality_checks

import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({Key? key}) : super(key: key);

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _value = '000';
  String? _errorLoadingImage;
  bool _isPlaying = false;
  final List<String> _valueList = [];
  int maxDigits = 3; // จำนวนตัวเลขสูงสุดที่อนุญาต
  // ignore: non_constant_identifier_names
  final List<String> _valueList_last = [];
  // Future<List<String>>? imageListFuture;
  // List<String> imageList = [];
  List<File> imageList = [];
  // จัดการรูปภาพ
  Timer? _timer; // ประกาศตัวแปร _timer
  final Duration _changeImageDuration = const Duration(seconds: 10);
  final PageController _pageController = PageController();
  // final List<String> imageList = [
  //   'assets/images/Slide1.jpg',
  //   'assets/images/Slide2.jpg',
  //   'assets/images/Slide3.jpg',
  //   'assets/images/Slide4.jpg',
  // ];

  Future<void> _handleSubmit(String value) async {
    if (_isPlaying) {
      return;
    }
    if (value.startsWith('-') && int.tryParse(value.substring(1)) != null) {
      _handleMinus(value);
    } else if (value == '*') {
      _handleMultiply();
    } else if (int.tryParse(value) != null) {
      _handleNumericValue(value);
    } else if (value == '---') {
      _handleReset();
    } else if (value.startsWith('***')) {
      _handleModeChange(value);
    } else if (RegExp(r'[^\d+-.*/]').hasMatch(value)) {
      _handleInvalidCharacter();
    } else if ((value.startsWith('/'))) {
      _handleSlashValue(value);
      // } else if (value.startsWith('/')) {
      //   _handleSlash(value);
    } else {
      _handleOtherCases();
    }
  }

  void _handlePlus() async {
    int currentValue = int.parse(_value);
    _value = (currentValue + 1).toString().padLeft(3, '0');
    _startFlash();
    await _playSound(_value);
    _stopFlash();
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleMinus(String value) {
    print("เอาออกจาก array");
    String numberPart = value.substring(1);
    if (numberPart.isNotEmpty && int.tryParse(numberPart) != null) {
      // เติม 0 นำหน้าให้ numberPart ถ้าจำนวนหลักไม่ถึง 3
      while (numberPart.length < 3) {
        numberPart = '0' + numberPart;
      }
      if (_valueList_last.contains(numberPart)) {
        setState(() {
          _valueList_last.remove(numberPart);
        });
        _focusNode.requestFocus();
        _textController.clear();
      } else {
        _focusNode.requestFocus();
        _textController.clear();
      }
    } else {
      _focusNode.requestFocus();
      _textController.clear();
    }
  }

  void _handleMultiply() {
    print("เคลียค่า");
    setState(() {
      _value = '000';
    });
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleClearText() async {
    print("เคลียค่า Text");
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleNumericValue(String value) async {
    print("รับค่าตัวเลขตรงๆ");
    _value = value.toString().padLeft(3, '0');
    _startFlash();
    await _playSound(_value);
    _stopFlash();
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleDot() async {
    int currentValue = int.parse(_value);
    _value = (currentValue).toString().padLeft(3, '0');
    _startFlash();
    await _playSound(_value);

    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleReset() {
    print("ลบออกหมดทุกอย่าง");
    setState(() {
      _valueList.clear();
      _valueList_last.clear();
      // _value = '000';
    });
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleModeChange(String value) async {
    print("เปลี่ยนโหมดเสียง");
    String numberPart = value.substring(3);
    if (numberPart.isNotEmpty && int.tryParse(numberPart) != null) {
      await _addToHive(numberPart);
      var box = await Hive.openBox('ModeSounds');
      var mode = box.values.first;
      _showModeChangeDialog(mode);
    } else {
      _focusNode.requestFocus();
      _textController.clear();
    }
  }

  void _showModeChangeDialog(String mode) {
    String title, content;
    switch (mode) {
      case '1':
        title = 'MODE 1 : Bell';
        // content = 'Changing mode, bell sound |  ປ່ຽນໂໝດ, ສຽງກະດິ່ງ';
        content = '';
        break;
      case '2':
        title = 'MODE 2 : Calling voice - LAOS';
        // content = 'Changing mode, LOAS sound |  ປ່ຽນໂໝດ, ຫຼິ້ນສຽງ ປະເທດລາວ';
        content = '';
        break;
      case '3':
        title = 'MODE 3 : Calling voice - ENGLISH';
        // content = 'Changing mode, EN sound |  ປ່ຽນໂໝດ, ຫຼິ້ນສຽງ ພາສາອັງກິດ';
        content = '';
        break;
      case '4':
        title = 'MODE 3 : Calling voice - LOAS & ENGLISH';
        // content =
        //     'Changing mode, LOAS sound + EN sound | ປ່ຽນໂໝດ, ຫຼິ້ນສຽງ ປະເທດລາວ + ຫຼິ້ນສຽງ ພາສາອັງກິດ';
        content = '';
        break;
      default:
        title = 'Bell';
        content = '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        const duration = Duration(seconds: 2);
        Timer(duration, () {
          Navigator.of(context).pop();
        });
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontSize: 35),
            textAlign: TextAlign.center,
          ),
          content: Text(
            content,
            style: TextStyle(fontSize: 35),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleInvalidCharacter() {
    _focusNode.requestFocus();
    _textController.clear();
  }

  void _handleSlashValue(String value) {
    if (value == '/') {
      String numberPart = _value.substring(0);
      if (numberPart.isNotEmpty && int.tryParse(numberPart) != null) {
        setState(() {
          _isPlaying = false;
          if (numberPart != '000' || numberPart != '00' || numberPart != '0') {
            _valueList.add(numberPart);
            if (_valueList.isNotEmpty) {
              if (!_valueList_last.contains(numberPart)) {
                _valueList_last.add(numberPart);
                if (_valueList_last.length > 6) {
                  _valueList_last.removeAt(0);
                }
              }
            }
          }
        });
        _focusNode.requestFocus();
        _textController.clear();
      } else {
        _focusNode.requestFocus();
        _textController.clear();
      }
    } else {
      _handleSlash(value);
    }
  }

  void _handleSlash(String value) {
    print("เรียกแล้วไม่มา");
    String numberPart = value.substring(1);
    if (numberPart.isNotEmpty && int.tryParse(numberPart) != null) {
      while (numberPart.length < 3) {
        numberPart = '0' + numberPart;
      }
      setState(() {
        _isPlaying = false;
        if (numberPart != '000' || numberPart != '00' || numberPart != '0') {
          _valueList.add(numberPart);
          if (_valueList.isNotEmpty) {
            if (!_valueList_last.contains(numberPart)) {
              _valueList_last.add(numberPart);
              if (_valueList_last.length > 6) {
                _valueList_last.removeAt(0);
              }
            }
          }
        }
      });
      _focusNode.requestFocus();
      _textController.clear();
    } else {
      _focusNode.requestFocus();
      _textController.clear();
    }
  }

  void _handleOtherCases() {
    _focusNode.requestFocus();
    _textController.clear();
  }

  Future<void> _addToHive(String mode) async {
    var box = await Hive.openBox('ModeSounds');
    await box.put('mode', mode);
    await box.close();
    setState(() {});
  }

  // เล่นเสียง
  Future<void> _playSound(String value) async {
    // ตรวจสอบว่ามาจากโหมดไหน
    var box = await Hive.openBox('ModeSounds');
    var values = box.values.toList();
    var mode = box.values.first;
    final trimmedString = value.toString();
    final numberString = trimmedString.replaceAll(RegExp('^0+'), '');
    if (mode == '1') {
      await _audioPlayer.play(AssetSource('sound/bell.mp3'));
      // await Future.delayed(const Duration(milliseconds: 800));
      // await _audioPlayer.play(AssetSource('sound/EN/pleasenumber.MP3'));
      // await Future.delayed(const Duration(milliseconds: 1200));
      // for (int i = 0; i < numberString.length; i++) {
      //   await _audioPlayer.play(AssetSource('sound/EN/${numberString[i]}.MP3'));
      //   if (i + 1 < numberString.length &&
      //       numberString[i] == numberString[i + 1]) {
      //     // ถ้าตัวเลขปัจจุบันซ้ำกับตัวเลขถัดไป
      //     await _audioPlayer.onPlayerStateChanged.firstWhere(
      //       (state) => state == PlayerState.completed,
      //     );
      //   } else {
      //     await Future.delayed(const Duration(milliseconds: 650));
      //   }
      // }
    } else if (mode == '2') {
      await _audioPlayer.play(AssetSource('sound/LOAS/pleasenumber.MP3'));
      await Future.delayed(const Duration(milliseconds: 1200));
      for (int i = 0; i < numberString.length; i++) {
        await _audioPlayer
            .play(AssetSource('sound/LOAS/${numberString[i]}.MP3'));
        if (i + 1 < numberString.length &&
            numberString[i] == numberString[i + 1]) {
          // ถ้าตัวเลขปัจจุบันซ้ำกับตัวเลขถัดไป
          await _audioPlayer.onPlayerStateChanged.firstWhere(
            (state) => state == PlayerState.completed,
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 650));
        }
      }
    } else if (mode == '3') {
      await _audioPlayer.play(AssetSource('sound/EN/pleasenumber.MP3'));
      await Future.delayed(const Duration(milliseconds: 1200));
      for (int i = 0; i < numberString.length; i++) {
        await _audioPlayer.play(AssetSource('sound/EN/${numberString[i]}.MP3'));
        if (i + 1 < numberString.length &&
            numberString[i] == numberString[i + 1]) {
          // ถ้าตัวเลขปัจจุบันซ้ำกับตัวเลขถัดไป
          await _audioPlayer.onPlayerStateChanged.firstWhere(
            (state) => state == PlayerState.completed,
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 650));
        }
      }
    } else if (mode == '4') {
      await _audioPlayer.play(AssetSource('sound/LOAS/pleasenumber.MP3'));
      await Future.delayed(const Duration(milliseconds: 1200));
      for (int i = 0; i < numberString.length; i++) {
        await _audioPlayer
            .play(AssetSource('sound/LOAS/${numberString[i]}.MP3'));
        if (i + 1 < numberString.length &&
            numberString[i] == numberString[i + 1]) {
          // ถ้าตัวเลขปัจจุบันซ้ำกับตัวเลขถัดไป
          await _audioPlayer.onPlayerStateChanged.firstWhere(
            (state) => state == PlayerState.completed,
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 650));
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.play(AssetSource('sound/EN/pleasenumber.MP3'));
      await Future.delayed(const Duration(milliseconds: 1200));
      for (int i = 0; i < numberString.length; i++) {
        await _audioPlayer.play(AssetSource('sound/EN/${numberString[i]}.MP3'));
        if (i + 1 < numberString.length &&
            numberString[i] == numberString[i + 1]) {
          // ถ้าตัวเลขปัจจุบันซ้ำกับตัวเลขถัดไป
          await _audioPlayer.onPlayerStateChanged.firstWhere(
            (state) => state == PlayerState.completed,
          );
        } else {
          await Future.delayed(const Duration(milliseconds: 650));
        }
      }
      // int consecutiveZeros1 = 0;
      // for (int i = 0; i < numberString.length; i++) {
      //   String digit = numberString[i];
      //   await _audioPlayer.play(AssetSource('sound/EN/$digit.MP3'));
      //   await _audioPlayer.onPlayerStateChanged.firstWhere(
      //     (state) => state == PlayerState.completed,
      //   );
      //   if (digit == '0' &&
      //       i < numberString.length - 1 &&
      //       numberString[i + 1] == '0') {
      //     consecutiveZeros1++;
      //     if (consecutiveZeros1 > 1) {
      //       await Future.delayed(Duration(milliseconds: 100));
      //     }
      //   } else {
      //     consecutiveZeros1 = 0;
      //   }
      //   if (i < numberString.length - 1 && digit == numberString[i + 1]) {
      //     await Future.delayed(Duration(milliseconds: 100));
      //   }
      // }
    } else {
      await _audioPlayer.play(AssetSource('sound/bell.mp3'));
    }
  }

  // จัดการการกระพริบสี
  Timer? _flashTimer;
  int _flashCount = 0;
  bool _isGreen = true;
  void _startFlash() {
    _flashCount = 0; // รีเซ็ตจำนวนครั้งที่กระพริบ
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _isGreen = !_isGreen; // เปลี่ยนสีของ Text
        _flashCount++; // เพิ่มจำนวนครั้งที่กระพริบ
        if (_flashCount >= 8) {
          _flashTimer?.cancel(); // หยุดการกระพริบเมื่อกระพริบครบ 4 ครั้ง
        }
      });
    });
  }

  void _stopFlash() {
    _flashTimer?.cancel();
    setState(() {
      _isGreen = true;
    });
  }

  Future<void> loadImagesFromDrive() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await _requestExternalStoragePermission();
    }
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw 'External storage directory not found';
    }
    String usbPath =
        // '${externalDir.parent.parent.parent.parent.parent.parent.path}/CF09-E67B/images';
        '${externalDir.parent.parent.parent.parent.parent.parent.path}/DB1D-7C56/images';
    // '${externalDir.parent.parent.parent.parent.parent.parent.path}/2627-6E53/images';
    if (usbPath == null) {
      throw 'USB path is null';
    }
    Directory usbDir = Directory(usbPath);
    if (!usbDir.existsSync()) {
      throw 'USB directory does not exist';
    }

    List<FileSystemEntity> files = usbDir.listSync();

    if (files.isEmpty) {
      throw 'No files found in USB directory';
    }
    List<File> imageFiles = files.whereType<File>().toList();
    if (imageFiles.isEmpty) {
      throw 'No image files found in USB directory';
    }
    setState(() {
      imageList = imageFiles;
    });
  }

// ฟังก์ชันเริ่มต้น Timer
  void startTimer() {
    const Duration interval =
        Duration(seconds: 10); // กำหนดช่วงเวลาที่ต้องการให้ทำงานทุก 10 วินาที
    _timer = Timer.periodic(interval, (Timer timer) {
      loadImagesFromDrive(); // เรียก loadImagesFromDrive() ทุก 10 วินาที
    });
    Timer.periodic(_changeImageDuration, (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= imageList.length) {
          nextPage = 0;
        }
        setState(() {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

// ฟังก์ชันหยุด Timer
  void stopTimer() {
    _timer?.cancel();
  }

  Future<void> _requestExternalStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
    } else {
      setState(() {
        _errorLoadingImage = 'Permission denied for storage';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestExternalStoragePermission();
    loadImagesFromDrive();
    startTimer();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _stopFlash();
    super.dispose();
    stopTimer();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: const Color.fromARGB(235, 241, 248, 120),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Opacity(
                          opacity: 1,
                          child: TextField(
                            controller: _textController,
                            onChanged: (value) {
                              _checkvalue(value);
                            },
                            onSubmitted: _handleSubmit,
                            autofocus: true,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintStyle: TextStyle(
                                fontSize: 1.0,
                                color: Color.fromARGB(235, 0, 0, 0),
                              ),
                              // border: InputBorder.none,
                            ),
                            inputFormatters: [
                              // LengthLimitingTextInputFormatter(3),
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d+-.*/]')),
                            ],
                            maxLines: 1,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: screenSize.height *
                                  0.15, // 10% ของความสูงของหน้าจอ
                              child: Image.asset(
                                'assets/images/logoHawkerChan.png', // ที่อยู่ของรูปภาพในโฟลเดอร์ assets
                                fit: BoxFit.contain,
                                alignment:
                                    Alignment.center, // ทำให้รูปภาพอยู่ตรงกลาง
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 9, 105, 14),
                        minimumSize: Size(
                            screenSize.width * 0.3, screenSize.height * 0.07),
                      ),
                      child: Text(
                        'NEXT QUEUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenSize.width * 0.015,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical:
                              0.0), // เพิ่ม padding เพื่อลดพื้นที่รอบๆข้อความ
                      child: Text(
                        _value.substring(0, 3),
                        style: TextStyle(
                          color: _isGreen
                              ? Color.fromARGB(255, 218, 41, 28)
                              : Color.fromARGB(255, 255, 230, 0),
                          fontSize: screenSize.height *
                              0.30, // ลดขนาด font ของข้อความ
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 9, 105, 14),
                        ),
                        minimumSize: MaterialStateProperty.all<Size>(
                          Size(
                              screenSize.width * 0.3, screenSize.height * 0.07),
                        ),
                      ),
                      child: Text(
                        'PAST QUEUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenSize.width * 0.015,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.05),
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              // ใช้ Expanded เพื่อให้ Column มีขนาดที่เหมาะสม
                              child: SizedBox(
                                width: screenSize.width * 0.4,
                                child: Column(
                                  children:
                                      _splitListIntoColumns(_valueList_last, 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                itemCount: imageList.length,
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.black,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Image.file(
                        imageList[index],
                      ),
                      // child: Image.asset(
                      //   imageList[index],
                      // ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _splitListIntoColumns(List<String> list, int columns) {
    final Size screenSize = MediaQuery.of(context).size;
    List<Widget> columnWidgets = [];
    List<Widget> rowWidgets = [];

    for (int i = 0; i < list.length; i++) {
      rowWidgets.add(
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  list[i].toString(),
                  style: TextStyle(
                    color: Color.fromARGB(255, 218, 41, 28),
                    fontSize: screenSize.height * 0.06,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if ((i + 1) % columns == 0 || i == list.length - 1) {
        columnWidgets.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: rowWidgets,
          ),
        );
        rowWidgets = [];
      }

      // เมื่อเต็ม 6 คอลัมน์หรือเมื่อมาถึงสุดท้ายของรายการ
      if (rowWidgets.length == columns || i == list.length - 1) {
        columnWidgets.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: rowWidgets,
          ),
        );
        rowWidgets = [];
      }
    }

    return columnWidgets;
  }

  Future<void> _checkvalue(String value) async {
    if (_isPlaying) {
      return;
    }
    if (value == '.') {
      if (_value == '000' || _value == '00' || _value == '0') {
        _focusNode.requestFocus();
        _textController.clear();
      } else {
        int currentValue = int.parse(_value);
        _value = (currentValue).toString().padLeft(3, '0');
        _startFlash();
        await _playSound(_value);
        _stopFlash();
      }
    } else if (value == '+') {
      _handlePlus();
    }
  }
}
