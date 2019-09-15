class Game
{
    public Game(PApplet p) //构造函数，读取各种资源。
    {
        textColor = color(0, 0, 0);
        sky = new PImage[4];
        sky[0] = loadImage("resource/sky1.jpg");
        sky[1] = loadImage("resource/sky2.jpg");
        sky[2] = loadImage("resource/sky3.jpg");
        sky[3] = sky[2];
        for(int i = 0; i < sky.length; i++){
          sky[i].resize(width, height);
        }
        bulletTexture = loadImage("resource/bullet.png");
        MedkitTexture = loadImage("resource/medkit.jpg");
        groundTexture = loadImage("resource/ground.jpg");
        playerShape = loadShape("resource/fish.obj");
        enemyShape1 = loadShape("resource/enemy_fish/white_fish/white_fish.obj");
        enemyShape2 = loadShape("resource/enemy_fish/yellow_fish/yellow_fish.obj");
        enemyShape3 = loadShape("resource/enemy_fish/green_fish/green_fish.obj");
        enemyShape4 = loadShape("resource/enemy_fish/blue_fish/blue_fish.obj");
        enemyShape5 = loadShape("resource/enemy_fish/red_fish/red_fish.obj");
        enemyShape6 = loadShape("resource/enemy_fish/black_fish/black_fish.obj");
        bossShape = loadShape("resource/boss.obj");
        treeShape = new PShape[3];
        treeShape[0] = loadShape("resource/tree.obj");
        treeShape[1] = loadShape("resource/tree1.obj");
        treeShape[2] = loadShape("resource/Haus.obj");
        minim = new Minim(p);
        bgms = new ArrayList(); // 0:Start, 1:Boss, 2:Win, 3:Over
        bgms.add(minim.loadFile("resource/BGM/Start.mp3"));
        bgms.add(minim.loadFile("resource/BGM/Boss.mp3"));
        bgms.add(minim.loadFile("resource/BGM/Win.mp3"));
        bgms.add(minim.loadFile("resource/BGM/GameOver.mp3"));
        launchSE = minim.loadFile("resource/SE/Launch.mp3");
        boomSE = minim.loadFile("resource/SE/Boom.mp3");
        boomSE2 = minim.loadFile("resource/SE/Boom.mp3");
        atkSE = minim.loadFile("resource/SE/Atk.mp3");
        rushSE = minim.loadFile("resource/SE/Rush.mp3");
        launchSE.setGain(3);
        rushSE.setGain(-3);
        boomSE.setGain(-1);
        boomSE2.setGain(-1);
        atkSE.setGain(3);
        bgms.get(0).setGain(-4);
        bgms.get(1).setGain(-1);
        bgms.get(2).setGain(-4);
        bgms.get(3).setGain(-1);
    }
    public void initGame() //初始化游戏
    {
        boomersPtr =  enemiesPtr = naturalAtksPtr = medkitsPtr
            = boomersSize = enemiesSize = naturalAtksSize = medkitsSize 
            = 0;
        surface.setTitle("3D Plane Fight");
        float rate = 24;//帧率设太高了的话，后面会感觉卡
        frameRate(rate);//设置帧率
        gameSpeed = 60.0 / rate;//根据帧率调整游戏速度
        println(gameSpeed);
        over = 0;
        darker = 0;
        launch = pause = false;
        bossScore = 150;//bossScore分后出现boss
        preBossScore = 50;//bossScore - preBossScore分之后切换场景，表明boss快到了
        bossLife = 1000;//bossLife为boss血量

        if(debug) //调试时用另一组数据
        {
            bossScore = 2;
            preBossScore = 1;
            bossLife = 15;
        }
        boss = null;//此时boss还没出场
        altitude = 50;//地形的高度
        bulletVelocity = 12 * gameSpeed;//玩家射击频率
        playerVelocity = 2 * gameSpeed;//玩家控制速度
        mapVelocity = 0.05 * gameSpeed;//地形移动速度
        enemyVelocity = 1.25 * gameSpeed;//小怪移动速度
        score = 0;//初始分数
        enemies = new Enemy[16];//小怪列表
        initObj(enemies);
        boomers = new Boomer[16];//爆炸效果列表
        initObj(boomers);
        keyCodeStack = new ArrayList<Integer>();//方向栈
        naturalAtks = new Atk[16];//地图外攻击列表
        initObj(naturalAtks);
        medkits = new Medkit[4];//地图外医疗包列表
        initObj(medkits);
        addEnemies(new Enemy());//添加一个小怪
        //enemies.add(new Enemy());//添加一个小怪
        player = new Player();//初始化玩家
        field = new Field(0, 0, width / 10, height / 10, 10);//设置地形
        lifeColor = new color[player.life + 1];//默认血量为5，每格血量对应一种血条颜色
        for(int i = 0; i < lifeColor.length; i++)
        {
            lifeColor[i] = color(220 - 40 * i, 100 + 30 * i, 80 + 25 * i);
        }
        medkit_count = 0;
        stopBGMs();//如果是重新开始时调用的该函数，则需要先停止声音播放
        stopBoomSE();
    }
    public void run()
    {
        lightSettings();//背景、灯光控制
        cameraSettings();//摄像头控制
        field.draw();//绘制地形
        player.draw();//绘制玩家
        drawAndUpdateEnemies();//小怪的相关操作，包括绘制、移动、判断碰撞
        drawAndUpdateBossOrNot();//这里把“如果boss还没出来”时的播放背景音乐的操作也放进去了
        otherStatesOfGame();//游戏结束或暂停时的操作
        drawScore();//绘制分数
        drawLake();//绘制湖面
        drawAndUpdateBoomers();
        drawAndUpdateNaturalAtks();
        naturalMedkit();
        drawAndUpdateMedkit();
        field.makeNoise(-altitude, altitude);//地形移动
        ctrl();//控制方向
    }
    void ctrl() //控制方向，这里使用了栈存储玩家按下了哪些控制方向的键
    {
        if(pause)return;
        for(int i = keyCodeStack.size() - 1; i >= 0; i--)
        {
            switch(keyCodeStack.get(i))
            {
            case SHIFT:
                player.move(0, 0, playerVelocity);
                break;
            case CONTROL:
                player.move(0, 0, -playerVelocity);
                break;
            case UP:
                player.move(0, -playerVelocity, 0);
                break;
            case DOWN:
                player.move(0, playerVelocity, 0);
                break;
            case LEFT:
                player.move(-playerVelocity, 0, 0);
                break;
            case RIGHT:
                player.move(playerVelocity, 0, 0);
                break;
            }
        }
    }
    void lightSettings() //背景、灯光控制
    {
        //color c;
        if(darker == 3){
            //c = color(20, 20, 35);
            ambientLight(32, 32, 32);
            directionalLight(64, 64, 64, 0, 0, -1);
            lightSpecular(20, 20, 20);
            for(int i = 0; i < 5; i++){
                spotLight(255, 255, 255, random(width * 0.1, width * 0.9), random(height * 0.1, height * 0.9), altitude * 6, 0, 0, -1, radians(30), 500);
            }
        }
        else if(darker == 2){
            //c = color(65, 55, 85);
            ambientLight(64, 64, 64);
            directionalLight(96, 96, 96, 0, 0, -1);
            spotLight(128, 128, 128, width / 2, height / 2, altitude * 6, 0, 1, -1, HALF_PI, 4);
            lightSpecular(20, 20, 20);
        }
        else if(darker == 1){
            //c = color(230, 130, 85);
            ambientLight(96, 96, 96);
            directionalLight(128, 128, 128, 0, 0, -1);
            spotLight(144, 144, 144, width / 2, 0, altitude * 6, 0, 1, -1, HALF_PI, 2);
            lightSpecular(20, 20, 20);
        }
        else{
            //c = color(100, 200, 255);
            ambientLight(128, 128, 128);
            directionalLight(144, 144, 144, 0, 0, -1);
            spotLight(192, 192, 192, width / 2, 0, altitude * 6, 0, 1, -1, HALF_PI, 2);
            lightSpecular(20, 20, 20);
        }
        background(sky[darker]);
    }
    void cameraSettings() //控制摄像头视角
    {
        beginCamera();
        camera();
        translate(0, 0, -100);
        rotateX(radians(45));
        endCamera();
    }
    void drawLake(){//绘制湖面
        pushMatrix();
        tint(255, 126);//alpha = 126，半透明
        specular(255, 255, 255);//设置了镜面反射的材质，不过贴图后好像没用
        translate(0, 0, -altitude * 0.1875 + altitude * 0.09375 * sin(radians(frameCount * gameSpeed * 0.5)));//正弦函数是为了让水面看起来有点波动，不过中间的湖面有波动也可能有点奇怪
        image(sky[darker], 0, 0, width, height);
        popMatrix();
    }
    void addEnemies() //boss战前调用，生成小怪
    {
        //for(int j = 0; j <= floor(log(score + 1) / log(10)) && enemies.size() < 10; j++)
        while(enemiesSize <= floor(log(score + 1) / log(4)))
        {
            addEnemies(new Enemy());
            if(score + preBossScore >= bossScore)
            {
                if(boss == null)game.darker = 1;
                float x = game.player.loc.x, z = game.player.loc.z;
                addNaturalAtks(new Atk(new PVector(
                                                 min(width * 0.9, max(width * 0.1, map(randomGaussian(), -3, 3, x - width * 0.05, x + width * 0.05))),
                                                 height * 0.2,
                                                 min(game.altitude * 3.9, max(game.altitude * 1.1, map(randomGaussian(), -3, 3, z - game.altitude * 0.3, z + game.altitude * 0.3)))
                                             ), new PVector(0, 2 * game.enemyVelocity, 0)
                                            ));
            }
        }
    }
    public void naturalAttack() //来自地图外的攻击
    {
        float x = player.loc.x, z = player.loc.z;
        addNaturalAtks(new Atk(new PVector(
                                    min(width * 0.9, max(width * 0.1, map(randomGaussian(), -3, 3, x - width * 0.05, x + width * 0.05))),
                                    height * 0.2,
                                    min(altitude * 3.9, max(altitude * 1.1, map(randomGaussian(), -3, 3, z - altitude * 0.3, z + altitude * 0.3)))
                                ), new PVector(0, 2 * enemyVelocity, 0)
                               ));
    }
    void drawAndUpdateEnemies()
    {
        for(int i = 0; i < enemies.length; i++)
        {
            if(enemies[i] == null)continue;
            enemies[i].draw();
            if(!pause)enemies[i].move();
            if(!pause)enemies[i].launch();
            if(enemies[i].outOfRange())
            {
                removeFromEnemies(i);
                if(score < bossScore)
                {
                    addEnemies();
                }
                else if(boss == null)
                {
                    boss = new Boss(bossLife);
                }
                continue;
            }
            for(int j = 0; j < player.bullets.length; j++)
            {
                if(player.bullets[j] == null)continue;
                if(!enemies[i].crash && collision(enemies[i], player.bullets[j]))
                {
                    boom(player.bullets[j].loc);
                    player.removeFromBullets(j);
                    enemies[i].crash = true;
                    score++;
                    break;
                }
            }
        }
    }
    void drawAndUpdateBoomers()
    {
        for(int i = 0; i < boomers.length; i++)
        {
            if(boomers[i] == null)continue;
            if(boomers[i].life <= 0)
            {
                removeFromBoomers(i);
                continue;
            }
            boomers[i].draw();
        }
    }
    void drawAndUpdateNaturalAtks()
    {
        for(int i = 0; i < naturalAtks.length; i++)
        {
            if(naturalAtks[i] == null)continue;
            naturalAtks[i].draw();
            if(!pause)naturalAtks[i].update();
            if(collision(player, naturalAtks[i]))
            {
                player.hurt();
            }
            if(naturalAtks[i].over())
            {
                removeFromNaturalAtks(i);
                continue;
            }
        }
    }
    public void naturalMedkit() //来自地图外的医疗包
    {
        if (medkit_count < 1000)
        {
            if(!pause && over == 0)medkit_count++;
            return;
        }
        medkit_count = 0;
        float x = player.loc.x, z = player.loc.z;
        addMedkits(new Medkit(new PVector(
                                   min(width * 0.9, max(width * 0.1, map(randomGaussian(), -3, 3, x - width * 0.05, x + width * 0.05))),
                                   height * 0.2,
                                   min(altitude * 3.9, max(altitude * 1.1, map(randomGaussian(), -3, 3, z - altitude * 0.3, z + altitude * 0.3)))
                               ), new PVector(0, enemyVelocity, 0)
                              ));
    }
    void drawAndUpdateMedkit()
    {
        for(int i = 0; i < medkits.length; i++)
        {
            if(medkits[i] == null)continue;
            medkits[i].draw();
            if(!pause)medkits[i].update();
            if(collision(player, medkits[i]))
            {
                player.heal();
                removeFromMedkits(i);
                continue;
            }
            else if(medkits[i].over())
            {
                removeFromMedkits(i);
                continue;
            }
        }
    }
    void drawAndUpdateBossOrNot()
    {
        if(boss != null)
        {
            if(boss.state == 0)stopBGMs();
            boss.draw();
            if(!pause)boss.move();
            for(int j = 0; j < player.bullets.length; j++)
            {
                if(player.bullets[j] == null)continue;
                if(boss.state > 0 && collision(boss, player.bullets[j]))
                {
                    boom(player.bullets[j].loc);
                    player.removeFromBullets(j);
                    boss.hurt();
                    break;
                }
            }
            if(boss.state == -1 && boss.loc.z < -altitude)
            {
                boss = null;
                if(over == 0)
                {
                    stopBGMs();
                    over = 2;
                }
            }
        }
        else if(over == 0)
        {
            playStartBGMLoop();
        }
        if(!pause && over == 0)
        {
            if(!debug)
                surface.setTitle("3D Plane Fight");
                //surface.setTitle("3D Plane Fight[fps:" + frameRate + "]");
        }
    }
    void otherStatesOfGame()
    {
        if(over == 1)
        {
            keyCodeStack.clear();
            launch = false;
            drawOver();
            stopBGMs();
            playOverBGM();
            stopBoomSE();
        }
        if(over == 2)
        {
            keyCodeStack.clear();
            launch = false;
            drawWin();
            playWinBGM();
            stopBoomSE();
        }
        if(pause)
        {
            keyCodeStack.clear();
            launch = false;
            drawPause();
        }
    }
    void boom(PVector loc) //产生爆炸，即爆炸列表中新增一个实例
    {
        addBoomers(new Boomer(5, loc));
    }
    boolean collision(Plane a, Player b) //敌人与玩家的碰撞检测
    {
        return over == 0 && abs(a.loc.x - b.loc.x) < a.rb2.x * a.size + b.rb2.x * b.size
               && abs(a.loc.y - b.loc.y) < a.rb2.y * a.size + b.rb2.y * b.size
               && abs(a.loc.z - b.loc.z) < a.rb2.z * a.size + b.rb2.z * b.size;
    }
    boolean collision(Plane a, Particle b) //飞机与粒子的碰撞检测
    {
        return over == 0 && abs(a.loc.x - b.loc.x) < a.rb2.x * a.size + b.size
               && abs(a.loc.y - b.loc.y) < a.rb2.y * a.size + b.size
               && abs(a.loc.z - b.loc.z) < a.rb2.z * a.size + b.size;
    }
    void drawOver() //失败时绘制相关信息
    {
        surface.setTitle("3D Plane Fight(Game Over)");
        textMode(SHAPE);
        textAlign(CENTER, CENTER);
        textSize(22);
        pushMatrix();
        translate(width * 0.5, height * 0.8, altitude * 3);
        rotateX(radians(-45));
        fill(textColor);
        text("Game Over", 0, 0, 0);
        rotateX(radians(45));
        translate(0, height * 0.1, 0);
        rotateX(radians(-45));
        text("Enter To Restart", 0, 0, 0);
        popMatrix();
    }
    void drawWin() //胜利时绘制相关信息
    {
        surface.setTitle("3D Plane Fight(Win)");
        textMode(SHAPE);
        textAlign(CENTER, CENTER);
        textSize(22);
        pushMatrix();
        translate(width * 0.5, height * 0.8, altitude * 3);
        rotateX(radians(-45));
        fill(textColor);
        text("Win. Score: " + score, 0, 0, 0);
        rotateX(radians(45));
        translate(0, height * 0.1, 0);
        rotateX(radians(-45));
        text("Enter To Restart", 0, 0, 0);
        popMatrix();
    }
    void drawPause() //暂停时绘制相关信息
    {
        surface.setTitle("3D Plane Fight(Pause)");
        textMode(SHAPE);
        textAlign(CENTER, CENTER);
        textSize(22);
        pushMatrix();
        translate(width * 0.5, height * 0.8, altitude * 3);
        rotateX(radians(-45));
        fill(textColor);
        text("Pause", 0, 0, 0);
        rotateX(radians(45));
        translate(0, height * 0.1, 0);
        rotateX(radians(-45));
        text("Press 'P' To Resume", 0, 0, 0);
        popMatrix();
    }
    void drawScore() //绘制分数
    {
        textMode(SHAPE);
        textAlign(RIGHT, TOP);
        textSize(32);
        pushMatrix();
        rotateX(radians(-45));
        fill(textColor);
        text("Score: " + score, width, 0, altitude * 2);
        popMatrix();
    }

    void stopBGMs() //停止所有背景音乐（不包括音效）
    {
        for(int i = 0; i < bgms.size(); i++){
          bgms.get(i).pause();
        }
    }
    void playStartBGMLoop() //循环播放第一段背景音乐
    {
        if(bgms.get(0).isPlaying())return;
        for(int i = 0; i < bgms.size(); i++){
          bgms.get(i).rewind();
        }
        bgms.get(0).loop();
    }
    void playBossBGMLoop() //循环播放boss战背景音乐
    {
        if(bgms.get(1).isPlaying())return;
        for(int i = 0; i < bgms.size(); i++){
          bgms.get(i).rewind();
        }
        bgms.get(1).loop();
    }
    void playWinBGM() //单次播放胜利背景音乐
    {
        if(bgms.get(2).isPlaying())return;
        for(int i = 0; i < bgms.size(); i++){
          if(i == 2)continue;
          bgms.get(i).rewind();
        }
        bgms.get(2).play();
    }
    void playOverBGM() //单次播放失败背景音乐
    {
        if(bgms.get(3).isPlaying())return;
        for(int i = 0; i < bgms.size(); i++){
          if(i == 3)continue;
          bgms.get(i).rewind();
        }
        bgms.get(3).play();
    }
    void playRushSEOnceNotRewind() //单次播放boss移动的音效
    {
        if(rushSE.isPlaying())return;
        rushSE.play();
    }
    void resetRushSE() //重置boss移动的音效
    {
        rushSE.rewind();
        rushSE.pause();
    }
    void playAtkSE() //播放boss射击的音效
    {
        atkSE.rewind();
        atkSE.play();
    }
    void playBoomSELoop() //循环播放爆炸音效（仅打败boss时播放，否则吃不消）
    {
        if(boomSE.isPlaying()){
          if(boomSE.position() > 800){
            if(boomSE2.isPlaying())return;
            boomSE2.rewind();
            boomSE2.loop();
          }
          return;
        }
        stopBGMs();
        boomSE.rewind();
        boomSE.loop();
    }
    void stopBoomSE() //停止爆炸音效（boss消失后需停止）
    {
        boomSE.pause();
        boomSE2.pause();
    }
    void playLaunchSE() //播放玩家射击音效
    {
        launchSE.rewind();
        launchSE.play();
    }
    void addBoomers(Boomer b)
    {
        if(!checkList(boomers, boomersSize))return;
        boomers[boomersPtr] = b;
        while(boomers[boomersPtr] != null){
            boomersPtr = (boomersPtr + 1) & (boomers.length - 1);
        }
        boomersSize++;
        if(debug)println("boomersSize = " + boomersSize);
    }
    void removeFromBoomers(int i)
    {
        boomers[i] = null;
        boomersSize--;
    }
    void addEnemies(Enemy e)
    {
        if(!checkList(enemies, enemiesSize))return;
        enemies[enemiesPtr] = e;
        while(enemies[enemiesPtr] != null){
            enemiesPtr = (enemiesPtr + 1) & (enemies.length - 1);
        }
        enemiesSize++;
        if(debug)println("enemiesSize = " + enemiesSize);
    }
    void removeFromEnemies(int i)
    {
        enemies[i] = null;
        enemiesSize--;
    }
    void addNaturalAtks(Atk a)
    {
        if(!checkList(naturalAtks, naturalAtksSize))return;
        naturalAtks[naturalAtksPtr] = a;
        while(naturalAtks[naturalAtksPtr] != null){
            naturalAtksPtr = (naturalAtksPtr + 1) & (naturalAtks.length - 1);
        }
        naturalAtksSize++;
        if(debug)println("nAtksSize = " + naturalAtksSize);
    }
    void removeFromNaturalAtks(int i)
    {
        naturalAtks[i] = null;
        naturalAtksSize--;
    }
    void addMedkits(Medkit m)
    {
        if(!checkList(medkits, medkitsSize))return;
        medkits[medkitsPtr] = m;
        while(medkits[medkitsPtr] != null){
            medkitsPtr = (medkitsPtr + 1) & (medkits.length - 1);
        }
        medkitsSize++;
    }
    void removeFromMedkits(int i)
    {
        medkits[i] = null;
        medkitsSize--;
    }
    void initObj(Object[] objs)
    {
        for(int i = 0; i < objs.length; i++){
            objs[i] = null;
        }
    }
    boolean checkList(Object[] objs, int objsSize)
    {
        if(objsSize >= objs.length - 1)return false;
        return true;
    }
    color lifeColor[];//血条颜色
    boolean launch, pause;//控制射击、控制暂停的变量
    int score, bossScore, preBossScore, over;//各种分数，游戏状态（开始/胜利/失败）
    Field field;//地形
    Player player;//玩家
    color textColor;//文字显示颜色
    PImage groundTexture, bulletTexture, MedkitTexture, sky[];//地形贴图，子弹贴图，医疗包贴图，天空贴图
    PShape playerShape, bossShape, treeShape[];//玩家模型，敌人模型，boss模型，植被、房子模型
    PShape enemyShape1, enemyShape2, enemyShape3, enemyShape4, enemyShape5, enemyShape6;
    Boomer boomers[];//爆炸效果列表
    int boomersPtr, boomersSize;
    Enemy enemies[];//敌人列表
    int enemiesPtr, enemiesSize;
    ArrayList<Integer> keyCodeStack;//方向键栈
    Atk naturalAtks[];//地图外攻击列表
    int naturalAtksPtr, naturalAtksSize;
    Medkit medkits[];//地图外医疗包列表
    int medkitsPtr, medkitsSize;
    Minim minim;//读取声音用的第三方类
    ArrayList<AudioPlayer> bgms;//背景音乐列表
    AudioPlayer launchSE, boomSE, boomSE2, atkSE, rushSE;//各种音效
    float altitude, mapVelocity, enemyVelocity, playerVelocity, bulletVelocity;//地形高度，各种速度
    Boss boss;//boss
    int darker;//场景灯光控制变量
    int bossLife;//boss血量
    float gameSpeed;//游戏运行速度的系数
    int medkit_count;//用于医疗包出现
};