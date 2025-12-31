module pbp_graph

import gg

pub struct View {
pub mut:
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
	p_block []int   // index of block
	p_link  [][]int // index of link
	// links
	l_inp     []int // index of the input port
	l_out     []int
	l_start_x []f32
	l_start_y []f32
	l_end_x   []f32
	l_end_y   []f32
	// interactions
	selected_i       int = -1 // selected link
	selected_variant Variant
	l_start          bool // is the input or the output of the link is selected/controled, is the selected end of the link its start or its end (for the data flowing in it)
	b_dx             f32  // offset from block_x to mouse click_x
	b_dy             f32
	mouse_clicked    bool
}

pub fn (v View) which_link_is_clicked(x f32, y f32) int {
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

pub fn (mut v View) new_block(name string, x f32, y f32, inputs []string, outputs []string) {
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
		if inp != '' {
			inps << v.p_x.len
			v.p_x << x
			v.p_y << y + j * v.input_spacing + v.input_spacing / 2
			v.p_input << true
			v.p_name << inp
			v.p_block << i
			v.p_link << [[]]
		}
	}
	v.b_inps << inps
	for j, out in outputs {
		if out != '' {
			outs << v.p_x.len
			v.p_x << x + w
			v.p_y << y + j * v.input_spacing + v.input_spacing / 2
			v.p_input << false
			v.p_name << out
			v.p_block << i
			v.p_link << [[]]
		}
	}
	v.b_outs << outs
}

// is the position in the radius
// returns the first that validates the condition
pub fn (v View) which_port_is_clicked(x f32, y f32) int {
	for i in 0 .. v.p_x.len {
		dx := v.p_x[i] - x
		dy := v.p_y[i] - y
		if dx * dx + dy * dy < v.radius * v.radius {
			return i
		}
	}
	return -1
}

pub fn (v View) which_block_is_clicked(x f32, y f32) int {
	for i in 0 .. v.b_x.len {
		if x >= v.b_x[i] && x < v.b_x[i] + v.b_w[i] && y >= v.b_y[i] && y < v.b_y[i] + v.b_h[i] {
			return i
		}
	}
	return -1
}

// Selectables
pub enum Variant {
	block
	link
}

pub fn (v View) is_a_block_selected() bool {
	return v.selected_variant == .block && v.selected_i != -1
}

pub fn (v View) is_a_link_selected() bool {
	return v.selected_variant == .link && v.selected_i != -1
}

pub fn is_none(i int) bool {
	return i == -1
}

pub fn (v View) draw(ctx &gg.Context, mouse_x f32, mouse_y f32, cfg gg.TextCfg) {
	p_i := v.which_port_is_clicked(mouse_x, mouse_y)
	l_i := v.which_link_is_clicked(mouse_x, mouse_y)
	for i in 0 .. v.b_x.len {
		ctx.draw_rect_filled(v.b_x[i], v.b_y[i], v.b_w[i], v.b_h[i], gg.blue)
		ctx.draw_text(int(v.b_x[i] + v.b_w[i] / 2), int(v.b_y[i] + v.b_h[i] / 2), v.b_name[i],
			cfg)
	}
	if v.is_a_block_selected() {
		ctx.draw_rect_filled(v.b_x[v.selected_i], v.b_y[v.selected_i], v.b_w[v.selected_i],
			v.b_h[v.selected_i], gg.dark_blue)
		ctx.draw_text(int(v.b_x[v.selected_i] + v.b_w[v.selected_i] / 2), int(v.b_y[v.selected_i] +
			v.b_h[v.selected_i] / 2), v.b_name[v.selected_i], cfg)
	} else {
		if is_none(p_i) && is_none(l_i) && !v.is_a_link_selected() {
			b_i := v.which_block_is_clicked(mouse_x, mouse_y)
			if !is_none(b_i) {
				ctx.draw_rect_filled(v.b_x[b_i], v.b_y[b_i], v.b_w[b_i], v.b_h[b_i], gg.dark_blue)
				ctx.draw_text(int(v.b_x[b_i] + v.b_w[b_i] / 2), int(v.b_y[b_i] + v.b_h[b_i] / 2),
					v.b_name[b_i], cfg)
			}
		}
	}
	for i in 0 .. v.p_x.len {
		ctx.draw_circle_filled(v.p_x[i], v.p_y[i], v.radius, gg.light_gray)
		ctx.draw_text(int(v.p_x[i]), int(v.p_y[i]), v.p_name[i], cfg)
	}
	if !is_none(p_i) && !v.is_a_block_selected()
		&& (!v.is_a_link_selected() || v.l_start != v.p_input[p_i]) { // if it is the side it can connect to
		ctx.draw_circle_filled(v.p_x[p_i], v.p_y[p_i], v.radius, gg.dark_gray)
		ctx.draw_text(int(v.p_x[p_i]), int(v.p_y[p_i]), v.p_name[p_i], cfg)
	}
	for i in 0 .. v.l_start_x.len {
		if v.l_start_x[i] >= 0.0 {
			ctx.draw_line(v.l_start_x[i], v.l_start_y[i], v.l_end_x[i], v.l_end_y[i],
				gg.black)
		}
	}
	if !v.is_a_block_selected() {
		if v.is_a_link_selected() {
			ctx.draw_line(v.l_start_x[v.selected_i], v.l_start_y[v.selected_i], v.l_end_x[v.selected_i],
				v.l_end_y[v.selected_i], gg.red)
		} else {
			if is_none(p_i) && !is_none(l_i) {
				ctx.draw_line(v.l_start_x[l_i], v.l_start_y[l_i], v.l_end_x[l_i], v.l_end_y[l_i],
					gg.red)
			}
		}
	}
}

pub fn (mut v View) events(e &gg.Event) {
	match e.typ {
		.mouse_move {
			if v.mouse_clicked && !is_none(v.selected_i) {
				if v.selected_variant == .link {
					p_i := v.which_port_is_clicked(e.mouse_x, e.mouse_y)
					// move already selected link
					if v.l_start {
						if is_none(p_i) {
							v.l_start_x[v.selected_i] = e.mouse_x
							v.l_start_y[v.selected_i] = e.mouse_y
						} else {
							if !v.p_input[p_i] {
								v.l_start_x[v.selected_i] = v.p_x[p_i]
								v.l_start_y[v.selected_i] = v.p_y[p_i]
							} else {
								v.l_start_x[v.selected_i] = e.mouse_x
								v.l_start_y[v.selected_i] = e.mouse_y
							}
						}
					} else {
						if is_none(p_i) {
							v.l_end_x[v.selected_i] = e.mouse_x
							v.l_end_y[v.selected_i] = e.mouse_y
						} else {
							if v.p_input[p_i] {
								v.l_end_x[v.selected_i] = v.p_x[p_i]
								v.l_end_y[v.selected_i] = v.p_y[p_i]
							} else {
								v.l_end_x[v.selected_i] = e.mouse_x
								v.l_end_y[v.selected_i] = e.mouse_y
							}
						}
					}
				} else if v.selected_variant == .block {
					v.b_x[v.selected_i] = e.mouse_x - v.b_dx
					v.b_y[v.selected_i] = e.mouse_y - v.b_dy
					for i, idx in v.b_inps[v.selected_i] {
						v.p_x[idx] = v.b_x[v.selected_i]
						v.p_y[idx] = v.b_y[v.selected_i] + i * v.input_spacing + v.input_spacing / 2
						for l in v.p_link[idx] {
							v.l_end_x[l] = v.p_x[idx]
							v.l_end_y[l] = v.p_y[idx]
						}
					}
					for i, idx in v.b_outs[v.selected_i] {
						v.p_x[idx] = v.b_x[v.selected_i] + v.b_w[v.selected_i]
						v.p_y[idx] = v.b_y[v.selected_i] + i * v.input_spacing + v.input_spacing / 2
						for l in v.p_link[idx] {
							v.l_start_x[l] = v.p_x[idx]
							v.l_start_y[l] = v.p_y[idx]
						}
					}
				}
			}
		}
		.mouse_down {
			if is_none(v.selected_i) {
				v.mouse_clicked = true
				p_i := v.which_port_is_clicked(e.mouse_x, e.mouse_y)
				if is_none(p_i) {
					l_i := v.which_link_is_clicked(e.mouse_x, e.mouse_y)
					if l_i != -1 {
						// select link
						v.selected_variant = .link
						v.selected_i = l_i
						if e.mouse_x >= v.l_start_x[l_i] {
							if (e.mouse_x - v.l_start_x[l_i]) >= (v.l_end_x[l_i] - e.mouse_x) {
								v.l_start = false
								idx := v.p_link[v.l_out[l_i]].index(l_i)
								if idx != -1 {
									v.p_link[v.l_out[l_i]].delete(idx)
								}
								v.l_out[l_i] = -1
							} else {
								v.l_start = true
								idx := v.p_link[v.l_inp[l_i]].index(l_i)
								if idx != -1 {
									v.p_link[v.l_inp[l_i]].delete(idx)
								}
								v.l_inp[l_i] = -1
							}
						} else {
							if (e.mouse_x - v.l_end_x[l_i]) <= (v.l_start_x[l_i] - e.mouse_x) {
								v.l_start = false
								idx := v.p_link[v.l_out[l_i]].index(l_i)
								if idx != -1 {
									v.p_link[v.l_out[l_i]].delete(idx)
								}
								v.l_out[l_i] = -1
							} else {
								v.l_start = true
								idx := v.p_link[v.l_inp[l_i]].index(l_i)
								if idx != -1 {
									v.p_link[v.l_inp[l_i]].delete(idx)
								}
								v.l_inp[l_i] = -1
							}
						}
					} else {
						b_i := v.which_block_is_clicked(e.mouse_x, e.mouse_y)
						if !is_none(b_i) {
							// select block
							v.selected_variant = .block
							v.selected_i = b_i
							v.b_dx = e.mouse_x - v.b_x[b_i]
							v.b_dy = e.mouse_y - v.b_y[b_i]
						}
					}
				} else {
					// new link or select link
					v.selected_variant = .link
					// create link
					v.p_link[p_i] << v.l_inp.len
					v.selected_i = v.l_inp.len
					if v.p_input[p_i] {
						// we need an input for the link as the input for the block is the output for the link
						v.l_start = true
						v.l_out << p_i
						v.l_inp << -1
						v.l_end_x << v.p_x[p_i]
						v.l_end_y << v.p_y[p_i]
						v.l_start_x << e.mouse_x
						v.l_start_y << e.mouse_y
					} else {
						v.l_start = false
						v.l_inp << p_i
						v.l_out << -1
						v.l_start_x << v.p_x[p_i]
						v.l_start_y << v.p_y[p_i]
						v.l_end_x << e.mouse_x
						v.l_end_y << e.mouse_y
					}
				}
			}
		}
		.mouse_up {
			v.mouse_clicked = false
			if !is_none(v.selected_i) {
				if v.selected_variant == .link {
					p_i := v.which_port_is_clicked(e.mouse_x, e.mouse_y)
					if is_none(p_i) || p_i == v.l_out[v.selected_i]
						|| p_i == v.l_inp[v.selected_i]
						|| (!is_none(p_i) && v.p_input[p_i] == v.l_start) {
						if !is_none(v.l_inp[v.selected_i]) {
							idx := v.p_link[v.l_inp[v.selected_i]].index(v.selected_i)
							if idx != -1 {
								v.p_link[v.l_inp[v.selected_i]].delete(idx)
							}
						}
						if !is_none(v.l_out[v.selected_i]) {
							idx := v.p_link[v.l_out[v.selected_i]].index(v.selected_i)
							if idx != -1 {
								v.p_link[v.l_out[v.selected_i]].delete(idx)
							}
						}
						v.l_end_x[v.selected_i] = -1.0
						v.l_end_y[v.selected_i] = -1.0
						v.l_start_x[v.selected_i] = -1.0
						v.l_start_y[v.selected_i] = -1.0
						v.l_inp[v.selected_i] = -1
						v.l_out[v.selected_i] = -1
					} else {
						if v.p_input[p_i] {
							v.p_link[p_i] << v.selected_i
							v.l_end_x[v.selected_i] = v.p_x[p_i]
							v.l_end_y[v.selected_i] = v.p_y[p_i]
							v.l_out[v.selected_i] = p_i
						} else {
							v.p_link[p_i] << v.selected_i
							v.l_start_x[v.selected_i] = v.p_x[p_i]
							v.l_start_y[v.selected_i] = v.p_y[p_i]
							v.l_inp[v.selected_i] = p_i
						}
					}
				} else if v.selected_variant == .block {
					v.b_x[v.selected_i] = e.mouse_x - v.b_dx
					v.b_y[v.selected_i] = e.mouse_y - v.b_dy
					for i, idx in v.b_inps[v.selected_i] {
						v.p_x[idx] = v.b_x[v.selected_i]
						v.p_y[idx] = v.b_y[v.selected_i] + i * v.input_spacing + v.input_spacing / 2
						for l in v.p_link[idx] {
							v.l_end_x[l] = v.p_x[idx]
							v.l_end_y[l] = v.p_y[idx]
						}
					}
					for i, idx in v.b_outs[v.selected_i] {
						v.p_x[idx] = v.b_x[v.selected_i] + v.b_w[v.selected_i]
						v.p_y[idx] = v.b_y[v.selected_i] + i * v.input_spacing + v.input_spacing / 2
						for l in v.p_link[idx] {
							v.l_start_x[l] = v.p_x[idx]
							v.l_start_y[l] = v.p_y[idx]
						}
					}
				}
				v.selected_i = -1
			}
		}
		else {}
	}
}
