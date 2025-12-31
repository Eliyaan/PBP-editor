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
	// TODO: imports, main code, run fns

	// fn struct
	for i, name in g.b_name {
		output += 'struct ' + name.camel_case() + ' {\n'
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
		output += '}\n'
	}
}
