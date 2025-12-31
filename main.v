import gg
import pbp_graph as pg

@[heap]
struct App {
mut:
	ctx              &gg.Context = unsafe { nil }
	selected_i       int         = -1 // selected link
	selected_variant pg.Variant
	l_start          bool // is the input or the output of the link is selected/controled
	b_dx             f32  // offset from block_x to mouse click_x
	b_dy             f32
	v                pg.View
	mouse_clicked    bool
	mouse_x          f32
	mouse_y          f32
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
	app.mouse_y = e.mouse_y
	match e.typ {
		.mouse_move {
			if app.mouse_clicked && app.selected_i != -1 {
				if app.selected_variant == .link {
					p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y)
					// move already selected link
					if app.l_start {
						if p_i != -1 {
							if !app.v.p_input[p_i] {
								app.v.l_start_x[app.selected_i] = app.v.p_x[p_i]
								app.v.l_start_y[app.selected_i] = app.v.p_y[p_i]
							} else {
								app.v.l_start_x[app.selected_i] = e.mouse_x
								app.v.l_start_y[app.selected_i] = e.mouse_y
							}
						} else {
							app.v.l_start_x[app.selected_i] = e.mouse_x
							app.v.l_start_y[app.selected_i] = e.mouse_y
						}
					} else {
						if p_i != -1 {
							if app.v.p_input[p_i] {
								app.v.l_end_x[app.selected_i] = app.v.p_x[p_i]
								app.v.l_end_y[app.selected_i] = app.v.p_y[p_i]
							} else {
								app.v.l_end_x[app.selected_i] = e.mouse_x
								app.v.l_end_y[app.selected_i] = e.mouse_y
							}
						} else {
							app.v.l_end_x[app.selected_i] = e.mouse_x
							app.v.l_end_y[app.selected_i] = e.mouse_y
						}
					}
				} else if app.selected_variant == .block {
					app.v.b_x[app.selected_i] = e.mouse_x - app.b_dx
					app.v.b_y[app.selected_i] = e.mouse_y - app.b_dy
					for i, idx in app.v.b_inps[app.selected_i] {
						app.v.p_x[idx] = app.v.b_x[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing +
							app.v.input_spacing / 2
						for l in app.v.p_link[idx] {
							app.v.l_end_x[l] = app.v.p_x[idx]
							app.v.l_end_y[l] = app.v.p_y[idx]
						}
					}
					for i, idx in app.v.b_outs[app.selected_i] {
						app.v.p_x[idx] = app.v.b_x[app.selected_i] + app.v.b_w[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing +
							app.v.input_spacing / 2
						for l in app.v.p_link[idx] {
							app.v.l_start_x[l] = app.v.p_x[idx]
							app.v.l_start_y[l] = app.v.p_y[idx]
						}
					}
				}
			}
		}
		.mouse_down {
			if app.selected_i == -1 {
				app.mouse_clicked = true
				p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y)
				if p_i != -1 {
					// new link or select link
					app.selected_variant = .link
					// create link
					app.v.p_link[p_i] << app.v.l_inp.len
					app.selected_i = app.v.l_inp.len
					if app.v.p_input[p_i] {
						// we need an input for the link as the input for the block is the output for the link
						app.l_start = true
						app.v.l_out << p_i
						app.v.l_inp << -1
						app.v.l_end_x << app.v.p_x[p_i]
						app.v.l_end_y << app.v.p_y[p_i]
						app.v.l_start_x << e.mouse_x
						app.v.l_start_y << e.mouse_y
					} else {
						app.l_start = false
						app.v.l_inp << p_i
						app.v.l_out << -1
						app.v.l_start_x << app.v.p_x[p_i]
						app.v.l_start_y << app.v.p_y[p_i]
						app.v.l_end_x << e.mouse_x
						app.v.l_end_y << e.mouse_y
					}
				} else {
					l_i := app.v.which_link_is_clicked(e.mouse_x, e.mouse_y)
					if l_i != -1 {
						// select link
						app.selected_variant = .link
						app.selected_i = l_i
						if e.mouse_x >= app.v.l_start_x[l_i] {
							if (e.mouse_x - app.v.l_start_x[l_i]) >= (app.v.l_end_x[l_i] - e.mouse_x) {
								app.l_start = false
								idx := app.v.p_link[app.v.l_out[l_i]].index(l_i)
								if idx != -1 {
									app.v.p_link[app.v.l_out[l_i]].delete(idx)
								}
								app.v.l_out[l_i] = -1
							} else {
								app.l_start = true
								idx := app.v.p_link[app.v.l_inp[l_i]].index(l_i)
								if idx != -1 {
									app.v.p_link[app.v.l_inp[l_i]].delete(idx)
								}
								app.v.l_inp[l_i] = -1
							}
						} else {
							if (e.mouse_x - app.v.l_end_x[l_i]) <= (app.v.l_start_x[l_i] - e.mouse_x) {
								app.l_start = false
								idx := app.v.p_link[app.v.l_out[l_i]].index(l_i)
								if idx != -1 {
									app.v.p_link[app.v.l_out[l_i]].delete(idx)
								}
								app.v.l_out[l_i] = -1
							} else {
								app.l_start = true
								idx := app.v.p_link[app.v.l_inp[l_i]].index(l_i)
								if idx != -1 {
									app.v.p_link[app.v.l_inp[l_i]].delete(idx)
								}
								app.v.l_inp[l_i] = -1
							}
						}
					} else {
						b_i := app.v.which_block_is_clicked(e.mouse_x, e.mouse_y)
						if b_i != -1 {
							// select block
							app.selected_variant = .block
							app.selected_i = b_i
							app.b_dx = e.mouse_x - app.v.b_x[b_i]
							app.b_dy = e.mouse_y - app.v.b_y[b_i]
						}
					}
				}
			}
		}
		.mouse_up {
			app.mouse_clicked = false
			if app.selected_i != -1 {
				if app.selected_variant == .link {
					p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y)
					if p_i == -1 || p_i == app.v.l_out[app.selected_i]
						|| p_i == app.v.l_inp[app.selected_i]
						|| (p_i != -1 && app.v.p_input[p_i] == app.l_start) {
						if app.v.l_inp[app.selected_i] != -1 {
							idx := app.v.p_link[app.v.l_inp[app.selected_i]].index(app.selected_i)
							if idx != -1 {
								app.v.p_link[app.v.l_inp[app.selected_i]].delete(idx)
							}
						}
						if app.v.l_out[app.selected_i] != -1 {
							idx := app.v.p_link[app.v.l_out[app.selected_i]].index(app.selected_i)
							if idx != -1 {
								app.v.p_link[app.v.l_out[app.selected_i]].delete(idx)
							}
						}
						app.v.l_end_x[app.selected_i] = -1.0
						app.v.l_end_y[app.selected_i] = -1.0
						app.v.l_start_x[app.selected_i] = -1.0
						app.v.l_start_y[app.selected_i] = -1.0
						app.v.l_inp[app.selected_i] = -1
						app.v.l_out[app.selected_i] = -1
					} else {
						if app.v.p_input[p_i] {
							app.v.p_link[p_i] << app.selected_i
							app.v.l_end_x[app.selected_i] = app.v.p_x[p_i]
							app.v.l_end_y[app.selected_i] = app.v.p_y[p_i]
							app.v.l_out[app.selected_i] = p_i
						} else {
							app.v.p_link[p_i] << app.selected_i
							app.v.l_start_x[app.selected_i] = app.v.p_x[p_i]
							app.v.l_start_y[app.selected_i] = app.v.p_y[p_i]
							app.v.l_inp[app.selected_i] = p_i
						}
					}
				} else if app.selected_variant == .block {
					app.v.b_x[app.selected_i] = e.mouse_x - app.b_dx
					app.v.b_y[app.selected_i] = e.mouse_y - app.b_dy
					for i, idx in app.v.b_inps[app.selected_i] {
						app.v.p_x[idx] = app.v.b_x[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing +
							app.v.input_spacing / 2
						for l in app.v.p_link[idx] {
							app.v.l_end_x[l] = app.v.p_x[idx]
							app.v.l_end_y[l] = app.v.p_y[idx]
						}
					}
					for i, idx in app.v.b_outs[app.selected_i] {
						app.v.p_x[idx] = app.v.b_x[app.selected_i] + app.v.b_w[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing +
							app.v.input_spacing / 2
						for l in app.v.p_link[idx] {
							app.v.l_start_x[l] = app.v.p_x[idx]
							app.v.l_start_y[l] = app.v.p_y[idx]
						}
					}
				}
				app.selected_i = -1
			}
		}
		else {}
	}
}

fn on_frame(mut app App) {
	cfg := gg.TextCfg{
		align:          .center
		vertical_align: .middle
		size:           int(app.v.char_x) * 2
	}
	app.ctx.begin()
	app.v.draw(app.ctx, app.mouse_x, app.mouse_y, app.selected_i, app.selected_variant,
		cfg, app.l_start)
	app.ctx.end()
}
