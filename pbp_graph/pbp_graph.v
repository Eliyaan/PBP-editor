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
		inps << v.p_x.len
		v.p_x << x
		v.p_y << y + j * v.input_spacing + v.input_spacing / 2
		v.p_input << true
		v.p_name << inp
		v.p_block << i
		v.p_link << [[]]
	}
	v.b_inps << inps
	for j, out in outputs {
		outs << v.p_x.len
		v.p_x << x + w
		v.p_y << y + j * v.input_spacing + v.input_spacing / 2
		v.p_input << false
		v.p_name << out
		v.p_block << i
		v.p_link << [[]]
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

pub fn is_a_block_selected(selected_variant Variant, selected_i int) bool {
	return selected_variant == .block && selected_i != -1
}

pub fn is_a_link_selected(selected_variant Variant, selected_i int) bool {
	return selected_variant == .link && selected_i != -1
}

pub fn is_none(i int) bool {
	return i == -1
}

// l_start: is the selected end of the link its start or its end (for the data flowing in it)
pub fn (v View) draw(ctx &gg.Context, mouse_x f32, mouse_y f32, selected_i int, selected_variant Variant, cfg gg.TextCfg, l_start bool) {
	p_i := v.which_port_is_clicked(mouse_x, mouse_y)
	l_i := v.which_link_is_clicked(mouse_x, mouse_y)
	for i in 0 .. v.b_x.len {
		ctx.draw_rect_filled(v.b_x[i], v.b_y[i], v.b_w[i], v.b_h[i], gg.blue)
		ctx.draw_text(int(v.b_x[i] + v.b_w[i] / 2), int(v.b_y[i] + v.b_h[i] / 2), v.b_name[i],
			cfg)
	}
	if is_a_block_selected(selected_variant, selected_i) {
		ctx.draw_rect_filled(v.b_x[selected_i], v.b_y[selected_i], v.b_w[selected_i],
			v.b_h[selected_i], gg.dark_blue)
		ctx.draw_text(int(v.b_x[selected_i] + v.b_w[selected_i] / 2), int(v.b_y[selected_i] +
			v.b_h[selected_i] / 2), v.b_name[selected_i], cfg)
	}
	if is_none(p_i) && is_none(l_i) && !is_a_link_selected(selected_variant, selected_i) {
		b_i := v.which_block_is_clicked(mouse_x, mouse_y)
		if !is_none(b_i) {
			ctx.draw_rect_filled(v.b_x[b_i], v.b_y[b_i], v.b_w[b_i], v.b_h[b_i], gg.dark_blue)
			ctx.draw_text(int(v.b_x[b_i] + v.b_w[b_i] / 2), int(v.b_y[b_i] + v.b_h[b_i] / 2),
				v.b_name[b_i], cfg)
		}
	}
	for i in 0 .. v.p_x.len {
		ctx.draw_circle_filled(v.p_x[i], v.p_y[i], v.radius, gg.light_gray)
		ctx.draw_text(int(v.p_x[i]), int(v.p_y[i]), v.p_name[i], cfg)
	}
	if !is_none(p_i) && !is_a_block_selected(selected_variant, selected_i)
		&& !is_a_link_selected(selected_variant, selected_i) && l_start == v.p_input[p_i] { // if it is the side it can connect to
		ctx.draw_circle_filled(v.p_x[p_i], v.p_y[p_i], v.radius, gg.dark_gray)
		ctx.draw_text(int(v.p_x[p_i]), int(v.p_y[p_i]), v.p_name[p_i], cfg)
	}
	for i in 0 .. v.l_start_x.len {
		if v.l_start_x[i] >= 0.0 {
			ctx.draw_line(v.l_start_x[i], v.l_start_y[i], v.l_end_x[i], v.l_end_y[i],
				gg.black)
		}
	}
	if is_none(p_i) && (!is_none(l_i) || is_a_link_selected(selected_variant, selected_i))
		&& !is_a_block_selected(selected_variant, selected_i) {
		if selected_i != -1 {
			ctx.draw_line(v.l_start_x[selected_i], v.l_start_y[selected_i], v.l_end_x[selected_i],
				v.l_end_y[selected_i], gg.red)
		} else {
			ctx.draw_line(v.l_start_x[l_i], v.l_start_y[l_i], v.l_end_x[l_i], v.l_end_y[l_i],
				gg.red)
		}
	}
}
