import gg

struct View {
mut:
	radius f32 = 5.0
	input_spacing f32 = 15.0
	// blocks
	b_x []f32
	b_y []f32
	b_w []f32
	b_h []f32
	b_inps [][]int // index of the ports
	b_name []string // name of the block
	// ports
	p_x []f32
	p_y []f32
	p_input []bool // is input or output
	p_name []f32
	p_block []int // index of block
	p_link []int // index of link
	// links
	l_inp []int // index of the input port
	l_out []int
	l_start_x []f32
	l_start_y []f32
	l_end_x []f32
	l_end_y []f32
}

fn (mut v View) new_block(name string, x f32, y f32, inputs []string, outputs []string)

// is the position in the radius
// returns the first that validates the condition
fn (v View) which_port_is_clicked(x f32, y f32, r f32) int {
	for i in 0 .. v.p_x.len {
		dx := v.p_x[i] - x
		dy := v.p_y[i] - y
		if dx * dx + dy * dy < r * r { 
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
	ctx gg.Context = unsafe { nil } 
	selected_i int // selected link
	selected_variant Variant
	l_start bool // is the input or the output of the link is selected
	b_dx f32 // offset from block_x to mouse click_x
	b_dy f32
	v View
}



fn main() {
	mut app := App{}
	app.ctx = gg.new_context(
		user_data: &app
		event_fn:
		frame_fn:
	}
	
	app.ctx.run()
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.mouse_down {
			if app.selected_i != -1 {
				if app.selected_variant == .link {
					p_i :=  app.v.which_port_is_clicked(e.mouse_x, e.mouse_y, app.v.radius) 
					// move already selected link
					if app.l_start {
						if p_i != -1 {
							if !app.v.p_input[p_i] {
								app.v.l_start_x[app.selected_i] = v.p_x
								app.v.l_start_y[app.selected_i] = v.p_y 
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
								app.v.l_end_x[app.selected_i] = v.p_x
								app.v.l_end_y[app.selected_i] = v.p_y 
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
				}
			} else {
				// new link or select link
				p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y, app.v.radius) 
				if p_i != -1 {
					app.selected_variant = .link
					if app.v.p_link[p_i] != -1 {
						// select link
						app.selected_i = app.v.p_link[p_i]
						app.l_start = app.v.p_input[p_i]
					} else {
						// create link
						app.v.p_link[p_i] = app.v.l_inp.len 
						if app.v.p_input[p_i] {
							app.v.l_out << p_i
							app.v.l_inp << -1
							app.v.l_end_x << app.v.p_x
							app.v.l_end_y << app.v.p_y
							app.v.l_start_x << e.mouse_x
							app.v.l_start_y << e.mouse_y
						} else {
							app.v.l_inp << p_i
							app.v.l_out << -1
							app.v.l_start_x << app.v.p_x
							app.v.l_start_y << app.v.p_y
							app.v.l_end_x << e.mouse_x
							app.v.l_end_y << e.mouse_y
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
		.mouse_up {
			if app.selected_i != -1 {
				if app.selected_variant == .list {
					p_i := app.v.which_port_is_clicked(e.mouse_x, e.mouse_y, app.v.radius) 
					if p_i == -1 {
						app.l_end_x[selected_i] = -1.0
						app.l_end_y[selected_i] = -1.0
						app.l_start_x[selected_i] = -1.0
						app.l_start_y[selected_i] = -1.0
						app.l_inp[selected_i] = -1
						app.l_out[selected_i] = -1
					} else {
						if app.p_input[p_i] {
							app.l_end_x[selected_i] = app.p_x[p_i]
							app.l_end_y[selected_i] = app.p_y[p_i]
							app.l_out[selected_i] = p_i
						} else {
							app.l_start_x[selected_i] = app.p_x[p_i]
							app.l_start_y[selected_i] = app.p_y[p_i]
							app.l_inp[selected_i] = p_i
						}
					}
				} else if app.selected_variant == .block {
					app.v.b_x[app.selected_i] = e.mouse_x - app.b_dx
					app.v.b_y[app.selected_i] = e.mouse_y - app.b_dy 
					for i, idx in app.v.b_inps {
						app.v.p_x[idx] = app.v.b_x[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing + app.v.input_spacing/2
						app.v.l_end_x[app.v.p_link[idx]] = app.v.p_x[idx]
						app.v.l_end_y[app.v.p_link[idx]] = app.v.p_y[idx]
					}
					for i, idx in app.v.b_outs {
						app.v.p_x[idx] = app.v.b_x[app.selected_i] + app.v.b_w[app.selected_i]
						app.v.p_y[idx] = app.v.b_y[app.selected_i] + i * app.v.input_spacing + app.v.input_spacing/2
						app.v.l_start_x[app.v.p_link[idx]] = app.v.p_x[idx]
						app.v.l_start_y[app.v.p_link[idx]] = app.v.p_y[idx]
					}
				}
				app.selected_i = -1
			}
		}
		else {}
	}
}

fn on_frame(mut app App) {
	cfg := gg.TextCfg{align: center, vertical_align: middle}
	app.ctx.begin()
	for i in 0 .. app.v.b_x.len {
		app.ctx.draw_rect_filled(app.v.b_x[i], app.v.b_y[i], app.v.b_w[i], app.v.b_h[i], gg.blue)
		app.ctx.draw_text(app.v.b_x[i] + app.v.b_w[i]/2, app.v.b_y[i] + app.v.b_h[i]/2, app.v.b_name[i], cfg)
	}	
	for i in 0 .. app.v.p_x.len {
		app.ctx.draw_circle_filled(app.v.p_x[i], app.v.p_y[i], app.v.radius, gg.light_gray)
		app.ctx.draw_text(app.v.p_x[i], app.v.p_y[i], app.v.p_name[i], cfg)
	}
	for i in 0 .. app.v.l_start_x.len {
		app.ctx.draw_line(app.v.l_start_x[i], app.v.l_start_y[i], app.v.l_end_x[i], app.v.l_end_y[i], gg.black)
	}
	app.ctx.end()
}
