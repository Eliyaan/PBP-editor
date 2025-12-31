import gg
import pbp_graph as pg
import pbp_g2c as g2c
import os

// TODO: add a way to duplicate a block -> change g2c because the structs will have the same name

@[heap]
struct App {
mut:
	ctx     &gg.Context = unsafe { nil }
	v       pg.View
	mouse_x f32
	mouse_y f32
}

fn main() {
	doc_output := os.execute('v doc .').output.split('\n')
	fns := doc_output.filter(it#[..2] == 'fn')
	fn_names := fns.map(it.all_after(' ').all_before('('))
	inp_strs := fns.map(it.all_after('(').all_before(')'))
	out_strs := fns.map(it.all_after(')')) // TODO : does not support multiple outputs
	inps := inp_strs.map(it.split(',').map(it.trim_space_left().all_after(' ')))
	outs := out_strs.map(it.split(','))

	mut app := App{}
	for i, name in fn_names {
		app.v.new_block(name, 1.0, 1.0, inps[i], outs[i])
	}
	app.ctx = gg.new_context(
		user_data:    &app
		event_fn:     on_event
		frame_fn:     on_frame
		window_title: 'PBP editor'
		bg_color:     gg.white
	)

	app.ctx.run()
	println(g2c.generate_code(app.v))
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
