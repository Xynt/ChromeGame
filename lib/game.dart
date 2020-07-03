import 'dart:async';
import 'dart:math';

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:spritewidget/spritewidget.dart';
import 'package:flutter/rendering.dart';


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

  dinoContainer dinoc;
  int seed = 0;
  bool started = false;

  @override
  void initState() {

    dinoc = new dinoContainer(this);
    super.initState();

    AssetBundle bundle = rootBundle;

    _loadAssets(bundle).then((_) {
      setState(() {
        assetsLoaded = true;
      });
    });
  }

  void startTimers() {

    Random rnd = new Random();
    seed = rnd.nextInt(2000000000);

    Duration intSpawner = Duration(milliseconds: (seed / 200000000 + 1000).toInt());
    Timer obstacleTimer = Timer.periodic(intSpawner, (Timer t){
      setState(() {
        if (!dinoc.obstacleIsRunning) {
          spawnObstacle();
          dinoc.obstacleIsRunning = true;
          dinoc.obstacleNum++;
        }
      });
    });
    timerManager.timerList.add(obstacleTimer);

    Duration intCol = Duration(milliseconds: 10);

    Timer collisionTimer = Timer.periodic(intCol, (Timer t) {
      setState(() {
        if ((dinoc.obstaclePadding <= 120 && dinoc.dinoHeight <= 20) || (dinoc.obstaclePadding <= 100 && dinoc.dinoHeight <= 20)) {
          die();
        }
      });
    });
    timerManager.timerList.add(collisionTimer);

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
      dinoc = new dinoContainer(this);
      started = false;
      build(context);
    });
  }

  void spawnObstacle() {
    double updateSpeed = (-1 * pow(5, -0.02 * dinoc.obstacleNum)) + 2.5;
    dinoc.obstaclePadding = 1000;
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

  void die() {
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
        body: GestureDetector(
          onTap: () {
            pressing = false;
          },
          onTapDown: (TapDownDetails details) {
            setState(() {
              if (!started) {
                startTimers();
                started = true;
              } else {
                pressing = true;
                jump(details);
              }
            });
          },
          child: dinoc.getContainer()
        )
      );
    }
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

class dinoContainer {

  _gameState gameState;

  final int minHoldJumpHeight = 160;

  bool died = false;
  bool obstacleIsRunning = false;
  int obstacleNum = 0;
  int walkFrame = 2;
  String dinoSprite;
  String obstaclePath = "assets/img/longCactus.png";
  double rightObstaclePadding = 0;
  double obstaclePadding = 1000;
  double dinoHeight = 0;

  dinoContainer(_gameState gameState) {
    dinoSprite = "assets/img/dinoWalk$walkFrame.png";
    this.gameState = gameState;
  }

  String getDinoSprite() {
    if (!died) {
      dinoSprite = "assets/img/dinoWalk$walkFrame.png";
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
                  padding: EdgeInsets.fromLTRB(obstaclePadding, 0, rightObstaclePadding, 4),
                  child: Image.asset(
                      "assets/img/longCactus.png",
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