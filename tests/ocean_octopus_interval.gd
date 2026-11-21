extends SceneTree
var failures: Array[String] = []
var appearances: Array[Vector2] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func advance(encounters: Node,seconds: float,ascent: float = 0):
    for step in ceili(seconds/.01):
        encounters.target.position.y -= ascent*.01
        encounters.camera.position = encounters.target.position
        encounters.camera.force_update_scroll()
        encounters._physics_process(.01)
        for visitor in encounters.visitors: visitor._physics_process(.01)
func run():
    root.size = Vector2i(1152,648)
    var player := CharacterBody2D.new()
    player.position = Vector2(960,38800)
    root.add_child(player)
    var camera := Camera2D.new()
    camera.position = player.position
    camera.zoom = Vector2.ONE*1.35
    root.add_child(camera)
    camera.make_current()
    camera.force_update_scroll()
    var encounters = load("res://scenes/enemies/ocean_octopus_encounters.tscn").instantiate()
    root.add_child(encounters)
    encounters.configure(player,camera)
    encounters.enabled = true
    encounters.set_physics_process(false)
    for visitor in encounters.visitors: visitor.set_physics_process(false)
    encounters.appeared.connect(func(visitor):appearances.append(visitor.global_position))
    advance(encounters,10)
    check(appearances.is_empty(),"Standing still never produces timed spawns")
    advance(encounters,.4,420)
    check(appearances.is_empty(),"Octopus waits for its upcoming water section")
    advance(encounters,.6,420)
    check(appearances.size()==1,"Ascending toward the first section produces one entrance ahead")
    check(absf(appearances[0].y-(38800-900))<.1,"Entrance is placed at a fixed world height")
    var first = encounters.visitors[0]
    var old: Vector2 = first.global_position
    camera.position.x += 200
    camera.force_update_scroll()
    check(first.global_position==old,"A visitor is never attached to camera panning")
    advance(encounters,12)
    check(appearances.size()==1,"Waiting at the same height does not spawn more enemies")
    advance(encounters,encounters.encounter_spacing/420+.15,420)
    check(appearances.size()==2,"Next world section creates exactly one more encounter")
    check(absf(appearances[0].y-appearances[1].y-1800)<.1,"Reduced octopus density leaves 1800 pixels between encounters")
    check((appearances[0].x-960)*(appearances[1].x-960)<0,"Consecutive visitors use alternating lanes")
    player.position.y -= 2800
    advance(encounters,.1,420)
    check(appearances.size()<=3,"Teleport skips passed sections without a burst of catch-up spawns")
    var count := appearances.size()
    encounters.finish_current_visit()
    advance(encounters,5,420)
    check(appearances.size()==count,"Death completes old actions without new spawns")
    encounters.reset()
    check(is_inf(encounters._next_encounter_y),"Retry clears progression anchors")
    print("OCEAN_OCTOPUS_INTERVAL_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
