module Parser

import ParseTree;
import Syntax;

start[Programa] parsePrograma(str texto, loc origen) = parse(#start[Programa], texto, origen);
start[Programa] parsePrograma(loc archivo) = parse(#start[Programa], archivo);
