import nico
import bumpy
import strformat
import fpn
# moves when you do - theme
# control two platforming characters at the same time, and get them into their respective holes
# this shouldn't be messy at all :)
genQM_N(initQ22_10, 10, fixedPoint32)

# player states
type States {.pure.} = enum # can only use what i explicitly typed out
  Moving, Ground, Turnaround, Jump, Air, AirMoving

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
    airAccel: int
    maxAirSpeed: int
    jumpForce: int
    airJumpsLeft: int
    maxAirJumps: int
    terminalVelocity: int
    gravity: int
    # friction
    staticFriction: int # should be strong to stop quickly
    kineticFriction: int # should be weak to facilitate movement
    drag: int # air friction

  PlayerInput = ref object of RootObj
    pressedLeft, pressedRight, jumpPressed : bool

# global variables (used for now)

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

    state : States.Ground,
    facingRight : false,

    velocity : Vec2i(),

    groundAccel : 2,
    maxGroundSpeed : 4,

    airAccel : 2,
    maxAirSpeed : 4,

    jumpForce : 10,
    airJumpsLeft : 3,
    maxAirJumps : 3,

    terminalVelocity : 3,
    gravity : 2,

    staticFriction : 5, # grounded friction
    kineticFriction : 1, # movement friction
    drag : 1, # air friction essentially
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

  fps(60)

  playerInit()

  # create hitbox

  randomBox = RectHitbox(
    transform : Rect(
      x : 10,
      y : 90,
      w : 90,
      h : 5,
    ),
    isSolid : true,
  )

proc playerSetInput(player : Player, playerInput: PlayerInput) =
  playerInput.pressedLeft = btn(pcLeft)
  playerInput.pressedRight = btn(pcRight)
  playerInput.jumpPressed = btnp(pcA)


proc playerMoveX(player : Player, playerInput: PlayerInput) =
  let accel =
    case player.state:
    of States.Moving: player.groundAccel
    of States.AirMoving: player.airAccel
    else: 0
  
  let maxSpeed =
    case player.state:
    of States.Moving: player.maxGroundSpeed
    of States.AirMoving: player.maxAirSpeed
    else: 0
  
  if playerInput.pressedLeft:
    player.velocity.x -= (if player.velocity.x - accel >= -maxSpeed: accel else: 0)
  if playerInput.pressedRight:
    player.velocity.x += (if player.velocity.x + accel <= maxSpeed: accel else: 0)


proc playerFriction(player : Player) =
  let friction = 
    case player.state:
    of States.Moving: player.kineticFriction
    of States.Ground, States.Turnaround: player.staticFriction
    of States.Air, States.AirMoving: player.drag
    else: 0
  if player.velocity.x < 0:
    if player.velocity.x + friction > 0:
      player.velocity.x = 0
    else:
      player.velocity.x += friction
  elif player.velocity.x > 0:
    if player.velocity.x - friction < 0:
      player.velocity.x = 0
    else:
      player.velocity.x -= friction


proc playerJump(player : Player) =
  player.velocity.y = -player.jumpForce



proc playerGravity(player : Player) =
  player.velocity.y += (if player.velocity.y + player.gravity <= player.terminalVelocity: player.gravity else: 0)

proc playerCheckCollision(player : Player, randomBox : RectHitbox) : bool =
  if overlaps(player.hitbox.transform, randomBox.transform):
    player.velocity.y = 0
    return true
  else:
    return false

proc playerApplyVelocity(player : Player, dt: float32) =
  player.position.x += player.velocity.x
  player.position.y += player.velocity.y

proc playerUpdateHitbox(player: Player) =
  player.hitbox.transform.x = float player.position.x
  player.hitbox.transform.y = float player.position.y

proc playerUpdate(player: Player, dt: float32) =
  playerSetInput(player, playerInput)

  template changeToGroundJump =
    if (playerInput.jumpPressed):
      player.state = States.Jump

  template checkForAirJump =
    if (player.airJumpsLeft > 0 and playerInput.jumpPressed):
      player.airJumpsLeft -= 1
      player.state = States.Jump

  template checkForGround =
    if playerCheckCollision(player, randomBox):
      player.state = States.Ground
      player.airJumpsLeft = player.maxAirJumps
  
  template checkForAir = 
    if not playerCheckCollision(player, randomBox):
      player.state = States.Air

  case player.state:
    of States.Ground:
      #echo "Ground"
      playerFriction(player)

      if (playerInput.pressedLeft or playerInput.pressedRight):
        player.state = States.Moving
      
      checkForAir()
      changeToGroundJump()
    of States.Moving:
      playerMoveX(player, playerInput)
      playerFriction(player)

      if (playerInput.pressedLeft or playerInput.pressedRight):
      # the follow is to facilitate non slippery turnarounds.
        if(playerInput.pressedRight != player.facingRight):
          player.state = States.Turnaround
          player.facingRight = playerInput.pressedRight
      else:
        player.state = States.Ground

      checkForAir()
      changeToGroundJump()
    of States.Turnaround:
      playerMoveX(player, playerInput)
      playerFriction(player)

      if (playerInput.pressedLeft or playerInput.pressedRight):
        player.state = States.Moving
      else:
        player.state = States.Ground
      
      checkForAir()
      changeToGroundJump()
    of States.Jump:
      playerJump(player)
      player.state = States.Air
    of States.Air:
      #echo "Air"
      playerFriction(player)
      playerGravity(player)

      if (playerInput.pressedLeft or playerInput.pressedRight):
        player.state = States.AirMoving
      
      checkForGround()
      checkForAirJump()
    of States.AirMoving:
      playerMoveX(player, playerInput)
      playerFriction(player)
      playerGravity(player)

      if not (playerInput.pressedLeft or playerInput.pressedRight):
        player.state = States.Air
      
      checkForGround()
      checkForAirJump()
  
  playerApplyVelocity(player, dt)
  playerUpdateHitbox(player)

proc gameUpdate(dt: float32) =
  let dt = 1/60 # fixed 6 frames a second
  playerUpdate(player, dt)


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
  case player.state:
    of States.Ground: debugStr.add("State: Ground")
    of States.Moving: debugStr.add("State: Moving")
    of States.Turnaround: debugStr.add("State: Turnaround")
    of States.Jump: debugStr.add("State: Jump")
    of States.Air: debugStr.add("State: Air")
    of States.AirMoving: debugStr.add("State: AirMoving")
  printc(debugStr, screenWidth div 2, 2)

nico.init("myOrg", "myApp")
nico.createWindow("myApp", 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)