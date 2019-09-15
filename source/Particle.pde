class Particle //粒子，简化的粒子系统
{
    public Particle()
    {
    }
    public Particle(PVector loc, PVector vel)
    {
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(0, 0, 0);
        this.tx = null;
        this.size = random(10, 25);
    }
    public Particle(PVector loc, PVector vel, PImage texture)
    {
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(0, 0, 0);
        this.tx = texture;
        this.size = random(10, 25);
    }
    public void drawBoom() //没有单独写一个爆炸粒子类，只写了一个画爆炸粒子的爆炸函数
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        rotateX(radians(-45));
        fill(153, 132, 92, 133);
        sphere(size);
        popMatrix();
    }
    public void update()
    {
        this.loc.add(this.vel);
        this.vel.add(this.acc);
        this.acc.mult(0);
    }
    void drawTexture(int r, int g, int b, int a) //绘制带贴图的粒子，其实画的是一个平面
    {
        //pushMatrix();
        rotateX(-radians(45));
        noStroke();
        beginShape();
        textureMode(NORMAL);
        tint(r, g, b, a);
        texture(tx);
        scale(size, size, size);
        for(int i = 100; i > 0; i--)
        {
            float x = cos((float)i / 100 * TWO_PI), y = sin((float)i / 100 * TWO_PI);
            vertex(x, y, 0, x / 2 + 0.5, y / 2 + 0.5);
        }
        endShape(CLOSE);
        //popMatrix();
    }
    PVector loc, vel, acc;
    PImage tx;
    float size;
};

class Bullet extends Particle //玩家射击的子弹，继承的粒子类
{
    public Bullet()
    {
    }
    public Bullet(PVector loc, PVector vel)
    {
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(0, 0, 0);
        this.tx = game.bulletTexture;
        this.size = 12;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        //texture(tx);
        //sphere(size);
        //game.textureSphere(size, size, size, tx);
        drawTexture(40, 250, 220, 220);
        popMatrix();
    }
};
class Atk extends Particle //敌人的攻击，继承的粒子类
{
    public Atk()
    {
    }
    public Atk(PVector loc, PVector vel)
    {
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(0, 0, 0);
        this.tx = game.bulletTexture;
        this.r = 160;
        this.g = 250;
        this.b = 20;
        this.a = 220;
        this.size = 12;
    }
    public Atk(PVector loc, PVector vel, int r, int g, int b, int a)
    {
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(0, 0, 0);
        this.tx = game.bulletTexture;
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
        this.size = 15;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        drawTexture(r, g, b, a);
        popMatrix();
    }
    public boolean over() //判断该粒子生命周期结束
    {
        return loc.x > width || loc.x < 0
               || loc.y > height || loc.y < 0
               || loc.z > game.altitude * 6 || loc.z < -game.altitude;
    }
    int r, g, b, a;
};
class Medkit extends Particle //医疗包，继承的粒子类
{
    public Medkit()
    {
    }
    public Medkit(PVector loc, PVector vel)
    {
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(0, 0, 0);
        this.tx = game.MedkitTexture;
        this.size = 15;
    }
    public void draw()
    {
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        drawTexture(160, 250, 20, 220);
        popMatrix();
    }
    public boolean over() //判断该粒子生命周期结束
    {
        return loc.x > width || loc.x < 0
               || loc.y > height || loc.y < 0
               || loc.z > game.altitude * 6 || loc.z < -game.altitude;
    }
};
class Boomer //爆炸效果，内有爆炸粒子列表
{
    Boomer(int count, PVector center)
    {
        particles = new Particle[8];
        game.initObj(particles);
        boomParticles = new BoomParticle[16];
        game.initObj(boomParticles);
        particlesPtr = particlesSize = boomParticlesPtr = boomParticlesSize = 0;
        for(int i = 0; i < count; i++)
        {
            addParticles(new Particle(center.copy(), PVector.random3D().mult(random(0.4, 1))));
            for(int j = 0; j < count / 2; j++){
                addBoomParticles(new BoomParticle(center.copy(), PVector.random3D().mult(random(2, 8))));
            }
        }
        this.life = 30;
    }
    public void draw()
    {
        shininess(5.0);
        for(int i = 0; i < particles.length; i++)
        {
            if(particles[i] == null)continue;
            particles[i].drawBoom();
            if(!game.pause)particles[i].update();
        }
        shininess(1.0);
        if(!game.pause)life--;
        for(int i = 0; i < boomParticles.length; i++){
            if(boomParticles[i] == null)continue;
            boomParticles[i].draw();
            if(!game.pause)boomParticles[i].update();
        }
    }
    void addBoomParticles(BoomParticle b)
    {
        if(!game.checkList(boomParticles, boomParticlesSize))return;
        boomParticles[boomParticlesPtr] = b;
        while(boomParticles[boomParticlesPtr] != null){
            boomParticlesPtr = (boomParticlesPtr + 1) & (boomParticles.length - 1);
        }
        boomParticlesSize++;
        if(debug)println("boomParticlesSize = " + boomParticlesSize);
    }
    void addParticles(Particle b)
    {
        if(!game.checkList(particles, particlesSize))return;
        particles[particlesPtr] = b;
        while(particles[particlesPtr] != null){
            particlesPtr = (particlesPtr + 1) & (particles.length - 1);
        }
        particlesSize++;
        if(debug)println("particlesSize = " + particlesSize);
    }
    Particle particles[];
    int particlesPtr, particlesSize;
    BoomParticle boomParticles[];//爆炸碎片列表
    int boomParticlesPtr, boomParticlesSize;
    int life;
};

class BoomParticle extends Particle{//玩家射击的子弹，继承的粒子类
    public BoomParticle(){
    }
    public BoomParticle(PVector loc, PVector vel){
        this.loc = loc.copy();
        this.vel = vel.copy();
        this.acc = new PVector(-0.2, -0.2, -3);
        this.size=int(random(0.4,4));
        this.life=9;
    }
    public void draw(){
        if(this.life--<=0) return;
        pushMatrix();
        translate(loc.x, loc.y, loc.z);
        rotateX(radians(-45));
        fill(168, 213, 27, 133);
        float shape=random(0,1);
        if(shape>=0.5f) sphere(size);
        else box(size); 
        popMatrix();
    }
    int life;
};