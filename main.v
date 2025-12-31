import gg
import pbp_graph as pg

@[heap]
struct App {
mut:
	ctx     &gg.Context = unsafe { nil }
	v       pg.View
	mouse_x f32
	mouse_y f32
}

fn main() {
	mut app := App{}
	app.ctx = gg.new_context(
		user_data:    &app
		event_fn:     on_event
		frame_fn:     on_frame
		window_title: 'PBP editor'
		bg_color:     gg.white
	)

	app.v.new_block('hello', 32.0, 54.0, ['int', 'f64'], ['[]f32', 'string'])
	app.v.new_block('very long string', 320.0, 154.0, ['string'], ['[]f32', 'string', 'int'])

	app.ctx.run()
}

fn on_event(e &gg.Event, mut app App) {
	app.mouse_x = e.mouse_x
	app.v.events(e)
	app.mouse_y = e.mouse_y
}

fn on_frame(mut app App) {
	cfg := gg.TextCfg{
		align:          .center
		vertical_align: .middle
		size:           int(app.v.char_x) * 2
	}
	app.ctx.begin()
	app.v.draw(app.ctx, app.mouse_x, app.mouse_y, cfg)
	app.ctx.end()
}
