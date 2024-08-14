import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameScreen extends StatefulWidget {
  final int gameId;
  final String playerName;
  final Color boardColor; // Board color

  GameScreen({required this.gameId, required this.playerName, required this.boardColor});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Map<String, dynamic> gameData;
  late List<List<String>> board;
  late final RealtimeChannel _gameChannel;
  String winner = '';
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchGameData();
    _subscribeToGameUpdates();
  }

  void _subscribeToGameUpdates() {
    _gameChannel = Supabase.instance.client
        .channel('public:games:id=eq.${widget.gameId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'games',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: widget.gameId,
      ),
      callback: (payload, {ref}) {
        if (payload.newRecord != null) {
          final updatedGameData = payload.newRecord as Map<String, dynamic>;
          setState(() {
            board = (updatedGameData['board'] as List)
                .map((row) => List<String>.from(row))
                .toList();
            gameData = updatedGameData;
            winner = _getWinner(); // Check if there's a winner
            _checkForDraw(); // Check if it's a draw
          });
        }
      },
    ).subscribe();
  }

  void _fetchGameData() async {
    final response = await Supabase.instance.client
        .from('games')
        .select('*')
        .eq('id', widget.gameId)
        .single();

    setState(() {
      gameData = response;
      board = (response['board'] as List)
          .map((row) => List<String>.from(row))
          .toList();
      winner = _getWinner(); // Check if there's a winner
      _checkForDraw(); // Check if it's a draw
      isLoading = false; // Set loading state to false
    });
  }

  void _makeMove(int row, int col) async {
    if (board[row][col].isEmpty && gameData['status'] == 'waiting') {
      String currentPlayer = gameData['turn'] == 'X' ? gameData['playerX'] : gameData['playerO'];

      if (currentPlayer == widget.playerName) {
        setState(() {
          board[row][col] = gameData['turn'];
        });
        String nextTurn = gameData['turn'] == 'X' ? 'O' : 'X';

        final response = await Supabase.instance.client
            .from('games')
            .update({
          'board': board,
          'turn': nextTurn,
        })
            .eq('id', widget.gameId)
            .select()
            .single();

        if (response != null) {
          setState(() {
            gameData = response as Map<String, dynamic>;
            board = (gameData['board'] as List)
                .map((row) => List<String>.from(row))
                .toList();
            winner = _getWinner(); // Check if there's a winner
            _checkForDraw(); // Check if it's a draw
          });
          if (winner.isNotEmpty) {
            _showWinnerDialog();
            _checkWinner(); // Update status if there's a winner
          }
        }
      }
    }
  }

  void _checkForDraw() {
    bool isFull = board.every((row) => row.every((cell) => cell.isNotEmpty));
    if (isFull && winner.isEmpty) {
      _showDrawDialog();
    }
  }

  void _checkWinner() async {
    String winner = _getWinner();
    if (winner.isNotEmpty) {
      await Supabase.instance.client
          .from('games')
          .update({'status': 'completed', 'winner': winner})
          .eq('id', widget.gameId)
          .select()
          .single();
    }
  }

  String _getWinner() {
    if (_isWinner('X')) return 'X';
    if (_isWinner('O')) return 'O';
    return '';
  }

  bool _isWinner(String player) {
    return _checkRows(player) || _checkCols(player) || _checkDiagonals(player);
  }

  bool _checkRows(String player) {
    return board.any((row) => row.every((cell) => cell == player));
  }

  bool _checkCols(String player) {
    for (int col = 0; col < 3; col++) {
      if (board[0][col] == player && board[1][col] == player && board[2][col] == player) {
        return true;
      }
    }
    return false;
  }

  bool _checkDiagonals(String player) {
    return (board[0][0] == player && board[1][1] == player && board[2][2] == player) ||
        (board[0][2] == player && board[1][1] == player && board[2][0] == player);
  }

  void _showWinnerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Winner: $winner'),
          content: Text('Complete the game.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text('Restart Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Navigate back to the list screen
              },
              child: Text('Return to List'),
            ),
          ],
        );
      },
    );
  }

  void _showDrawDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Draw!'),
          content: Text('The game ended in a draw.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text('Restart Game'),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() async {
    await Supabase.instance.client
        .from('games')
        .update({'board': [['', '', ''], ['', '', ''], ['', '', '']], 'status': 'waiting', 'turn': 'X'})
        .eq('id', widget.gameId)
        .select()
        .single();

    setState(() {
      board = [['', '', ''], ['', '', ''], ['', '', '']];
      winner = '';
    });
  }

  @override
  void dispose() {
    _gameChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Tic Tac Toe')),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Tic Tac Toe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              winner.isNotEmpty ? 'Winner: $winner' : '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  int row = index ~/ 3;
                  int col = index % 3;
                  return GestureDetector(
                    onTap: () => _makeMove(row, col),
                    child: Container(
                      color: widget.boardColor, // Set the background color
                      child: Center(
                        child: Text(
                          board[row][col],
                          style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                        ),
                      ),
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
}
