module Check
extend analysis::typepal::TypePal;



import AST;
import Parser;
import Implode;
import ParseTree;
import Syntax;


data IdRole
  = variableId()
  | objectId()
  | fieldId()
  | methodId()
  | typeParamId()
  ;


//Definimos los tipos ya que Typepal no sabe cuales son los tipos de mi lenguaje
data AType
  = intType()
  | boolType()
  | strType()
  | charType()
  | objectType(str nombre, list[AType] args)  
  | tupleType(list[AType] elems)               
  | typeParam(str nombre)                      
  ;

//Y una funcion que convierte un Tipo de nuestro AST a un Atype para TypePal
//Basicamente, AType es como el idioma en el que TypePal va a razonar
//Como un dominio de semantica detacional

AType aTipo(tipoInteger()) = intType();
AType aTipo(tipoBoolean()) = boolType();
AType aTipo(tipoString())  = strType();
AType aTipo(tipoChar())    = charType();
AType aTipo(tipoNombre(str n)) = objectType(n, []);
AType aTipo(tipoGenerico(str n, list[Tipo] as)) = objectType(n, [ aTipo(a) | a <- as ]);
AType aTipo(tipoTupla(Tipo p, list[Tipo] resto)) = tupleType([aTipo(p)] + [ aTipo(r) | r <- resto ]);



//Typepal funciona con dos verbos: define y use. 
//Una sirve para declarar y el otro para usar ese nombre declarado. 

//Cuando use no encuentra su define, hay error. 

//Ahora, definimos lo explicado anteriormente: 

//Definimos objeto:

void collect(DefinicionObjeto obj, Collector c) {
  if (objeto(str n, list[DefinicionGenerico] gs, list[ConstructorParametros] cs, list[Herencia] hs) := obj) {
    c.define(n, objectId(), obj, defType(objectType(n, [])));
    c.enterScope(obj);
    collect(gs, c);
    collect(cs, c);
    collect(hs, c);
    c.leaveScope(obj);
  }
}

//Definimos Herencia
void collect(Herencia h, Collector c) {
  if (herencia(Tipo padre) := h) {
    usarTipo(padre, c);
  }
}

//Definimos Generico
void collect(generico(list[ParametroGenerico] ps), Collector c) { collect(ps, c); }
void collect(pg:parametroGenerico(_, str nombre), Collector c) {
  c.define(nombre, typeParamId(), pg, defType(typeParam(nombre)));
}


//Constructor
void collect(constructor(list[ParametroConstructor] ps), Collector c) { collect(ps, c); }
void collect(p:parametro(str nombre, Tipo t), Collector c) {
  usarTipo(t, c);
  c.define(nombre, fieldId(), p, defType(aTipo(t)));
}

//Metodo

void collect(m:metodo(str obj, str nombre, Parametros ps, Tipo retorno, list[Bloque] cuerpo), Collector c) {
  c.define(nombre, methodId(), m, defType(aTipo(retorno)));
  usarTipo(retorno, c);
  c.enterScope(m);
    collect(ps, c);
    collect(cuerpo, c);
  c.leaveScope(m);
}
void collect(parametros(list[Parametro] ps), Collector c) { collect(ps, c); }
void collect(p:parametroMetodo(str nombre, Tipo t), Collector c) {
  usarTipo(t, c);
  c.define(nombre, variableId(), p, defType(aTipo(t)));
}

//Variable
void collect(d:declaracion(_, str nombre, _, Expresion valor), Collector c) {
  c.define(nombre, variableId(), d, defType(valor));
  collect(valor, c);
}

void collect(ElementoBase e, Collector c) {
  if (variable(str nombre) := e) {
    c.use(e, {variableId(), fieldId()});
  }
}

//Auxiliar
void usarTipo(tipoNombre(str n), Collector c) = c.use([Id] n, {objectId(), typeParamId()});
void usarTipo(tipoGenerico(str n, list[Tipo] as), Collector c) {
  c.use([Id] n, {objectId()});
  for (a <- as) usarTipo(a, c);
}
default void usarTipo(Tipo _, Collector c) { }