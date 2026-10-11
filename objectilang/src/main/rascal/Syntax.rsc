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


start syntax Programa = programa : Definicion* Metodo;

syntax Definicion = defObjeto: DefinicionObjeto | defMetodo: DefinicionObjetoMetodo;

syntax Metodo = metodoMain: "method" "main" Bloque;

syntax DefinicionObjetoMetodo = metodo: Id "." Id "=" "method" "(" Parametros ")" ":" Tipo Bloque;


//Bloque cambió con respecto al original de la primera entrega, ya que así, omitimos ambiguedad.
syntax Bloque = bloque: "{" {Sentencia ";"}* "}";

//Sentencia cambió al igual que Tipo, ya que pues al escribirlo en rascal lo aceptaba mejor de esta manera

syntax Sentencia
  = sentDeclaracion: DeclaracionVariable
  | sentExpresion: Expresion
  | sentBloque: Bloque
  | sentIf: CondicionalIf
  | sentFor: CicloFor;

// A partir de acá somos un poco más especificos, ya que si dejabamos la traduccion original el AST no reconocía por completo la traduccion. 

syntax DeclaracionVariable = declaracion: Modificador Id AnotacionTipo? "=" Expresion;

syntax Modificador = inmutable: "val" | mutable: "var";

syntax AnotacionTipo = anotacion: ":" Tipo;

syntax CondicionalIf
  = ifSinElse: "if" Expresion "then" Sentencia () !>> "else"
  | ifConElse: "if" Expresion "then" Sentencia "else" Sentencia
  ;

syntax CicloFor = ciclo: "for" "(" VariableIteracion "\<-" Expresion ")" Sentencia;

syntax VariableIteracion = varSimple: Id | varTupla: "(" Id "," {Id ","}+ ")";

//TEMPORAL
syntax Expresion = temporalId: Id | temporalNum: Entero;


syntax DefinicionObjeto = objeto: "object" Id DefinicionGenerico? ConstructorParametros? Herencia?;

syntax Herencia = herencia: "extends" Id;

syntax DefinicionGenerico = generico: "[" {ParametroGenerico ","}+ "]";

syntax ParametroGenerico = parametroGenerico: Varianza? Id;

syntax Varianza = covariante: "+" | contravariante: "-";

syntax ConstructorParametros = constructor: "(" {ParametroConstructor ","}+ ")";

syntax ParametroConstructor = parametro: "val" Id ":" Tipo;

//No funcionó Tipo tradujendolo como se tradujo originalmente, entonces toco poner esta funcion de rascal

syntax Tipo
  = tipoString: "String"
  | tipoInteger: "Integer"
  | tipoBoolean: "Boolean"
  | tipoNombre: Id nombre
  | tipoGenerico: Id nombre "[" {Tipo ","}+ argumentos "]";


syntax Parametros = parametros: {Parametro ","}*;

syntax Parametro = parametroMetodo: Id ":" Tipo;


