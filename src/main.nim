import nico
import bumpy
import strformat

# moves when you do - theme
# control two platforming characters at the same time, and get them into their respective holes
# this shouldn't be messy at all :)

# player states
type States = enum
  Moving, Still, Turnaround

# base types
type
  Vec2i = object 
    x, y: int
  GameObject = ref object of RootObj
    position: Vec2i
  RectObj = ref object of GameObject
    width, height: int
  RectHitbox = ref object of RootObj
    transform : Rect
    isSolid : bool
  Player = ref object of RectObj
    state : States
    facingRight : bool
    hitbox: RectHitbox
    velocity: Vec2i
    # horizontal physics
    groundAccel: int
    maxGroundSpeed: int
    # vertical physics
    jumpForce: int
    terminalVelocity: int
    gravity: int
    # friction
    staticFriction: int # should be strong to stop quickly
    kineticFriction: int # should be weak to facilitate movement

  PlayerInput = ref object of RootObj
    pressedLeft, pressedRight, jumpPressed : bool

proc `+`(a, b: Vec2i): Vec2i = 
  Vec2i(x: a.x + b.x, y: a.y + b.y)
#[
# player inputs
var playerX  = screenWidth div 2
var playerY  = screenWidth div 2
var playerWidth = 2
var playerHeight = 2


var playerState = States.Still
var facingRight = false

# horizontal movement
var player.velocity = Vec2i()

var playerAcceleration = 2
var maxSpeed = 5

# vertical movement
var jumpForce = 10
var terminalVelocity = 3

# physics variables
var gravity = 2
var staticFriction = 5 # should be strong to stop quickly
var kineticFriction = 1 # should be weak to facilitate movement

# input variables
var pressedLeft = false
var pressedRight = false

var jumpPressed = false
]#

var player : Player
var playerInput : PlayerInput

var randomBox : RectHitbox

proc playerInit() =
  player = Player(

    position : Vec2i(
      x : screenWidth div 2,
      y : screenHeight div 2
    ),
    width : 2,
    height : 2,

    state : States.Still,
    facingRight : false,

    velocity : Vec2i(),

    groundAccel : 2,
    maxGroundSpeed : 5,

    jumpForce : 10,
    terminalVelocity : 3,
    gravity : 2,

    staticFriction : 5,
    kineticFriction : 1,
  )

  player.hitbox = RectHitbox(
    transform : Rect(
      x : float32 player.position.x,
      y : float32 player.position.y,
      w : float32 player.width,
      h : float32 player.height
    ),
    isSolid : true,
  )
  
  playerInput = PlayerInput()
  playerInput.pressedLeft = false
  playerInput.pressedRight = false
  playerInput.jumpPressed = false

proc gameInit() =
  loadFont(0, "font.png")

  playerInit()

  # create hitbox

  randomBox = RectHitbox(
    transform : Rect(
      x : 60,
      y : 90,
      w : 15,
      h : 5,
    ),
    isSolid : true,
  )

proc playerSetInput(player : Player, playerInput: PlayerInput) =
  playerInput.pressedLeft = btn(pcLeft)
  playerInput.pressedRight = btn(pcRight)
  playerInput.jumpPressed = btnp(pcA)

proc playerSetStates(player : Player, playerInput: PlayerInput) =
  if (playerInput.pressedLeft or playerInput.pressedRight):
    if(playerInput.pressedRight != player.facingRight):
      player.state = States.Turnaround
      player.facingRight = playerInput.pressedRight
    else:
      player.state = States.Moving
  else:
    player.state = States.Still

proc playerMoveX(player : Player, playerInput: PlayerInput) =
  if playerInput.pressedLeft:
    player.velocity.x -= (if player.velocity.x - player.groundAccel >= -player.maxGroundSpeed: player.groundAccel else: 0)
  if playerInput.pressedRight:
    player.velocity.x += (if player.velocity.x + player.groundAccel <= player.maxGroundSpeed: player.groundAccel else: 0)


proc playerFriction(player : Player) =
  if player.state == States.Still or player.state == States.Turnaround:
    if player.velocity.x < 0:
      if player.velocity.x + player.staticFriction > 0:
        player.velocity.x = 0
      else:
        player.velocity.x += player.staticFriction
    elif player.velocity.x > 0:
      if player.velocity.x - player.staticFriction < 0:
        player.velocity.x = 0
      else:
        player.velocity.x -= player.staticFriction
  elif player.state == States.Moving:
    if player.velocity.x < 0:
      if player.velocity.x + player.kineticFriction > 0:
        player.velocity.x = 0
      else:
        player.velocity.x += player.kineticFriction
    elif player.velocity.x > 0:
      if player.velocity.x - player.kineticFriction < 0:
        player.velocity.x = 0
      else:
        player.velocity.x -= player.kineticFriction


proc playerJump(player : Player, playerInput: PlayerInput) =
  if playerInput.jumpPressed:
    player.velocity.y -= player.jumpForce


proc playerGravity(player : Player) =
  player.velocity.y += (if player.velocity.y + player.gravity <= player.terminalVelocity: player.gravity else: 0)

proc playerCheckCollision(player : Player, randomBox : RectHitbox) =
  if overlaps(player.hitbox.transform, randomBox.transform) and not playerInput.jumpPressed:
    player.velocity.y = 0

proc playerApplyVelocity(player : Player, dt: float32) =
  player.position.x += player.velocity.x
  player.position.y += player.velocity.y

proc playerUpdateHitbox(player: Player) =
  player.hitbox.transform.x = float player.position.x
  player.hitbox.transform.y = float player.position.y

proc gameUpdate(dt: float32) =
  playerSetInput(player, playerInput)
  playerSetStates(player, playerInput)
  playerMoveX(player, playerInput)
  playerFriction(player)
  playerJump(player, playerInput)
  playerGravity(player)
  playerCheckCollision(player, randomBox)
  playerApplyVelocity(player, dt)
  playerUpdateHitbox(player)


proc drawPlayer() =
  boxfill(player.position.x, player.position.y, player.width, player.height)

proc gameDraw() =
  cls()

  #sets color of both text and box
  setColor(3)
  
  # render player
  drawPlayer()

  # render random hitbox
  boxfill(randomBox.transform.x, randomBox.transform.y, randomBox.transform.w, randomBox.transform.h)

  # render text
  var debugStr : string = fmt"Pos: ({player.position.x}, {player.position.y})"
  debugStr.add(fmt"Turnaround: {player.state == States.Turnaround}")
  printc(debugStr, screenWidth div 2, 2)

nico.init("myOrg", "myApp")
nico.createWindow("myApp", 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)