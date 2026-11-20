extends SceneTree
var failures: Array[String] = []
var clock: float = 0.0
var appearances: Array[float] = []
func _initialize(): run.call_deferred()
func check(ok: bool,message: String):
    if not ok:
        failures.append(message)
        push_error(message)
func advance(encounters: Node,seconds: float,ascent: float = 420.0):
    for step in ceili(seconds/.01):
        clock += .01
        encounters.target.position.y -= ascent*.01
        encounters.visitors[0].camera.position.y -= ascent*.01
        encounters._physics_process(.01)
        for visitor in encounters.visitors: visitor._physics_process(.01)
func run():
    var player := CharacterBody2D.new()
    root.add_child(player)
    var camera := Camera2D.new()
    root.add_child(camera)
    camera.make_current()
    var encounters = load("res://scenes/enemies/ocean_octopus_encounters.tscn").instantiate()
    root.add_child(encounters)
    encounters.configure(player,camera)
    encounters.enabled = true
    encounters.set_physics_process(false)
    for visitor in encounters.visitors:
        visitor.set_physics_process(false)
        visitor.set_process(false)
    encounters.appeared.connect(func(_visitor):appearances.append(clock))
    advance(encounters,2.99)
    check(appearances.is_empty(),"No octopus appears before three seconds")
    advance(encounters,.03)
    check(appearances.size()==1,"First encounter begins at three seconds")
    advance(encounters,3.02)
    check(appearances.size()==2 and absf(appearances[1]-appearances[0]-3.0)<.03,"Next octopus appears three seconds later while the first is still active")
    check(encounters.visitors[0].visible and encounters.visitors[1].visible,"Two independent visits overlap without hiding the earlier one")
    check(encounters.visitors[0]._visit_elapsed>3 and encounters.visitors[1]._visit_elapsed<.1,"A new entrance preserves the old octopus's existing five-second progress")
    check(encounters.visitors[0]._side!=encounters.visitors[1]._side,"Entrances still alternate sides")
    advance(encounters,2.02)
    check(not encounters.visitors[0].visible and encounters.visitors[1].visible,"First octopus completes five seconds without shortening the next visit")
    advance(encounters,1.02)
    check(appearances.size()==3 and absf(appearances[2]-appearances[1]-3.0)<.03,"The freed slot is reused for the third three-second encounter")
    encounters.finish_current_visit()
    advance(encounters,6)
    check(appearances.size()==3,"Death stops new encounters while finishing both current visits")
    check(not encounters.visitors[0].visible and not encounters.visitors[1].visible,"Both preserved visits exit naturally")
    encounters.reset()
    check(is_zero_approx(encounters.cycle_elapsed) and not encounters._finishing_visit,"Retry clears encounter timing and death mode")
    advance(encounters,3.1,0)
    check(appearances.size()==3,"Standing still continues to wait for ascent")
    print("OCEAN_OCTOPUS_INTERVAL_FAILURES=",failures.size())
    quit(0 if failures.is_empty() else 1)
