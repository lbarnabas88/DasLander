require colliders

var gravity = float2(0.0, 100.0)

struct Body
    position : float2
    velocity : float2
    acceleration : float2
    mass : float
    inv_mass : float
    restitution : float
    gravity_scale : float

def updateBody(var body : Body&; dt : float)
    body.velocity += (body.acceleration + gravity * body.gravity_scale) * dt
    body.position += body.velocity * dt
