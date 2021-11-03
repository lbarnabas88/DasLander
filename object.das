require body
require colliders
require sprites

require math
require daslib/media

struct Object
    body : Body
    collider : Collider
    sprite : Sprite
    renderer : SpriteRenderer

def updateObject(var o: Object&; dt: float)
    updateBody(o.body, dt)

def drawObject(o: Object)
    drawSprite(o.body.position.x, o.body.position.y, o.sprite, o.renderer)

def drawCollider(o: Object)
    if o.collider is aabb
        let pos = o.body.position
        let aabb = o.collider as aabb
        fill_rect(pos.x + aabb.min.x, pos.y + aabb.min.y, aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y, 0x8800ff00)
    elif o.collider is circle
        let pos = o.body.position
        let circle = o.collider as circle
        fill_circle(pos.x, pos.y, circle.radius, 0x8800ff00)

struct Manifold
    penetration : float
    normal : float2

def resolveCollision(var a : Body; var b : Body; normal : float2)
    let relativeVelocity = b.velocity - a.velocity
    let velocityAlongNormal = dot(relativeVelocity, normal)
    if velocityAlongNormal > 0.0
        return
    let e = min(a.restitution, b.restitution)
    var j = -(1.0 + e) * velocityAlongNormal
    j /= a.inv_mass + b.inv_mass

    let impulse = j * normal
    a.velocity -= a.inv_mass * impulse
    b.velocity += b.inv_mass * impulse

let CORRECTION_PERCENT = 0.2
let CORRECTION_SLOP = 0.01

def positionalCorrection(var a : Body; var b : Body; penetration : float; normal : float2) : void
    let correction = max(penetration - CORRECTION_SLOP, 0.0) / (a.inv_mass + b.inv_mass) * CORRECTION_PERCENT * normal;
    a.position -= a.inv_mass * correction;
    b.position += b.inv_mass * correction;

def colloideCircleVSCircle(a_obj, b_obj : Object; var m : Manifold&) : bool
    assert(a_obj.collider is circle && b_obj.collider is circle)
    let a_circle = a_obj.collider as circle
    let b_circle = b_obj.collider as circle

    if !doesIntersect(a_obj.body.position, a_circle, b_obj.body.position, b_circle)
        return false
    let difference = b_obj.body.position - a_obj.body.position
    let distance = length(difference)
    if distance > 0.0
        let radii = a_circle.radius + b_circle.radius
        m.penetration = radii - distance
        m.normal = difference / distance
    else
        m.penetration = a_circle.radius
        m.normal = float2(1.0, 0.0)
    return true

def colloideAabbVsAabb(a_pos, b_pos : float2; a_aabb, b_aabb : AABBCollider; var m : Manifold&) : bool
    var a_center = a_pos.x + (a_aabb.max.x + a_aabb.min.x) / 2.0
    var b_center = b_pos.x + (b_aabb.max.x + b_aabb.min.x) / 2.0
    var a_extent = (a_aabb.max.x - a_aabb.min.x) / 2.0
    var b_extent = (b_aabb.max.x - b_aabb.min.x) / 2.0
    var x_difference = b_center - a_center

    let x_overlap = a_extent + b_extent - abs(x_difference)
    if x_overlap > 0.0
        a_center = a_pos.y + (a_aabb.max.y + a_aabb.min.y) / 2.0
        b_center = b_pos.y + (b_aabb.max.y + b_aabb.min.y) / 2.0
        a_extent = (a_aabb.max.y - a_aabb.min.y) / 2.0
        b_extent = (b_aabb.max.y - b_aabb.min.y) / 2.0
        var y_difference = b_center - a_center
        let y_overlap = a_extent + b_extent - abs(y_difference)
        if y_overlap > 0.0
            if x_overlap > y_overlap
                if y_difference < 0.0
                    m.normal = float2(0, -1)
                else
                    m.normal = float2(0, 1)
                m.penetration = y_overlap
            else
                if x_difference < 0.0
                    m.normal = float2(-1, 0)
                else
                    m.normal = float2(1, 0)
                m.penetration = x_overlap
            return true
    return false

def colloideAabbVsCircle(a_obj, b_obj : Object; var m : Manifold&) : bool
    assert(a_obj.collider is aabb && b_obj.collider is circle)
    var a_aabb = a_obj.collider as aabb
    let b_circle = b_obj.collider as circle

    let difference = b_obj.body.position - a_obj.body.position
    var closest = difference

    let x_extent = (a_aabb.max.x - a_aabb.min.x) / 2.0
    let y_extent = (a_aabb.max.y - a_aabb.min.y) / 2.0

    closest.x = clamp(x_extent, x_extent, closest.x)
    closest.y = clamp(y_extent, y_extent, closest.y)

    var inside = false
    if difference == closest
        inside = true
        if abs(difference.x) > abs(difference.y)
            if closest.x > 0.0
                closest.x = x_extent
            else
                closest.x = -x_extent
        else
            if closest.y > 0.0
                closest.y = y_extent
            else
                closest.y = -y_extent
    
    var normal = difference - closest
    var d = length_sq(normal)
    let r = b_circle.radius

    if d > r * r && !inside
        return false

    d = sqrt(d)

    if inside
        m.normal = -normalize(difference)
    else
        m.normal = normalize(difference)
    m.penetration = r - d

    return true

options debugger
require daslib/debug
