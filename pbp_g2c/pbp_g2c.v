module pbp_g2c

// graph to code

const letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p']

interface Graph {
	// blocks
	b_inps [][]int  // index of the ports
	b_outs [][]int  // index of the ports
	b_name []string // name of the block // fn names
	// ports
	p_input []bool   // is input or output
	p_name  []string // type names
	p_block []int    // index of block
	p_link  [][]int  // index of link
	// links
	l_inp []int // index of the input port
	l_out []int
}

pub fn generate_code(g Graph) {
	mut output := ''
	// TODO: imports, main code

	for i, name in g.b_name {
		// fn struct
		name_camel_case := name.camel_case()
		output += 'struct ' + name_camel_case + ' {\n'
		output += '\tf fn ('
		for j, inp in g.b_inps[i] {
			output += letters[j] + ' ' + inp
			if j != g.b_inps[i].len - 1 {
				output += ','
			}
		}
		output += ') '
		if g.b_outs.len > 1 {
			output += '('
		}
		for j, out in g.b_outs[i] {
			output += ' ' + out
			if j != g.b_outs[i].len - 1 {
				output += ','
			}
		}
		if g.b_outs.len > 1 {
			output += ')'
		}
		output += ' = ' + name + '\n'

		output += 'mut:\n'
		output += '\t ready &atom.AtomicVal[bool] = atom.new_atomic(true)'

		for j, inp in g.b_inps[i] {
			output += '\t${letters[j]}_in &pbp.AtomicQueue[${inp}]\n'
		}
		for j, out in g.b_outs[i] {
			output += '\t${letters[j]}_out pbp.FanOut[${out}]\n'
		}
		output += '}\n\n'

		// run fn	
		output += 'fn (mut a ${name_camel_case}) run() {\n'
		output += '\tif '
		for j, inp in g.b_inps[i] {
			output += '!a.${letters[j]}_in.is_empty() '
			if j != g.b_inps[i].len - 1 {
				output += '&& '
			}
		}
		output += '{\n'
		// pop all the inputs from the queues
		for j, inp in g.b_inps[i] {
			l := letters[j]
			output += '\t\t${l}_in := a.${l}_in.pop() or { panic(@LOCATION) }\n'
		}
		// get all the outputs
		output += '\t\t'
		for j, out in g.b_outs[i] {
			l := letters[j]
			output += l + '_out, '
		}
		if g.b_outs[i].len >= 1 {
			output += ' := '
		}
		output += 'a.${name}('
		for j, inp in g.b_inps[i] {
			output += letters[i] + '_in'
			if j != g.b_inps[i].len - 1 {
				output += ', '
			}
		}
		output += ')\t'
		output += '\t}\n'
		output += '}\n\n'
	}
}
