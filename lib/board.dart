import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tetris/piece.dart';
import 'package:tetris/pixel.dart';
import 'package:tetris/values.dart';

/*
Game Board 
This is a 2x2 grid with null representing an empty space. 
A non empty space will have the color to represent the landed pieces

*/

// create game board
List<List<Tetromino?>> gameBoard = List.generate(
    colLength,
    (i) => List.generate(
          rowLength,
          (j) => null,
        ));

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // current tetris piece
  // Piece currentPiece = Piece(type: Tetromino.O);
  Random rand = Random();
  late Piece currentPiece;
  // current score
  int currentScore = 0;

  //game over status
  bool gameOver = false;
  @override
  void initState() {
    super.initState();
    createNewPiece();
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    Duration frameRate = const Duration(milliseconds: 400);
    gameloop(frameRate);
  }

  void gameloop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        // clear the lines
        clearLines();
        //  check landing
        checkLanding();
        // move current piece down

        // check if game is over
        if (isGameOver() == true) {
          timer.cancel();
          showGameOverDialog();
        }

        currentPiece.movePiece(Direction.down);
      });
    });
  }

  // game over message
  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text("Your score is $currentScore"),
        actions: [
          TextButton(
              onPressed: () {
                resetGame();
                Navigator.pop(context);
              },
              child: const Text('Play Again'))
        ],
      ),
    );
  }

  // Reset game
  void resetGame() {
    // clear the game board
    gameBoard = List.generate(
        colLength,
        (i) => List.generate(
              rowLength,
              (j) => null,
            ));
    // new game
    gameOver = false;
    currentScore = 0;

    createNewPiece();

    startGame();
  }

  // check for collision in future
  // return true if collision
  // return false if no collision
  bool checkCollision(Direction direction) {
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      // adjust the row and col based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      // check if the place is out of bounds (either too low or too far to the left or right)
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      }
      if (row >= 0 && col >= 0 && gameBoard[row][col] != null) {
        return true;
      }
    }
    // if no collision are detectedd, return false
    return false;
  }

  void checkLanding() {
    // if going down is occupied
    if (checkCollision(Direction.down)) {
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;
        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      createNewPiece();
    }
  }

  void createNewPiece() {
    Random rand = Random();

    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    /*
    since our game over condition is if there is a piece at the top level,
    you want to check if the game is over when u create a new piece
    instead of checking every frame, because new pieces are allowed to go through the top level
    but if there is already a piece in the top level when the new piece is created,
    then the game is over
    */
    if (isGameOver()) {}
  }

  // move left
  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  // move right
  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  // rotate
  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  // clear lines
  void clearLines() {
    // Loop throught each row of the game board from bottom to top
    for (int row = colLength - 1; row >= 0; row--) {
      // initialise a variable to track if the row is full
      bool rowIsFull = true;

      // check if the row is full
      for (int col = 0; col < rowLength; col++) {
        // if there's an empty column, set rowIsfull to false and break the loop
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }
      // if the row is full clear the row and shift rows down
      if (rowIsFull) {
        // move all rows above the cleared row down by one position
        for (int r = row; r > 0; r--) {
          // copy the above row to the current row
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }
        // set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        // increase the score
        currentScore++;
      }
    }
  }

  bool isGameOver() {
    // check if any columns in the top row are filled
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) {
        return true;
      }
    }
    // if the top row is empty, the game is not over
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // GAME
          Expanded(
            child: GridView.builder(
                itemCount: rowLength * colLength,
                // physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowLength),
                itemBuilder: (context, index) {
                  int row = (index / rowLength).floor();
                  int col = index % rowLength;

                  // current piece
                  if (currentPiece.position.contains(index)) {
                    return Pixel(
                      color: currentPiece.color,
                    );
                  }
                  // landed piece
                  else if (gameBoard[row][col] != null) {
                    final Tetromino? tetrominoType = gameBoard[row][col];
                    return Pixel(
                      color: tetrominoColors[tetrominoType],
                    );
                  }
                  // blank pixel
                  else {
                    return Pixel(color: Colors.grey[900]);
                  }
                }),
          ),
          // Score
          Text(
            "Score: $currentScore",
            style: const TextStyle(color: Colors.white),
          ),
          // CONTROLS
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, top: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // left
                IconButton(
                    onPressed: moveLeft,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_ios)),

                // rotate
                IconButton(
                    onPressed: rotatePiece,
                    color: Colors.white,
                    icon: const Icon(Icons.rotate_right)),

                // right
                IconButton(
                    onPressed: moveRight,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_forward_ios)),

                // // Restart
                // IconButton(onPressed: resetGame, icon: Icon(Icons.restart_alt))
              ],
            ),
          )
        ],
      ),
    );
  }
}
