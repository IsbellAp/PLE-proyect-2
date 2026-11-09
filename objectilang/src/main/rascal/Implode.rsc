module Implode

import ParseTree;
import IO;
import Parser;
import AST;
import Exception;
import Cadenas;
import String;


Programa implodePrograma(Tree arbol) = convertir(implode(#Programa, arbol));

// Recorre el AST: convierte los strings en partes y quita comillas y escapes de los Char.
&T convertir(&T ast) = visit(ast) {
  case litString(str crudo) => litString([ aParte(p) | p <- partesDe(crudo) ])
  case litChar(str crudo)   => litChar(desescapar(substring(crudo, 1, size(crudo) - 1)))
};

ParteString aParte(<"texto", str c, _>)     = texto(c);
ParteString aParte(<"variable", str c, _>)  = interpVariable(c);
ParteString aParte(<"expresion", _, Tree e>) = interpExpresion(convertir(implode(#Expresion, e)));
