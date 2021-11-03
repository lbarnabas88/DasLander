require object
require sprites
require colliders
require daslib/media

var spritesheet : ImageHandle

var sprites : table<string; Sprite>

var ship : Object
var blocks : array<Object>
var stars : array<Object>
var ends : array<Object>

var points : int
var isRunning = false
var isGameOver = false
var gameOverText = ""

let POINT_TIME_LIMIT = 1.0
let POINT_DECREASE = 100
var pointTime : float

var backgroundMusic : PcmSound
var scoreSound : PcmSound
var mainJetSound : PcmSound
var stabJetSound : PcmSound

var mainJetSfx : PlayingSoundHandle
var stabJetSfx : PlayingSoundHandle

def setupShip(var s : Object&)
    s.body.restitution = 0.1
    s.body.mass = 20.0
    s.body.inv_mass = 1.0 / ship.body.mass
    s.body.gravity_scale = 1.0

    s.sprite = sprites["ship"]

    s.renderer.size = float2(100.0, 70.0)
    s.renderer.color = 0xFFFFFFFF
    s.renderer.pivot = float2(50.0, 35.0)
    s.collider <- [[Collider aabb <- [[AABBCollider min=float2(-40.0, -30.0), max=float2(40.0, 25.0)]] ]]

let SHIP_MAIN_POWER = 400.0
let SHIP_STAB_POWER = 200.0

def controlShip(var s : Object&)
    var acceleration : float2
    var mainJetInput = 0.0
    var stabJetInput = 0.0
    if get_key(VK_W)
        mainJetInput = 1.0
    if get_key(VK_D)
        stabJetInput = 1.0
    if get_key(VK_A)
        stabJetInput = -1.0
    mainJetSfx |> set_sound_volume(mainJetInput)
    stabJetSfx |> set_sound_volume(abs(stabJetInput))
    s.body.acceleration = float2(SHIP_STAB_POWER * stabJetInput, -SHIP_MAIN_POWER * mainJetInput)

let BLOCK_SIZE = 60.0

let MAP_WIDTH = 22
let MAP_HEIGHT = 12
let blockMap = [[auto[]
    '#'; '_'; '@'; '_'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#';
    '#'; '_'; '_'; '_'; '#'; 's'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; 'x'; 'x';
    '#'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; 'x'; 'x';
    '#'; '_'; 's'; '_'; '#'; '_'; '_'; '_'; '#'; '#'; '#'; '#'; '#'; '_'; '_'; '_'; '#'; '_'; '_'; '#'; '#'; '#';
    '#'; '_'; '_'; '_'; '#'; '#'; '_'; '_'; '_'; '#'; '_'; 's'; '#'; '#'; '_'; '_'; '#'; '_'; '_'; '_'; '#'; '#';
    '#'; '_'; '_'; '_'; '#'; '#'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; '_'; '#';
    '#'; '_'; '_'; '_'; '#'; '#'; '#'; '_'; '_'; '#'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; '#'; '_'; '_'; '_'; '#';
    '#'; '_'; '_'; '_'; '#'; '#'; '#'; '_'; '_'; '#'; '_'; '_'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '_'; '_'; '#';
    '#'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; '_'; '#'; '#'; 's'; '_'; '#'; '_'; '_'; '#';
    '#'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#';
    '#'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#'; 's'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '_'; '#';
    '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'; '#'
]]

var startPosition : float2
var starPositions : array<float2>

def buildMap()
    for i in range(MAP_WIDTH)
        for j in range(MAP_HEIGHT)
            let field = blockMap[j * MAP_WIDTH + i]
            if field == '#'
                var blk : Object
                blk.body.position = float2(float(i) * BLOCK_SIZE, float(j) * BLOCK_SIZE)
                blk.body.restitution = 0.2

                blk.sprite = sprites["block"]

                blk.renderer.size = float2(BLOCK_SIZE, BLOCK_SIZE)
                blk.renderer.color = 0xFFFFFFFF

                blk.collider <- [[Collider aabb <- [[AABBCollider min=float2(0.0, 0.0), max=float2(BLOCK_SIZE, BLOCK_SIZE)]] ]]

                blocks |> push(blk)
            elif field == '@'
                startPosition = float2((float(i) + 0.5) * BLOCK_SIZE, (float(j) + 0.5) * BLOCK_SIZE)
            elif field == 's'
                starPositions |> push(float2(float(i) * BLOCK_SIZE, float(j) * BLOCK_SIZE))
            elif field == 'x'
                var stop : Object
                stop.body.position = float2(float(i) * BLOCK_SIZE, float(j) * BLOCK_SIZE)
                stop.sprite = sprites["stop"]

                stop.renderer.size = float2(BLOCK_SIZE, BLOCK_SIZE)
                stop.renderer.color = 0xFFD81313

                stop.collider <- [[Collider aabb <- [[AABBCollider min=float2(0.0, 0.0), max=float2(BLOCK_SIZE, BLOCK_SIZE)]] ]]

                ends |> push(stop)

def startGame()
    points = 0
    ship.body.position = startPosition
    ship.body.velocity = float2(0.0, 0.0)
    ship.body.acceleration = float2(0.0, 0.0)
    pointTime = 0.0
    clear(stars)
    for pos in starPositions
        var star : Object
        star.body.position = pos
        star.sprite = sprites["star"]

        star.renderer.size = float2(BLOCK_SIZE, BLOCK_SIZE)
        star.renderer.color = 0xFFE5FF00

        star.collider <- [[Collider aabb <- [[AABBCollider min=float2(0.0, 0.0), max=float2(BLOCK_SIZE, BLOCK_SIZE)]] ]]

        stars |> push(star)
    isRunning = true
    isGameOver = false

def gameOver()
    isRunning = false
    isGameOver = true
    if points > 0
        gameOverText = "Nice job! You've won with {points} points!\n"
    else
        gameOverText = "Noob! You've {points} points!\n"

[export]
def initialize
    set_window_title("Das Lander")

    spritesheet = create_managed_image("spaaace-sheet.png")
    spritesheet |> make_image_color_transparent(spritesheet |> get_pixel(0, 0))

    sprites["background"] = [[Sprite sheet = spritesheet, region=float4(1024.0, 1024.0, 2048.0, 2048.0)]]
    sprites["ship"] = [[Sprite sheet = spritesheet, region=float4(0.0, 0.0, 512.0, 355.0)]]
    sprites["block"] = [[Sprite sheet = spritesheet, region=float4(0.0, 1536.0, 512.0, 512.0)]]
    sprites["star"] = [[Sprite sheet = spritesheet, region=float4(0.0, 512.0, 256.0, 256.0)]]
    sprites["stop"] = [[Sprite sheet = spritesheet, region=float4(256.0, 512.0, 256.0, 256.0)]]

    backgroundMusic <- create_sound("Comfortable Mystery.mp3")
    backgroundMusic |> play_sound_loop()

    scoreSound <- create_sound("score.wav")

    mainJetSound <- create_sound("jet_large.wav")
    stabJetSound <- create_sound("jet_small.wav")
    mainJetSfx = mainJetSound |> play_sound_loop()
    mainJetSfx |> set_sound_volume(0.0)
    stabJetSfx = stabJetSound |> play_sound_loop()
    stabJetSfx |> set_sound_volume(0.0)

    setupShip(ship)
    buildMap()

[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    
    if isRunning
        controlShip(ship)

        var m : Manifold
        for blk in blocks
            if colloideAabbVsAabb(ship.body.position, blk.body.position, ship.collider as aabb, blk.collider as aabb, m)
                resolveCollision(ship.body, blk.body, m.normal)
                positionalCorrection(ship.body, blk.body, m.penetration, m.normal)
        for end in ends
            if colloideAabbVsAabb(ship.body.position, end.body.position, ship.collider as aabb, end.collider as aabb, m)
                gameOver()
        var removableStar = -1
        for i in range(length(stars))
            if colloideAabbVsAabb(ship.body.position, stars[i].body.position, ship.collider as aabb, stars[i].collider as aabb, m)
                points += 1000
                removableStar = i
                scoreSound |> play_sound()
        if removableStar >= 0
            erase(stars, removableStar)

        updateObject(ship, dt)
        for blk in blocks
            updateObject(blk, dt)

        pointTime += dt
        while pointTime >= POINT_TIME_LIMIT
            points -= POINT_DECREASE
            pointTime -= POINT_TIME_LIMIT
    else
        mainJetSfx |> set_sound_volume(0.0)
        stabJetSfx |> set_sound_volume(0.0)
        if get_key_down(VK_SPACE)
            startGame()

[export]
def draw
    let backgroundSprite = sprites["background"]
    backgroundSprite.sheet |> draw_image_region(0.0, 0.0, backgroundSprite.region)
    backgroundSprite.sheet |> draw_image_region(1024.0, 0.0, backgroundSprite.region)

    enable_alpha_blend()
    drawObject(ship)
    for blk in blocks
        drawObject(blk)
    for star in stars
        drawObject(star)
    for end in ends
        drawObject(end)

    //drawCollider(ship)
    //for blk in blocks
    //    drawCollider(blk)

    set_font_size(25)
    text_out(get_screen_width() / 2 - 10, 10, "Score: {points}", 0xFFFFFFFF)

    if isGameOver
        let textSize = get_text_size(gameOverText)
        text_out((float(get_screen_width()) - textSize.x) / 2.0, (float(get_screen_height()) - textSize.y) / 2.0, gameOverText, 0xFFFFFFFF)

    if !isRunning
        let startText = "Press 'SPACE' to start!"
        let textSize = get_text_size(startText)
        text_out((float(get_screen_width()) - textSize.x) / 2.0, float(get_screen_height()) - textSize.y - 10.0, startText, 0xFFFFFFFF)

options debugger
require daslib/debug
