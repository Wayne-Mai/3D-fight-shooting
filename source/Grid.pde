class Field
{
    public Field(float x, float y, int Lsize, int Wsize, float size)
    {
        grids = new ArrayList<Grid>();
        trees = new Tree[32];
        game.initObj(trees);
        treesPtr = treesSize = 0;
        this.x = x;
        this.y = y;
        this.Lsize = Lsize;
        this.Wsize = Wsize;
        this.size = size;
        this.fieldOffset = 0;
        for(int j = 0; j < Wsize; j++)
        {
            for(int i = 0; i < Lsize; i++)
            {
                grids.add(new Grid(x + i * size, y + j * size));
            }
        }
        initTree(Lsize - 1, Wsize - 1);
    }
    public void makeNoise(float low, float high) //移动地形
    {
        if(game.pause)return;
        float param = 10;
        for(int i = 0; i < Lsize; i++)
        {
            for(int j = 0; j < Wsize; j++)
            {
                //PVector loc = grid.get(i * Wsize + j).loc;
                grids.get(i * Wsize + j).loc.z = map(noise((i - fieldOffset) * 0.1, j * 0.1), 0, 1, low, high);
            }
        }
        for(int i = 0; i < trees.length; i++){
            if(trees[i] == null)continue;
            trees[i].mapMove(game.mapVelocity * param * size);
            if(trees[i].y > height){
              removeFromTrees(i);
            }
        }
        initTree(1, Wsize - 1);
        fieldOffset += game.mapVelocity * param;
    }
    public void draw() //绘制地形
    {
        for(int j = 0; j < Wsize - 1; j++)
        {
            noStroke();
            fill(200, 200, 200, 255);
            if(debug)
            {
                stroke(200, 200, 200, 100);
                noFill();
            }
            beginShape(TRIANGLE_STRIP);
            textureMode(NORMAL);
            textureWrap(REPEAT);
            tint(200, 200, 200);
            texture(game.groundTexture);
            for(int i = 0; i < Lsize - 1; i++)
            {
                PVector loc[] = {grids.get(i * Wsize + j).loc, grids.get(i * Wsize + j + 1).loc};
                vertex(loc[0].x, loc[0].y, loc[0].z, loc[0].x * 20 / width, loc[0].y * 20 / height);
                vertex(loc[1].x, loc[1].y, loc[1].z, loc[1].x * 20 / width, loc[1].y * 20 / height);
            }
            endShape();
        }
        for(int i = 0; i < trees.length; i++){
            if(trees[i] == null)continue;
            trees[i].draw();
        }
    }
    void initTree(int maxI, int maxJ){
        for(int j = 0; j < maxJ; j++){
            for(int i = 0; i < maxI; i++){
                Grid grid = grids.get(i * Wsize + j);
                if(grid.loc.z > game.altitude * 0.66 && grid.loc.z < game.altitude * 0.75 && random(1) > 0.8){
                    addTrees(new Tree(
                                grid.loc.x,//-30, 
                                grid.loc.y,//-15, 
                                grid.loc.z,
                                0.1,
                                game.treeShape[2]
                              )
                            );
                }
                else if(grid.loc.z < game.altitude * 0.58 && grid.loc.z > game.altitude * 0.45 && random(1) > 0.8){
                    addTrees(new Tree(
                                grid.loc.x,//-30, 
                                grid.loc.y,//-15, 
                                grid.loc.z,
                                0.01,
                                game.treeShape[1]
                              )
                            );
                }
                else if(grid.loc.z > game.altitude * 0.4 && grid.loc.z < game.altitude * 0.46 && random(1) > 0.8){
                    addTrees(new Tree(
                                grid.loc.x,//-50, 
                                grid.loc.y,//-50, 
                                grid.loc.z,
                                0.3,
                                game.treeShape[0]
                              )
                            );
                }
            }
        }
    }
    void addTrees(Tree b)
    {
        if(!game.checkList(trees, treesSize))return;
        trees[treesPtr] = b;
        while(trees[treesPtr] != null){
            treesPtr = (treesPtr + 1) & (trees.length - 1);
        }
        treesSize++;
    }
    void removeFromTrees(int i)
    {
        trees[i] = null;
        treesSize--;
    }
    Tree[] trees;//树木建筑列表
    int treesPtr, treesSize;
    ArrayList<Grid> grids;//地形结点列表
    float x, y, size, fieldOffset;
    int Lsize, Wsize;
};
class Grid //结点（网格），原计划作为水面的网格，所以删去了几个函数
{
    public Grid(float x, float y)
    {
        this.loc = new PVector(x, y, 0);
    }
    PVector loc;
};
class Tree //树木建筑
{
    public Tree(float x, float y, float z, float scale, PShape shape)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.scale = scale;
        this.shape = shape;
    }
    public void draw()
    {
        pushMatrix();
        translate(x, y, z);
        scale(scale);
        shape(shape, 0, 0);
        popMatrix();
    }
    public void mapMove(float velocity)
    {
        this.y += velocity;
    }
    float x, y, z, scale;
    PShape shape;
};