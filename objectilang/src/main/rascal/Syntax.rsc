module Syntax

// ===== Espacios y comentarios =====
layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* $
  ;


lexical Id = ([a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;


lexical Entero = [0-9]+ !>> [0-9];


keyword Reservada
  = "object" | "extends" | "method" | "val" | "var" | "new"
  | "override" | "if" | "then" | "else" | "for" | "in"
  | "String" | "Integer" | "Boolean" | "true" | "false"
  | "and" | "or" | "neg"
  ;


start syntax DefinicionObjeto = objeto: "object" Id DefinicionGenerico? ConstructorParametros? ("extends" Id)?;


syntax DefinicionGenerico = generico: "[" ("+" | "-")? Id ("," ("+"|"-")? Id)* "]";

syntax ConstructorParametros = constructor:"(" ParametroConstructor ("," ParametroConstructor)* ")";

syntax ParametroConstructor = parametro: "val" Id ":" Tipo;

//No funcionó Tipo tradujendolo como se tradujo originalmente, entonces toco poner esta funcion de rascal

syntax Tipo
  = tipoString: "String"
  | tipoInteger: "Integer"
  | tipoBoolean: "Boolean"
  | tipoNombre: Id nombre
  | tipoGenerico: Id nombre "[" {Tipo ","}+ argumentos "]";


syntax Parametros = parametros: (Id ":" Tipo ("," Id ":" Tipo )*)?;

