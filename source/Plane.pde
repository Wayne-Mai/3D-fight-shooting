class Plane
{
    public Plane()
    {
        shape = null;
        rb1 = new PVector(-30, -75, -24);
        rb2 = new PVector(30, 75, 24);
    }
    public Plane(float x, float y, float z, float size)
    {
        this.loc = new PVector(x, y, z);
        this.size = size;
        shape = null;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        scale(size);
        shape(shape, 0, 0);
        popMatrix();
    }
    public void drawBox(int r, int g, int b, int a) //绘制碰撞判定长方体，调试或硬直时绘制
    {
        fill(r, g, b, a);
        beginShape(QUADS);
        vertex(rb1.x, rb1.y, rb1.z);
        vertex(rb1.x, rb2.y, rb1.z);
        vertex(rb1.x, rb2.y, rb2.z);
        vertex(rb1.x, rb1.y, rb2.z);
        endShape(CLOSE);
        beginShape(QUADS);
        vertex(rb2.x, rb1.y, rb1.z);
        vertex(rb2.x, rb2.y, rb1.z);
        vertex(rb2.x, rb2.y, rb2.z);
        vertex(rb2.x, rb1.y, rb2.z);
        endShape(CLOSE);
        beginShape(QUADS);
        vertex(rb1.x, rb1.y, rb1.z);
        vertex(rb1.x, rb1.y, rb2.z);
        vertex(rb2.x, rb1.y, rb2.z);
        vertex(rb2.x, rb1.y, rb1.z);
        endShape(CLOSE);
        beginShape(QUADS);
        vertex(rb1.x, rb2.y, rb1.z);
        vertex(rb1.x, rb2.y, rb2.z);
        vertex(rb2.x, rb2.y, rb2.z);
        vertex(rb2.x, rb2.y, rb1.z);
        endShape(CLOSE);
        beginShape(QUADS);
        vertex(rb1.x, rb1.y, rb1.z);
        vertex(rb1.x, rb2.y, rb1.z);
        vertex(rb2.x, rb2.y, rb1.z);
        vertex(rb2.x, rb1.y, rb1.z);
        endShape(CLOSE);
        beginShape(QUADS);
        vertex(rb1.x, rb1.y, rb2.z);
        vertex(rb1.x, rb2.y, rb2.z);
        vertex(rb2.x, rb2.y, rb2.z);
        vertex(rb2.x, rb1.y, rb2.z);
        endShape(CLOSE);
    }
    PVector loc, rb1, rb2;//rb1和rb2是碰撞判定长方体的两个对角关系的顶点
    float size;
    PShape shape;
};
class Player extends Plane //玩家，继承飞机的类
{
    public Player()
    {
        this.loc = new PVector(
            width * 0.5,
            height * 0.8,
            game.altitude * 2
        );
        this.flash = this.launchCount = 0;
        this.bullets = new Bullet[32];
        game.initObj(bullets);
        this.bulletsPtr = this.bulletsSize = 0;
        this.size = 0.25;
        this.life = 5;
        this.Large_life = 50;
        this.dynamic_life = this.Large_life;
        shape = game.playerShape;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        rotateZ(PI);//和敌人是镜像的，所以绕z轴旋转
        scale(size);
        shape(shape, 0, 0);
        if(game.launch) //可以射击
        {
            launch();
        }
        if(debug)drawBox(0, 255, 0, 50);
        if(flash > 0) //硬直时绘制
        {
            emissive(196, 196, 196);
            drawBox(0, 0, 255, 50);
            emissive(0);
        }
        drawLife();//绘制血条
        popMatrix();
        drawAndUpdateBullets();
        if(!game.pause && flash > 0)flash--;//硬直时减少硬直时间
    }
    public void move(float dx, float dy, float dz)
    {
        loc.add(dx, dy, dz);
        if(!(loc.x < width * 0.9 && loc.x > width * 0.1
                && loc.y < height && loc.y > 0
                && loc.z > game.altitude * 1.1 && loc.z < game.altitude * 3.9))
        {
            loc.sub(dx, dy, dz);
        }//位置不合法时撤销移动
    }
    public void heal() //玩家获得医疗包
    {
        if (flash <= floor(frameRate) * 3)
        {
            life = 5;
            Large_life = 50;
            flash = floor(frameRate) * 3;
        }
    }
    public void hurt() //玩家受伤后的操作
    {
        if(flash <= 0)
        {
            life--;
            Large_life -= 10;
            if(life <= 0)
            {
                game.over = 1;
            }
            flash = floor(frameRate) * 3;
        }
    }
    void launch() //发射子弹
    {
        if(floor(launchCount * game.gameSpeed) % 10 == 0)
        {
            addBullets(new Bullet(PVector.add(loc, new PVector(0, rb1.y * size, 0)), new PVector(0, -game.bulletVelocity, 0)));
            game.playLaunchSE();
        }
        launchCount++;
    }
    void drawAndUpdateBullets()
    {
        for(int i = 0; i < bullets.length; i++)
        {
            if(bullets[i] == null)continue;
            bullets[i].draw();
            if(!game.pause)bullets[i].update();
            if(bullets[i].loc.y <= 0)
            {
                removeFromBullets(i);
                continue;
            }
        }
    }
    void life_change()
    {
        if (dynamic_life == Large_life)
            return;
        if (dynamic_life > Large_life)
            dynamic_life -= 1;
        else if (dynamic_life < Large_life)
            dynamic_life += 1;
    }
    void drawLife()
    {
        translate(0, rb1.y * size * 5, rb2.z * size * 8);
        rotateX(radians(135));
        rotateZ(PI);
        translate(rb1.x * size * 10, 0, 0);
        noFill();
        stroke(0, 0, 0);
        strokeWeight(2);
        beginShape();
        vertex(0, 0, rb2.x * size * 4);
        vertex(rb2.x * size * 20, 0, rb2.x * size * 4);
        vertex(rb2.x * size * 20, 0, 0);
        vertex(0, 0, 0);
        endShape(CLOSE);
        fill(game.lifeColor[life]);
        noStroke();
        beginShape();
        life_change();
        vertex(0, 0, rb2.x * size * 4);
        vertex(rb2.x * size * 4 * dynamic_life / 10.0, 0, rb2.x * size * 4);
        vertex(rb2.x * size * 4 * dynamic_life / 10.0, 0, 0);
        vertex(0, 0, 0);
        endShape(CLOSE);
    }
    void addBullets(Bullet b)
    {
        if(!game.checkList(bullets, bulletsSize))return;
        bullets[bulletsPtr] = b;
        while(bullets[bulletsPtr] != null){
            bulletsPtr = (bulletsPtr + 1) & (bullets.length - 1);
        }
        bulletsSize++;
        if(debug)println("bulletsSize = " + bulletsSize);
    }
    void removeFromBullets(int i)
    {
        bullets[i] = null;
        bulletsSize--;
    }
    int life, flash, launchCount, Large_life;
    float dynamic_life;
    Bullet bullets[];//子弹列表
    int bulletsPtr, bulletsSize;
};
class Enemy extends Plane //敌人（小怪），继承飞机的类
{
    public Enemy()
    {
        this.loc = new PVector(
            min(width * 0.65, max(width * 0.35, map(randomGaussian(), -3, 3, 0.35, 0.65) * width)),
            height * 0.2,
            random(game.altitude * 1.1, game.altitude * 3.9)
        );
        this.crash = false;
        this.size = 0.25;
        this.acc = new PVector(0, 0, -0.2 * game.gameSpeed);
        this.vel = new PVector(0, 0, 0);
        select_enemy();
        this.atks = new Atk[16];
        game.initObj(atks);
        this.atksPtr = this.atksSize = 0;
        this.atkcount = 0;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        scale(size);
        shape(shape, 0, 0);
        if(debug)drawBox(0, 255, 0, 50);
        popMatrix();

        for(int i = 0; i < atks.length; i++)
        {
            if(atks[i] == null)continue;
            atks[i].draw();
            if(!game.pause)atks[i].update();
            if(game.collision(game.player, atks[i]))
            {
                game.player.hurt();
            }
            if(atks[i].over())
            {
                removeFromAtks(i);
                continue;
            }
        }
    }
    public void move() //小怪被打落时按粒子系统的方法处理移动，否则一直向前
    {
        if(game.over > 0 || game.pause)return;//游戏结束或暂停时不移动
        if(crash)
        {
            this.loc.add(this.vel);
            this.vel.add(this.acc);
        }
        else
        {
            this.loc.y += game.enemyVelocity;
            if(game.collision(this, game.player))
            {
                game.player.hurt();
            }
        }
    }
    public boolean outOfRange() //判断小怪是否超出地图范围
    {
        return loc.z < -game.altitude || loc.y > height;
    }
    public void launch() //敌人发射子弹
    {
        // atkcount用于延迟发射
        atkcount++;
        // 发射
        if (atkcount == 30)
        {
            PVector start = new PVector(loc.x, loc.y + rb2.y * size, loc.z);
            float atkVel = 2 * game.enemyVelocity;
            float atkVel_offset = 0.3 * atkVel;

            // (白 黄) (绿 蓝) (红) (黑)
            if (op >= 0 && op <= 3)
                return;
            else if (op >= 4 && op <= 7)
                addAtks(new Atk(start, new PVector(0, atkVel, 0)));
            else if (op == 8)
            {
                // 三角攻击
                // (0, 1, 0) (1, 1, 0) (-1, 1, 0)
                addAtks(new Atk(start, new PVector(0, atkVel, 0)));
                addAtks(new Atk(start, new PVector(atkVel_offset, atkVel, 0)));
                addAtks(new Atk(start, new PVector(-atkVel_offset, atkVel, 0)));
            }
            else if (op == 9)
            {
                // 五角攻击
                // (0, 1, 0) (1, 1, 1) (-1, 1, 1) (1, 1, -1) (-1, 1, -1)
                addAtks(new Atk(start, new PVector(0, atkVel, 0)));
                addAtks(new Atk(start, new PVector(atkVel_offset, atkVel, atkVel_offset)));
                addAtks(new Atk(start, new PVector(-atkVel_offset, atkVel, atkVel_offset)));
                addAtks(new Atk(start, new PVector(atkVel_offset, atkVel, -atkVel_offset)));
                addAtks(new Atk(start, new PVector(-atkVel_offset, atkVel, -atkVel_offset)));
            }
            //game.playAtkSE(); 小怪攻击不如不加音效？
        }
        else if (atkcount >= 90)
        {
            atkcount = 0;
        }
    }
    void select_enemy()
    {
        float enemy_op = random(0, 10);
        op = floor(enemy_op);

        // (白 黄) (绿 蓝) (红) (黑)
        // 概率 2/5 2/5 1/10 1/10
        if (op >= 0 && op < 2)
            shape = game.enemyShape1;
        else if (op >= 2 && op < 4)
            shape = game.enemyShape2;
        else if (op >= 4 && op < 6)
            shape = game.enemyShape3;
        else if (op >= 6 && op < 8)
            shape = game.enemyShape4;
        else if (op == 8)
            shape = game.enemyShape5;
        else if (op == 9)
            shape = game.enemyShape6;
    }
    void addAtks(Atk a)
    {
        if(!game.checkList(atks, atksSize))return;
        atks[atksPtr] = a;
        while(atks[atksPtr] != null){
            atksPtr = (atksPtr + 1) & (atks.length - 1);
        }
        atksSize++;
        if(debug)println("atksSize = " + atksSize);
    }
    void removeFromAtks(int i)
    {
        atks[i] = null;
        atksSize--;
    }
    boolean crash;
    PVector acc, vel;
    Atk atks[];
    int atksPtr, atksSize;
    int atkcount, op;
};
class Boss extends Plane //boss，继承飞机的类
{
    public Boss(int maxLife)
    {
        this.loc = new PVector(
            width * 0.5,
            height * 0.2,
            game.altitude * 2.5
        );
        this.atks = new Atk[16];
        game.initObj(atks);
        this.atksPtr = this.atksSize = 0;
        this.state = this.turn = 0;
        this.life = this.maxLife = maxLife;
        this.size = 1.5;
        this.originalY = height * 0.5;
        this.acc = new PVector(0, 0, -0.0025 * game.gameSpeed);//boss的坠落速度慢于小怪（为了仪式感）
        this.vel = new PVector(0, 0, 0);
        shape = game.bossShape;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        scale(size);
        shape(shape, 0, 0);
        if(debug)drawBox(0, 255, 0, 50);
        popMatrix();
        if(state > 0) //state指代的意思在后面给出
        {
            drawBossLife();
            for(int i = 0; i < atks.length; i++)
            {
                if(atks[i] == null)continue;
                atks[i].draw();
                if(!game.pause)atks[i].update();
                if(game.collision(game.player, atks[i]))
                {
                    game.player.hurt();
                }
                if(atks[i].over())
                {
                    removeFromAtks(i);
                    i--;
                }
            }
        }
    }
    public void move()
    {
        if(game.over > 0 || game.pause)return;//游戏结束或暂停时不移动
        if(state == -1) //state指代的意思在后面给出
        {
            game.darker = 0;
            game.stopBGMs();
            game.playBoomSELoop();
            this.loc.add(this.vel);
            this.vel.add(this.acc);
            if(floor(frameCount * game.gameSpeed) % 20 == 0)game.boom(loc.copy().add(0, rb2.y * size * 0.3, 0).add(PVector.random3D().mult(random(rb2.z, rb2.y))));
            return;
        }
        else if(state == 0)
        {
            this.loc.y += game.enemyVelocity;
            if(this.loc.y >= height * 0.5)
            {
                state = 1;
                this.originalY = this.loc.y;
            }
            return;
        }
        else if(state == 1)
        {
            game.playBossBGMLoop();
            game.darker = 2;
            if(turn < 10) //自机狙攻击
            {
                if(floor(frameCount * game.gameSpeed) % 60 == 0)
                {
                    snipeAttack();
                    turn++;
                }
            }
            else if(turn < 15) //召唤小怪
            {
                if(floor(frameCount * game.gameSpeed) % 120 == 0)
                {
                    game.addEnemies(new Enemy());
                    turn++;
                }
            }
            else
            {
                turn = 0;
            }
            // change state
            if(life < floor(0.6 * maxLife)) //血量低于60%时改变状态
            {
                state = 2;
                turn = 0;
            }
        }
        else if(state == 2)
        {
            if(turn < 15) //自机狙攻击
            {
                if(floor(frameCount * game.gameSpeed) % 50 == 0)
                {
                    snipeAttack();
                    turn++;
                }
            }
            else if(turn < 20) //冲撞预告
            {
                game.playRushSEOnceNotRewind();
                if(floor(frameCount * game.gameSpeed) % 50 == 0)
                {
                    turn++;
                }
            }
            else if(turn < 26) //冲撞
            {
                if(floor(frameCount * game.gameSpeed) % 50 == 0)
                {
                    game.addEnemies(new Enemy());
                    turn++;
                }
                if(this.loc.y < height + this.rb2.y * this.size)this.loc.y += game.enemyVelocity;
            }
            else if(turn < 32) //召唤小怪+回位
            {
                if(floor(frameCount * game.gameSpeed) % 100 == 0)
                {
                    game.addEnemies(new Enemy());
                    turn++;
                }
                if(this.loc.y > this.originalY)this.loc.y -= game.enemyVelocity;
            }
            else if(turn < 40) //召唤小怪
            {
                if(floor(frameCount * game.gameSpeed) % 100 == 0)
                {
                    game.addEnemies(new Enemy());
                    turn++;
                }
            }
            else //重置冲撞音效
            {
                game.resetRushSE();
                turn = 0;
            }
            // change state
            if(life < floor(0.2 * maxLife) && (turn < 20 || turn > 32)) //血量小于20%时改变状态，但要保证boss在原位，否则出事
            {
                game.resetRushSE();
                state = 3;
                turn = 0;
            }
        }
        else if(state == 3)
        {
            if(turn < 15) //自机狙攻击
            {
                if(floor(frameCount * game.gameSpeed) % 40 == 0)
                {
                    snipeAttack();
                    turn++;
                }
            }
            else if(turn < 20) //冲撞预告
            {
                game.playRushSEOnceNotRewind();
                if(floor(frameCount * game.gameSpeed) % 50 == 0)
                {
                    turn++;
                }
            }
            else if(turn < 26) //冲撞+场景变化
            {
                game.darker = 3;
                if(floor(frameCount * game.gameSpeed) % 80 == 0)
                {
                    game.addEnemies(new Enemy());
                    turn++;
                }
                if(this.loc.y < height + this.rb2.y * this.size)this.loc.y += game.enemyVelocity * 1.2;
            }
            else if(turn < 34) //地图外攻击
            {
                if(floor(frameCount * game.gameSpeed) % 40 == 0)
                {
                    game.naturalAttack();
                    turn++;
                }
            }
            else if(turn < 40) //地图外攻击+召唤小怪
            {
                if(floor(frameCount * game.gameSpeed) % 80 == 0)
                {
                    game.addEnemies(new Enemy());
                    game.naturalAttack();
                    turn++;
                }
                if(this.loc.y > this.originalY)this.loc.y -= game.enemyVelocity * 1.2;
            }
            else if(turn < 45) //场景复原
            {
                game.darker = 2;
                if(floor(frameCount * game.gameSpeed) % 50 == 0)
                {
                    turn++;
                }
            }
            else //重置冲撞音效
            {
                game.resetRushSE();
                turn = 0;
            }
            // change state
            if(life <= 0) //血量不大于0时被打败
            {
                game.resetRushSE();
                state = -1;
            }
        }
        if(game.collision(this, game.player)) //判定boss和玩家的碰撞
        {
            game.player.hurt();
        }
    }
    public void hurt() //boss受伤的操作
    {
        life--;
        if(life <= 0)
        {
            state = -1;
            game.score += game.bossLife;
        }
    }
    void snipeAttack() //自机狙攻击
    {
        PVector start = new PVector(loc.x, loc.y + rb2.y * size, loc.z);
        addAtks(new Atk(start, PVector.sub(game.player.loc, start).normalize().mult(4), 250, 20, 160, 220));
        game.playAtkSE();
    }

    void drawBossLife() //绘制boss血条
    {
        pushMatrix();
        translate(width * 0.35, height * 0.95, game.altitude * 1.2);
        rotateX(radians(45));
        noFill();
        stroke(0, 0, 0);
        strokeWeight(2);
        beginShape();
        vertex(0, 0, height * 0.02);
        vertex(width * 0.3, 0, height * 0.02);
        vertex(width * 0.3, 0, 0);
        vertex(0, 0, 0);
        endShape(CLOSE);
        fill(game.lifeColor[floor(life * 5.0 / maxLife)]);
        noStroke();
        beginShape();
        vertex(0, 0, height * 0.02);
        vertex(width * 0.3 * life / maxLife, 0, height * 0.02);
        vertex(width * 0.3 * life / maxLife, 0, 0);
        vertex(0, 0, 0);
        endShape(CLOSE);
        popMatrix();
    }
    void addAtks(Atk a)
    {
        if(!game.checkList(atks, atksSize))return;
        atks[atksPtr] = a;
        while(atks[atksPtr] != null){
            atksPtr = (atksPtr + 1) & (atks.length - 1);
        }
        atksSize++;
        if(debug)println("atksSize = " + atksSize);
    }
    void removeFromAtks(int i)
    {
        atks[i] = null;
        atksSize--;
    }
    PVector acc, vel;
    float originalY;//记录原位置
    int life, maxLife, state, turn;//state 0:出现但未入场，1:状态1，2:状态2，3:状态3，-1:被打败（坠落）
    Atk atks[];//自机狙子弹列表
    int atksPtr, atksSize;
};