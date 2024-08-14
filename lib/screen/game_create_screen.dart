import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tictactoe/screen/game_screen.dart';

class GameCreateScreen extends StatefulWidget {
  final String playerName;

  GameCreateScreen({required this.playerName});

  @override
  _GameCreateScreenState createState() => _GameCreateScreenState();
}

class _GameCreateScreenState extends State<GameCreateScreen> {
  final TextEditingController _gameNameController = TextEditingController();
  Color _boardColor = Colors.red;

  int colorToInt(Color color) {
    return color.value;
  }

  Color intToColor(int colorValue) {
    return Color(colorValue);
  }

  void _createGame() async {
    // Oyun oluşturmak için gerekli verileri hazırlayın
    final response = await Supabase.instance.client
        .from('games')
        .insert({
      'gameName': _gameNameController.text,
      'boardColor': _boardColor.value,
      'status': 'waiting',
      'creator': widget.playerName,
      'playerX': widget.playerName,
      'playerO': null,
      'turn': 'X',
      'board': List.generate(3, (index) => List.filled(3, '')),
    })
        .select()
        .single();

    if (response != null) {
      final createdGame = response;
      final boardColor = createdGame['boardColor'] != null
          ? Color(createdGame['boardColor']) // int değerini Color'a dönüştürün
          : Colors.white; // Varsayılan renk
      // Oyun başarıyla oluşturulduysa game_screen'e yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameId: createdGame['id'],
            playerName: widget.playerName,
            boardColor: boardColor,
          ),
        ),
      );
    } else {
      // Hata yönetimi ekleyin
      print("Oyun oluşturulurken bir hata meydana geldi: ${response}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create a New Game')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _gameNameController,
              decoration: InputDecoration(labelText: 'Game Name'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Board Color:'),
                GestureDetector(
                  onTap: () {
                    _showColorPicker(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    color: _boardColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createGame,
              child: Text('Create Game'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    // Diyaloğun açılma işleminin tetiklendiğini kontrol edin
    print('Color picker açılıyor...');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _boardColor,
              availableColors: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.lightBlue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey
              ],
              onColorChanged: (color) {
                print(color);
                setState(() {
                  _boardColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
