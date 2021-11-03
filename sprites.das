require daslib/media

struct Sprite
    sheet : ImageHandle
    region : float4

struct SpriteRenderer
    pivot : float2
    size : float2
    color : uint = 0xFFFFFFFF

def drawSprite(x, y : float; sprite : Sprite; renderer : SpriteRenderer)
    sprite.sheet |> draw_image_region(x - renderer.pivot.x, y - renderer.pivot.y, sprite.region, renderer.color, renderer.size)
