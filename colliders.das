require math

struct AABBCollider
    min : float2
    max : float2

struct CircleCollider
    radius : float

variant Collider
    aabb : AABBCollider
    circle : CircleCollider

def doesIntersect(position_a : float2; aabb_a : AABBCollider; position_b : float2; aabb_b : AABBCollider)
    if position_a.x + aabb_a.max.x < position_b.x + aabb_b.min.x || position_a.x + aabb_a.min.x > position_b.x + aabb_b.max.x
        return false
    if position_a.y + aabb_a.max.y < position_b.y + aabb_b.min.y || position_a.y + aabb_a.min.y > position_b.y + aabb_b.max.y
        return false
    return true

def doesIntersect(position_a : float2; circle_a : CircleCollider; position_b : float2; circle_b : CircleCollider)
    var r = circle_a.radius + circle_b.radius
    r *= r
    return length_sq(position_a - position_b) <= r
