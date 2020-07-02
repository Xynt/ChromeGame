import 'dart:async';

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

    const interval = const Duration(milliseconds: 200);
    new Timer.periodic(interval, (Timer t) {
      setState(() {
        dinoc.swapWalkFrame();
        dinoc.gameState.build(dinoc.gameState.context);
      });
    });
  }

  void spawnObstacle() {
    const interval = const Duration(milliseconds: 10);
    new Timer.periodic(interval, (Timer t) {
      setState(() {
        dinoc.obstaclePadding--;

        if (dinoc.obstaclePadding <= 0) {
          dinoc.obstaclePadding = 1000;
          t.cancel();
        }
      });
    });
  }

  bool pressing = false;

  void jump(TapDownDetails details) {

    int heldUpCounter = 0;
    double lastHeight = 0;

    if (dinoc.dinoHeight == 0) {
      int x = -10;

      dinoc.dinoHeight = 1;

      const interval = const Duration(milliseconds: 10);
      new Timer.periodic(interval, (Timer t){
        setState(() {
          lastHeight = dinoc.dinoHeight;
          dinoc.dinoHeight += 10 + ((-10 * x * x) / 150);

          if (heldUpCounter < 10 && lastHeight > dinoc.minHoldJumpHeight && pressing) {
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
    }
  }
  bool started = false;

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

class dinoContainer {

  _gameState gameState;

  final int minHoldJumpHeight = 160;

  String obstaclePath = "assets/img/longCactus.png";
  double obstaclePadding = 1000;
  double dinoHeight = 0;
  int walkFrame = 2;

  dinoContainer(_gameState gameState) {
    this.gameState = gameState;
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
                  alignment: FractionalOffset.bottomLeft,
                  padding: EdgeInsets.fromLTRB(120, 0, 0, 4),
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
                      padding: EdgeInsets.fromLTRB(20, 0, 0, dinoHeight),
                      child: Image.asset(
                        "assets/img/dinoWalk$walkFrame.png",
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