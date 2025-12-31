import gg

struct View {
mut:
	char_x        f32 = 10.0 // width of a single text character
	radius        f32 = 10.0
	input_spacing f32 = 30.0
	link_detect   f32 = 10.0
	// blocks
	b_x    []f32
	b_y    []f32
	b_w    []f32
	b_h    []f32
	b_inps [][]int  // index of the ports
	b_outs [][]int  // index of the ports
	b_name []string // name of the block
	// ports
	p_x     []f32
	p_y     []f32
	p_input []bool // is input or output
	p_name  []string
	p_block []int // index of block
	p_link  []int // index of link
	// links
	l_inp     []int // index of the input port
	l_out     []int
	l_start_x []f32
	l_start_y []f32
	l_end_x   []f32
	l_end_y   []f32
}

fn (v View) which_link_is_clicked(x f32, y f32) int {
	for l in 0 .. v.l_inp.len {
		if v.l_start_x[l] >= 0.0 {
			min_x := f32_min(v.l_start_x[l], v.l_end_x[l])
			max_x := f32_max(v.l_start_x[l], v.l_end_x[l])
			min_y, max_y := if min_x == v.l_start_x[l] {
				v.l_start_y[l], v.l_end_y[l]
			} else {
				v.l_end_y[l], v.l_start_y[l]
			}
			if x >= min_x - v.link_detect && x < max_x + v.link_detect {
				slope := (max_y - min_y) / (max_x - min_x)
				if (x - min_x) * slope >= y - min_y - v.link_detect
					&& (x - min_x) * slope <= y - min_y + v.link_detect {
					return l
				}
			}
		}
	}
	return -1
}

fn (mut v View) new_block(name string, x f32, y f32, inputs []string, outputs []string) {
	i := v.b_x.len
	v.b_x << x
	v.b_y << y
	w := v.input_spacing + v.char_x * name.len
	v.b_w << w
	v.b_h << (int_max(inputs.len, outputs.len) + 1) * v.input_spacing
	v.b_name << name
	mut inps := []int{}
	mut outs := []int{}
	for j, inp in inputs {
		inps << v.p_x.len
		v.p_x << x
		v.p_y << y + j * v.input_spacing + v.input_spacing / 2
		v.p_input << true
		v.p_name << inp
		v.p_block << i
		v.p_link << -1
	}
	v.b_inps << inps
	for j, out in outputs {
		outs << v.p_x.len
		v.p_x << x + w
		v.p_y << y + j * v.input_spacing + v.input_spacing / 2
		v.p_input << false
		v.p_name << out
		v.p_block << i
		v.p_link << -1
	}
	v.b_outs << outs
}

// is the position in the radius
// returns the first that validates the condition
fn (v View) which_port_is_clicked(x f32, y f32) int {
	for i in 0 .. v.p_x.len {
		dx := v.p_x[i] - x
		dy := v.p_y[i] - y
		if dx * dx + dy * dy < v.radius * v.radius {
			return i
		}
	}
	return -1
}

fn (v View) which_block_is_clicked(x f32, y f32) int {
	for i in 0 .. v.b_x.len {
		if x >= v.b_x[i] && x < v.b_x[i] + v.b_w[i] && y >= v.b_y[i] && y < v.b_y[i] + v.b_h[i] {
			return i
		}
	}
	return -1
}

enum Variant {
	block
	link
}

@[heap]
struct App {
mut:
	ctx              &gg.Context = unsafe { nil }
	selected_i       int         = -1 // selected link
	selected_variant Variant
	l_start          bool // is the input or the output of the link is selected/controled
	b_dx             f32  // offset from block_x to mouse click_x
	b_dy             f32
	v                View
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
						if app.v.p_link[idx] != -1 {
							app.v.l_end_x[app.v.p_link[idx]] = app.v.p_x[idx]
							app.v.l_end_y[app.v.p_link[idx]] = app.v.p_y[idx]
						}
					}
					for i, idx in app.v.b_outs[app.selected_i] {
						app.v.p_x[idx] = app.v.b_x[app.selected_i] + app.v.b_w[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing +
							app.v.input_spacing / 2
						if app.v.p_link[idx] != -1 {
							app.v.l_start_x[app.v.p_link[idx]] = app.v.p_x[idx]
							app.v.l_start_y[app.v.p_link[idx]] = app.v.p_y[idx]
						}
					}
				}
			}
		}
		.mouse_down {
			if app.selected_i == -1 {
				app.mouse_clicked = true
				// new link or select link
				p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y)
				if p_i != -1 {
					app.selected_variant = .link
					if app.v.p_link[p_i] != -1 {
						// select link
						app.selected_i = app.v.p_link[p_i]
						app.l_start = app.v.p_input[p_i]
					} else {
						// create link
						app.v.p_link[p_i] = app.v.l_inp.len
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
					}
				} else {
					l_i := app.v.which_link_is_clicked(e.mouse_x, e.mouse_y)
					if l_i != -1 {
						app.selected_variant = .link
						app.selected_i = l_i
						if e.mouse_x >= app.v.l_start_x[l_i] {
							if (e.mouse_x - app.v.l_start_x[l_i]) >= (app.v.l_end_x[l_i] - e.mouse_x) {
								app.l_start = false
								app.v.p_link[app.v.l_out[l_i]] = -1
								app.v.l_out[l_i] = -1
							} else {
								app.l_start = true
								app.v.p_link[app.v.l_inp[l_i]] = -1
								app.v.l_inp[l_i] = -1
							}
						} else {
							if (e.mouse_x - app.v.l_end_x[l_i]) <= (app.v.l_start_x[l_i] - e.mouse_x) {
								app.l_start = false
								app.v.p_link[app.v.l_out[l_i]] = -1
								app.v.l_out[l_i] = -1
							} else {
								app.l_start = true
								app.v.p_link[app.v.l_inp[l_i]] = -1
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
			eprintln(app.v.l_start_x)
		}
		.mouse_up {
			app.mouse_clicked = false
			if app.selected_i != -1 {
				if app.selected_variant == .link {
					p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y)
					eprintln(app.l_start)
					if p_i == -1 || p_i == app.v.l_out[app.selected_i]
						|| p_i == app.v.l_inp[app.selected_i]
						|| (p_i != -1 && app.v.p_input[p_i] == app.l_start) {
						if app.v.l_inp[app.selected_i] != -1 {
							app.v.p_link[app.v.l_inp[app.selected_i]] = -1
						}
						if app.v.l_out[app.selected_i] != -1 {
							app.v.p_link[app.v.l_out[app.selected_i]] = -1
						}
						app.v.l_end_x[app.selected_i] = -1.0
						app.v.l_end_y[app.selected_i] = -1.0
						app.v.l_start_x[app.selected_i] = -1.0
						app.v.l_start_y[app.selected_i] = -1.0
						app.v.l_inp[app.selected_i] = -1
						app.v.l_out[app.selected_i] = -1
					} else {
						if app.v.p_input[p_i] {
							app.v.p_link[p_i] = app.selected_i
							app.v.l_end_x[app.selected_i] = app.v.p_x[p_i]
							app.v.l_end_y[app.selected_i] = app.v.p_y[p_i]
							app.v.l_out[app.selected_i] = p_i
						} else {
							app.v.p_link[p_i] = app.selected_i
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
						if app.v.p_link[idx] != -1 {
							app.v.l_end_x[app.v.p_link[idx]] = app.v.p_x[idx]
							app.v.l_end_y[app.v.p_link[idx]] = app.v.p_y[idx]
						}
					}
					for i, idx in app.v.b_outs[app.selected_i] {
						app.v.p_x[idx] = app.v.b_x[app.selected_i] + app.v.b_w[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing +
							app.v.input_spacing / 2
						if app.v.p_link[idx] != -1 {
							app.v.l_start_x[app.v.p_link[idx]] = app.v.p_x[idx]
							app.v.l_start_y[app.v.p_link[idx]] = app.v.p_y[idx]
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
	p_i := app.v.which_port_is_clicked(app.mouse_x, app.mouse_y)
	l_i := app.v.which_link_is_clicked(app.mouse_x, app.mouse_y)
	app.ctx.begin()
	for i in 0 .. app.v.b_x.len {
		app.ctx.draw_rect_filled(app.v.b_x[i], app.v.b_y[i], app.v.b_w[i], app.v.b_h[i],
			gg.blue)
		app.ctx.draw_text(int(app.v.b_x[i] + app.v.b_w[i] / 2), int(app.v.b_y[i] + app.v.b_h[i] / 2),
			app.v.b_name[i], cfg)
	}
	if (app.selected_variant == .block && app.selected_i != -1)
		|| (p_i == -1 && (l_i == -1 || !(app.selected_variant == .link && app.selected_i != -1))) {
		if app.selected_i != -1 {
			app.ctx.draw_rect_filled(app.v.b_x[app.selected_i], app.v.b_y[app.selected_i],
				app.v.b_w[app.selected_i], app.v.b_h[app.selected_i], gg.dark_blue)
			app.ctx.draw_text(int(app.v.b_x[app.selected_i] + app.v.b_w[app.selected_i] / 2),
				int(app.v.b_y[app.selected_i] + app.v.b_h[app.selected_i] / 2), app.v.b_name[app.selected_i],
				cfg)
		} else {
			b_i := app.v.which_block_is_clicked(app.mouse_x, app.mouse_y)
			if b_i != -1 {
				app.ctx.draw_rect_filled(app.v.b_x[b_i], app.v.b_y[b_i], app.v.b_w[b_i],
					app.v.b_h[b_i], gg.dark_blue)
				app.ctx.draw_text(int(app.v.b_x[b_i] + app.v.b_w[b_i] / 2), int(app.v.b_y[b_i] +
					app.v.b_h[b_i] / 2), app.v.b_name[b_i], cfg)
			}
		}
	}
	for i in 0 .. app.v.p_x.len {
		app.ctx.draw_circle_filled(app.v.p_x[i], app.v.p_y[i], app.v.radius, gg.light_gray)
		app.ctx.draw_text(int(app.v.p_x[i]), int(app.v.p_y[i]), app.v.p_name[i], cfg)
	}
	if p_i != -1 && !(app.selected_variant == .block && app.selected_i != -1) {
		app.ctx.draw_circle_filled(app.v.p_x[p_i], app.v.p_y[p_i], app.v.radius, gg.dark_gray)
		app.ctx.draw_text(int(app.v.p_x[p_i]), int(app.v.p_y[p_i]), app.v.p_name[p_i],
			cfg)
	}
	for i in 0 .. app.v.l_start_x.len {
		if app.v.l_start_x[i] >= 0.0 {
			app.ctx.draw_line(app.v.l_start_x[i], app.v.l_start_y[i], app.v.l_end_x[i],
				app.v.l_end_y[i], gg.black)
		}
	}
	if p_i == -1 && (l_i != -1 || (app.selected_variant == .link && app.selected_i != -1))
		&& !(app.selected_variant == .block && app.selected_i != -1) {
		if app.selected_i != -1 {
			app.ctx.draw_line(app.v.l_start_x[app.selected_i], app.v.l_start_y[app.selected_i],
				app.v.l_end_x[app.selected_i], app.v.l_end_y[app.selected_i], gg.red)
		} else {
			app.ctx.draw_line(app.v.l_start_x[l_i], app.v.l_start_y[l_i], app.v.l_end_x[l_i],
				app.v.l_end_y[l_i], gg.red)
		}
	}
	app.ctx.end()
}
