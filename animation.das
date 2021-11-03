require sprites

struct Frame
    timestamp : float
    sprite : Sprite

struct Animation
    frames : array<Frame>
    length : float

struct AnimationState
    anim : Animation
    time : float
    frame : int

def updateAnimationState(var animState : AnimationState&; dt : float)
    animState.time += dt
    if animState.time > animState.anim.length
        animState.time -= animState.anim.length
        animState.frame = 0
    elif animState.frame < length(animState.anim.frames) - 1
        if animState.time >= animState.anim.frames[animState.frame + 1].timestamp
            animState.frame += 1
