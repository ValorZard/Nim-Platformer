import nico
import nico/vec
import bumpy
# import strformat
import polymorph
# moves when you do - theme
# control two platforming characters at the same time, and get them into their respective holes
# this shouldn't be messy at all :)

# base types
type
  States {.pure.} = enum # can only use what i explicitly typed out
    Moving, Ground, Turnaround, Jump, Air, AirMoving
### ECS REWRITE

registerComponents(defaultComponentOptions):
  type
    # Tag
    Player = object
    # States
    State = object 
      currentState : States
    # Components
    Position = object
      position : Vec2i
    Rectangle = object
      width, height: int
    Hitbox = object
      transform : Rect
      isSolid : bool
    FacingRight =  object
      value : bool
    Velocity = object
      value : Vec2i
    Acceleration = object 
      # horizontal physics
      groundAccel : int
      maxGroundSpeed : int
      # vertical physics
      airAccel : int
      maxAirSpeed: int
    Gravity = object 
      terminalVelocity: int
      gravity: int
    Friction = object
      staticFriction: int # should be strong to stop quickly
      kineticFriction: int # should be weak to facilitate movement
      drag: int # air friction
    JumpComponent = object
      # universal jump stuff
      jumpForce : int
      # air jumps
      airJumpsLeft: int
      maxAirJumps: int
    PlayerInput = ref object of RootObj
      pressedLeft, pressedRight, jumpPressed : bool


# Create systems to act on the components

# system definitions


defineSystem("HitboxCollision", [Hitbox], defaultSystemOptions):
  player: EntityRef


# actual system implementations

makeSystem("PlayerSetInput", [Player, PlayerInput]):
  # `item` is generated from the types passed within `[]`
  init:
    sys.paused = true
  all:
    item.playerInput.pressedLeft = btn(pcLeft)
    item.playerInput.pressedRight = btn(pcRight)
    item.playerInput.jumpPressed = btnp(pcA)
  finish:
    sys.paused = true

makeSystem("PlayerMoveX", [Player, State, Velocity, Acceleration, PlayerInput]):
  init:
    sys.paused = true
  all:
    let accel =
      case item.state.currentState:
      of States.Moving: item.acceleration.groundAccel
      of States.AirMoving: item.acceleration.airAccel
      else: 0
  
    let maxSpeed =
      case item.state.currentState:
      of States.Moving: item.acceleration.maxGroundSpeed
      of States.AirMoving: item.acceleration.maxAirSpeed
      else: 0
  
    if item.playerInput.pressedLeft:
      item.velocity.value.x -= (if item.velocity.value.x - accel >= -maxSpeed: accel else: 0)
    if item.playerInput.pressedRight:
      item.velocity.value.x += (if item.velocity.value.x + accel <= maxSpeed: accel else: 0)
  finish:
    sys.paused = true
makeSystem("PlayerFriction", [Player, State, Velocity, Friction]):
  init:
    sys.paused = true
  all:
    let friction = 
      case item.state.currentState:
      of States.Moving: item.friction.kineticFriction
      of States.Ground, States.Turnaround: item.friction.staticFriction
      of States.Air, States.AirMoving: item.friction.drag
      else: 0
    if item.velocity.value.x < 0:
      if item.velocity.value.x + friction > 0:
        item.velocity.value.x = 0
      else:
        item.velocity.value.x += friction
    elif item.velocity.value.x > 0:
      if item.velocity.value.x - friction < 0:
        item.velocity.value.x = 0
      else:
        item.velocity.value.x -= friction
  finish:
    sys.paused = true
makeSystem("PlayerJump", [Player, JumpComponent, Velocity]):
  init:
    sys.paused = true
  all:
    item.velocity.value.y = -item.jumpComponent.jumpForce
  finish:
    sys.paused = true

makeSystem("PlayerGravity", [Player, Gravity, Velocity]):
  init:
    sys.paused = true
  all:
    item.velocity.value.y += (if item.velocity.value.y + item.gravity.gravity <= item.gravity.terminalVelocity: item.gravity.gravity else: 0)
  finish:
    sys.paused = true

# Have to pass the options into the system.
makeSystemOpts("HitboxCollision", [Hitbox], defaultSystemOptions):
  init:
    sys.paused = true
  all:
    var isColliding = false
    if(item.entity != sys.player):
      # player is an entity so you'd have to fetch the hitbox from it.
      let hitbox = sys.player.fetchComponent Hitbox
      if(overlaps(hitbox.transform, item.hitbox.transform)):
        isColliding = true
    
    let state = sys.player.fetchComponent State

    if isColliding:
      let velocity = sys.player.fetchComponent Velocity
      velocity.value.y = 0 
      state.currentState = States.Ground
      let jumpComponent = sys.player.fetchComponent JumpComponent
      jumpComponent.airJumpsleft = jumpComponent.maxAirJumps
    else:
      state.currentState = States.Air


#[
makeSystemOptFields("HitboxCollision", [Hitbox], defaultSystemOptions) do:
  player: EntityRef
do:
  init:
    sys.paused = true
  all:
    var isColliding = false
    if(item != player):
      if(overlap(player.hitbox.transform, item.hitbox.transform)):
        isColliding = true
    
    if isColliding:
      player.velocity.value.y = 0 
      player.state.currentState = States.Ground
      player.jumpComponent.airJumpsleft = player.jumpComponent.maxAirJumps
    else:
      player.state.currentState = States.Air
]#


makeSystem("PlayerCheckCollision", [Player, Velocity, JumpComponent, Hitbox]):
  init: 
    sys.paused = true
  all:
    hitboxCollision.player = item.entity
    doHitboxCollision()
  finish:
    sys.paused = true


makeSystem("PlayerApplyVelocity", [Player, Position, Velocity]):
  init:
    sys.paused = true
  all:
    item.position.position.x += item.velocity.value.x
    item.position.position.y += item.velocity.value.y
  finish:
    sys.paused = true

makeSystem("PlayerUpdateHitbox", [Player, Position, Hitbox]):
  init:
    sys.paused = true
  all:
    item.hitbox.transform.x = float item.position.x
    item.hitbox.transform.y = float item.position.y
  finish:
    sys.paused = true

makeSystem("PlayerUpdate", [Player, PlayerInput, State, JumpComponent]):
  init:
    sys.paused = true
  all:
    doPlayerSetInput()

    template changeToGroundJump =
      if (item.playerInput.jumpPressed):
        item.state.currentState = States.Jump

    template checkForAirJump =
      if (item.jumpComponent.airJumpsLeft > 0 and item.playerInput.jumpPressed):
        item.jumpComponent.airJumpsLeft -= 1
        item.state.currentState = States.Jump


    case item.state.currentState:
      of States.Ground:
        #echo "Ground"
        doPlayerFriction()

        if (item.playerInput.pressedLeft or item.playerInput.pressedRight):
          item.state.currentState = States.Moving
      
        doPlayerCheckCollision()
        changeToGroundJump()
      of States.Moving:
        doPlayerMoveX()
        doPlayerFriction(player)

        if (item.playerInput.pressedLeft or item.playerInput.pressedRight):
        # the follow is to facilitate non slippery turnarounds.
          if(item.playerInput.pressedRight != item.facingRight.value):
            item.state.currentState = States.Turnaround
            item.facingRight.value = item.playerInput.pressedRight
        else:
          item.state.currentState = States.Ground

        doPlayerCheckCollision()
        changeToGroundJump()
      of States.Turnaround:
        doPlayerMoveX()
        doPlayerFriction()

        if (item.playerInput.pressedLeft or item.playerInput.pressedRight):
          item.state.currentState = States.Moving
        else:
          item.state.currentState = States.Ground
      
        doPlayerCheckCollision()
        changeToGroundJump()
      of States.Jump:
        doPlayerJump()
        item.state.currentState = States.Air
      of States.Air:
        #echo "Air"
        doPlayerFriction()
        doPlayerGravity()

        if (item.playerInput.pressedLeft or item.playerInput.pressedRight):
          item.state.currentState = States.AirMoving
      
        doPlayerCheckCollision()
        checkForAirJump()
      of States.AirMoving:
        doPlayerMoveX()
        doPlayerFriction()
        doPlayerGravity()

        if not (item.playerInput.pressedLeft or item.playerInput.pressedRight):
          item.state.currentState = States.Air
      
        doPlayerCheckCollision()
        checkForAirJump()
  
    doPlayerApplyVelocity()
    doPlayerUpdateHitbox()
  finish:
    sys.paused = true

# Seal and generate ECS
makeEcs()
commitSystems("run")

### END ECS REWRITE

# global variables (used for now)

let 
  player = newEntityWith(
      Position(
        position : Vec2i(
          x : screenWidth div 2,
          y : screenHeight div 2
        ),
      ),
    )

#[
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
]#

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
  case item.state.currentState:
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