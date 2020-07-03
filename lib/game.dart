import 'dart:async';
import 'dart:math';

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:spritewidget/spritewidget.dart';
import 'package:flutter/rendering.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

ImageMap _images;
SpriteSheet _sprites;

class gameWindow extends StatefulWidget {
  @override
  _gameState createState() => new _gameState();

}

class _gameState extends State<gameWindow> {

  TimerManager timerManager = new TimerManager();
  bool assetsLoaded = false;

  Future<Null> _loadAssets(AssetBundle bundle) async {
    _images = new ImageMap(bundle);
    await _images.load(<String>[
      "assets/img/0.png",
      "assets/img/1.png",
      "assets/img/2.png",
      "assets/img/3.png",
      "assets/img/4.png",
      "assets/img/5.png",
      "assets/img/6.png",
      "assets/img/7.png",
      "assets/img/8.png",
      "assets/img/9.png",
      "assets/img/bigCactus1.png",
      "assets/img/bigCactus2.png",
      "assets/img/bigCactus3.png",
      "assets/img/bigCactus4.png",
      "assets/img/bird1.png",
      "assets/img/bird2.png",
      "assets/img/cactus1.png",
      "assets/img/cactus2.png",
      "assets/img/cactus3.png",
      "assets/img/cactus4.png",
      "assets/img/cactus5.png",
      "assets/img/cactus6.png",
      "assets/img/cloud.png",
      "assets/img/dino1.png",
      "assets/img/dino2.png",
      "assets/img/dinoDie1.png",
      "assets/img/dinoDie2.png",
      "assets/img/dinoDuck1.png",
      "assets/img/dinoDuck2.png",
      "assets/img/dinoWalk1.png",
      "assets/img/dinoWalk2.png",
      "assets/img/floor.png",
      "assets/img/gameover.png",
      "assets/img/highscore.png",
      "assets/img/longCactus.png",
      "assets/img/moon1.png",
      "assets/img/moon2.png",
      "assets/img/moon3.png",
      "assets/img/moon4.png",
      "assets/img/retry.png",
      "assets/img/star1.png",
      "assets/img/star2.png",
      "assets/img/star3.png",
      "assets/img/startingFrame.png",
    ]);
  }

  DinoContainer dinoc;
  TutorialManager tut;
  int seed = 0;
  bool started = false;

  @override
  void initState() {
    super.initState();

    tut = new TutorialManager(this);
    dinoc = new DinoContainer(this);

    AssetBundle bundle = rootBundle;

    _loadAssets(bundle).then((_) {
      setState(() {
        assetsLoaded = true;
      });
    });
  }

  var screenSize;
  double width = 0;
  double height = 0;
  ObstacleManager obsManager;

  void start() {

    screenSize = MediaQuery.of(context).size;
    width = screenSize.width;
    height = screenSize.height;

    obsManager = ObstacleManager();

    Random rnd = new Random();
    seed = rnd.nextInt(2000000000);

    // Obstacle Spawner Timer
    Duration intSpawner = Duration(milliseconds: (seed / 200000000 + 1000).toInt());
    Timer obstacleTimer = Timer.periodic(intSpawner, (Timer t){
      setState(() {
        if (!dinoc.obstacleIsRunning) {
          obsManager.nextObstacle(seed, dinoc.obstacleNum);
          spawnObstacle();
          dinoc.obstacleIsRunning = true;
          dinoc.obstacleNum++;
        }
      });
    });
    timerManager.timerList.add(obstacleTimer);

    // Collision Checker Timer
    Duration intCol = Duration(milliseconds: 10);
    Timer collisionTimer = Timer.periodic(intCol, (Timer t) {
      setState(() {
        Obstacle obs = obsManager.obstacles[obsManager.currentObs];
        if ((dinoc.obstaclePadding <= obs.lowPadding && dinoc.dinoHeight <= obs.lowHeight) ||
            (dinoc.obstaclePadding <= obs.highPadding && dinoc.dinoHeight <= obs.highHeight)) {
          if (!(obs.canDuckUnder && dinoc.ducking) || (obs.canDuckUnder && dinoc.dinoHeight > 10)) {
            die();
          }
        }
      });
    });
    timerManager.timerList.add(collisionTimer);

    // Walking Animation Timer
    const interval = const Duration(milliseconds: 200);
    Timer walkAnimTimer = Timer.periodic(interval, (Timer t) {
      setState(() {
        if (dinoc.walkFrame == 1) {
          dinoc.walkFrame = 2;
        } else {
          dinoc.walkFrame = 1;
        }
      });
    });
    timerManager.timerList.add(walkAnimTimer);
  }

  void reset() {
    setState(() {
      timerManager.cancelTimers();
      dinoc = new DinoContainer(this);
      started = false;
      build(context);
    });
  }

  void spawnObstacle() {
    double updateSpeed = (-1 * pow(5, -0.02 * dinoc.obstacleNum)) + 2.5;
    dinoc.obstaclePadding = 1000;

    // Obstacle mover Timer
    const interval = const Duration(milliseconds: 1);
    Timer obs = new Timer.periodic(interval, (Timer t) {
      setState(() {
        dinoc.obstaclePadding -= updateSpeed;
        if (dinoc.obstaclePadding <= 1) {
          dinoc.obstacleIsRunning = false;
          dinoc.obstaclePadding = 1000;
          t.cancel();
          timerManager.timerList.remove(t);
        }
      });
    });
    timerManager.timerList.add(obs);
  }

  void saveHighscore() async {
    if (dinoc.obstacleNum > getHighscore()) {
      var prefs = await SharedPreferences.getInstance();
      prefs.setInt("highscore", dinoc.obstacleNum);
    }
  }

  int _highscore = 0;

  int getHighscore() {
    _updateHighscore();
    return _highscore;
  }

  void _updateHighscore() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.get("highscore") != null) {
      _highscore =  prefs.get("highscore");
    } else {
      print("highscore was empty");
      _highscore = 0;
    }
  }

  void die() {
    saveHighscore();
    Vibration.vibrate();
    timerManager.cancelTimers();
    dinoc.died = true;
  }

  bool pressing = false;

  void jump(TapDownDetails details) {
    int heldUpCounter = 0;
    double lastHeight = 0;

    if (dinoc.dinoHeight == 0) {
      int x = -10;

      dinoc.dinoHeight = 1;

      // Jump Timer
      const interval = const Duration(milliseconds: 10);
      Timer jumpTimer = new Timer.periodic(interval, (Timer t) {
        setState(() {
          lastHeight = dinoc.dinoHeight;
          dinoc.dinoHeight += 10 + ((-10 * x * x) / 150);

          if (heldUpCounter < 10 && lastHeight > dinoc.minHoldJumpHeight &&
              pressing) {
            dinoc.dinoHeight = lastHeight;
            heldUpCounter++;
            x = 10;
          }

          if (dinoc.dinoHeight <= 0) {
            dinoc.dinoHeight = 0;
            t.cancel();
          }
        });
        x++;
      });
      timerManager.timerList.add(jumpTimer);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (!assetsLoaded) {
      return new Scaffold(
        body: Center(
          child: Text("Loading...")
        )
      );
    } else {
      return new Scaffold(
        body: Stack (
          children: [
            GestureDetector(
                onTap: () {
                  pressing = false;
                  dinoc.ducking = false;
                },
                onTapDown: (TapDownDetails details) {
                  setState(() {
                    if (!started) {
                      start();
                      started = true;
                    } else {
                      pressing = true;
                      if (!dinoc.died) {
                        if (details.globalPosition.dx < width / 2) {
                          jump(details);
                        } else {
                          dinoc.ducking = true;
                        }
                      }
                    }
                  });
                },
                child: dinoc.getContainer()
            ),
            tut.getTutorialRow()
          ],
        )
      );
    }
  }
}

class ObstacleManager {
  int currentObs = 0;
  List<Obstacle> obstacles;
  ObstacleManager() {
    obstacles = new List(); // dinoc.obstaclePadding <= 120 && dinoc.dinoHeight <= 20) || (dinoc.obstaclePadding <= 100 && dinoc.dinoHeight <= 20
    obstacles.add(new Obstacle("assets/img/longCactus.png", 0, 120, 20, 100, 80, false));
    obstacles.add(new Obstacle("assets/img/cactusArray1.png", 0, 140, 20, 120, 40, false));
    obstacles.add(new Obstacle("assets/img/cactusArray2.png", 0, 14+0, 20, 120, 40, false));
    obstacles.add(new Obstacle("assets/img/bigCactusArray1.png", 0, 100, 60, 80, 100, false));
    obstacles.add(new Obstacle("assets/img/bigCactusArray2.png", 0, 100, 60, 80, 100, false));
    obstacles.add(new Obstacle("assets/img/bird.gif", 70, 120, 80, 100, 500, true));
  }

  Obstacle getCurrentObs() {
    return obstacles[currentObs];
  }

  Obstacle nextObstacle(int seed, int obstacleNum) {
    currentObs = (((1 + seed / 2000000000) * obstacleNum) % obstacles.length).toInt();
    return obstacles[currentObs];
  }
}

class Obstacle {
  String sprite;
  int lowPadding;
  int lowHeight;
  int highPadding;
  int highHeight;
  bool canDuckUnder;
  int defaultHeight;

  Obstacle(sprite, defaultHeight, lowPadding, lowHeight, highPadding, highHeight, canDuckUnder) {
    this.sprite = sprite;
    this.defaultHeight = defaultHeight;
    this.lowPadding = lowPadding;
    this.lowHeight = lowHeight;
    this.highPadding = highPadding;
    this.highHeight = highHeight;
    this.canDuckUnder = canDuckUnder;
  }
}

class TutorialManager {
  _gameState state;
  TutorialManager(_gameState state) {
    this.state = state;
  }

  Row getTutorialRow() {
    if (state.started) {
      return Row(
        children: <Widget>[
          Flexible(
            child: Container(
              padding: EdgeInsets.all(50),
              alignment: Alignment.topRight,
              child: Text(
                  "Score: ${state.dinoc.obstacleNum}",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  )
              ),
            )
          )
        ],
      );
    }
    return Row(
      children: <Widget>[
        Flexible(
            fit: FlexFit.tight,
            child: Container(
                alignment: Alignment.center,
                child: Text(
                  "Jump",
                  style: TextStyle(
                      color: Colors.grey
                  ),
                )
            )
        ),
        Container(
          padding: EdgeInsets.all(100),
          width: 1,
          color: Colors.grey,
        ),
        Flexible(
            fit: FlexFit.tight,
            child: Stack(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Duck",
                    style: TextStyle(
                      color: Colors.grey
                    ),
                  )
                ),
                Container(
                  padding: EdgeInsets.all(50),
                  alignment: Alignment.topRight,
                  child: Text(
                    "Highscore: ${state.getHighscore()}",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    )
                  )
                )
              ],
            )
        )
      ],
    );
  }
}

class TimerManager {
  List<Timer> timerList;

  TimerManager() {
    timerList = new List();
  }

  void cancelTimers() {
    for (Timer t in timerList) {
      t.cancel();
    }
    timerList.clear();
  }
}

class DinoContainer {

  _gameState gameState;

  final int minHoldJumpHeight = 160;

  bool ducking = false;
  bool died = false;
  bool obstacleIsRunning = false;
  int obstacleNum = 0;
  int walkFrame = 2;
  String dinoSprite;
  String obstaclePath = "assets/img/longCactus.png";
  double rightObstaclePadding = 0;
  double obstaclePadding = 1000;
  double dinoHeight = 0;

  DinoContainer(_gameState gameState) {
    dinoSprite = "assets/img/dinoWalk$walkFrame.png";
    this.gameState = gameState;
  }

  String getDinoSprite() {
    if (!died) {
      if (ducking) {
        dinoSprite = "assets/img/dinoDuck$walkFrame.png";
      } else {
        dinoSprite = "assets/img/dinoWalk$walkFrame.png";
      }
    } else {
      dinoSprite = "assets/img/dinoDie1.png";
    }
    return dinoSprite;
  }

  void swapWalkFrame() {
    if (walkFrame == 1) {
      walkFrame = 2;
    } else {
      walkFrame = 1;
    }
  }

  Container getContainer() {
    if (!gameState.started) {
      return Container(
          alignment: FractionalOffset.center,
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.all(50.0),
            alignment: FractionalOffset.bottomLeft,
            child: Image.asset(
              "assets/img/startingFrame.png",
              scale: 5,
            ),
          )
      );
    } else {
      return Container(
          alignment: FractionalOffset.center,
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.fromLTRB(50, 50, 50, 50),
            alignment: FractionalOffset.bottomLeft,
            child: Stack(
              children: <Widget>[
                Container(
                  alignment: FractionalOffset.topLeft,
                  child: FlatButton(
                    onPressed: () {
                      gameState.reset();
                    },
                    child: Image.asset(
                      "assets/img/retry.png",
                      scale: 5,
                    ),
                  )
                ),
                Container(
                  alignment: FractionalOffset.bottomLeft,
                  padding: EdgeInsets.fromLTRB(obstaclePadding, 0, rightObstaclePadding, 4.0 + gameState.obsManager.getCurrentObs().defaultHeight),
                  child: Image.asset(
                      gameState.obsManager.getCurrentObs().sprite,
                      scale: 5
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      alignment: FractionalOffset.bottomLeft,
                      padding: EdgeInsets.fromLTRB(50, 0, 0, dinoHeight),
                      child: Image.asset(
                        getDinoSprite(),
                        scale: 5,
                      ),
                    ),
                    Container(
                        alignment: FractionalOffset.bottomLeft,
                        child: AnimatedContainer(
                          duration: Duration(seconds: 2),
                          child: Image.asset(
                            "assets/img/floor.png",
                            scale: 0.5,
                          ),
                        )
                    )
                  ],
                ),
              ],
            )
          )
      );
    }
  }
}