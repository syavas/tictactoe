import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictactoe/screen/game_create_screen.dart';
import 'package:tictactoe/screen/game_screen.dart';

class GameListScreen extends StatefulWidget {
  final String playerName;

  GameListScreen({required this.playerName});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {


  void _joinGame(int gameId,int boardColor) async {
    final response = await Supabase.instance.client
        .from('games')
        .update({
      'playerO': widget.playerName, // playerO alanını güncelle
      'status': 'waiting', // Oyun durumunu güncelle
    })
        .eq('id', gameId);


      // Güncelleme başarılı olursa game_screen ekranına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            gameId: gameId,
            playerName: widget.playerName,
            boardColor: Color(boardColor),
          ),
        ),
      );

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Available Games')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('games')
            .stream(primaryKey: ['id'])
            .map((data) => data.map((e) => e as Map<String, dynamic>).toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No Games Found'));
          }
          return ListView.builder(
            itemCount:  snapshot.data!.length,
            itemBuilder: (context, index) {
              final game = snapshot.data![index];
              return ListTile(
                title: Text(game['gameName']),
                subtitle: Text(game['status']),
                trailing: ElevatedButton(
                  onPressed: game['playerO'] == null && game['status'] != 'completed' ? () => _joinGame(game['id'],game['boardColor']) : null,
                  child: Text('Join'),
                ),
                onTap: () {
                  if (game['playerO'] != null && game['status'] != 'completed') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreen(
                          gameId: game['id'],
                          playerName: widget.playerName,
                          boardColor: game['boardColor'] != null
                              ? Color(game['boardColor'])
                              : Colors.white,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameCreateScreen(playerName: widget.playerName),
            ),
          );
        },
      ),
    );
  }
}
