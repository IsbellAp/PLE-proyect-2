module Syntax

// ===== Espacios y comentarios ===== (No entiendo casi esto, pero ok)
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

//Inicio del programa

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

//Para la expresion lo que hacemos es esta vez usar una funcion de rascal que nos permite poner "prioridad"
//Esta preioridad si va como de lo mas basico a lo mas completo, por lo que esta vez empezamos desde primario, hasta el que era el tope en nuestro original. 


//Hecha con ayuda de IA pq fue la mas complicada y no la entendpi casi. 
syntax Expresion
  = base: Primario
  > negacion: "neg" Expresion | negativo: "-" Expresion
  > right potencia: Expresion "**" Expresion
  > left ( mult: Expresion "*" Expresion | div: Expresion "/" Expresion | modulo: Expresion "%" Expresion )
  > left ( suma: Expresion "+" Expresion | resta: Expresion "-" Expresion )
  > non-assoc ( menor: Expresion "\<" Expresion | mayor: Expresion "\>" Expresion
              | menorIgual: Expresion "\<=" Expresion | mayorIgual: Expresion "\>=" Expresion
              | distinto: Expresion "\<\>" Expresion | igual: Expresion "=" Expresion
              | pertenece: Expresion "in" Expresion )
  > left conjuncion: Expresion "and" Expresion
  > left disyuncion: Expresion "or" Expresion
  > left ( flecha: Expresion "-\>" Expresion | flechaDoble: Expresion "=\>" Expresion )
  ;


//Aquí ya definimos como lo ultimo que es primero, las instancias y los literales


syntax Primario = primario: ElementoBase Sufijo*;

//Igual que con tipo:D
syntax ElementoBase
  = variable: Id
  | llamada: Id Argumentos
  | literal: Literal
  | instancia: NuevaInstancia
  | tupla: Tupla
  | agrupacion: "(" Expresion ")"
  ;

syntax Sufijo = acceso: "." Id | llamadaMetodo: "." Id Argumentos;

syntax Argumentos = argumentos: "(" {Expresion ","}* ")";

syntax Tupla = tuplaExp: "(" Expresion "," {Expresion ","}+ ")";

syntax NuevaInstancia = nueva: "new" Tipo Argumentos? CuerpoInstancia?;

syntax CuerpoInstancia = cuerpo: "{" OverrideMetodo+ "}";

syntax OverrideMetodo = sobrescribir: "override" Id "(" Parametros ")" ":" Tipo "=" Bloque;

syntax Literal = litEntero: Entero | litBooleano: LiteralBooleano | litString: LiteralString ;

syntax LiteralBooleano = verdadero: "true" | falso: "false";




//Definciones basicas (hice primero esto)

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



//Esta es la ultima parte, que es complicada, porque la idea es que no se pierdan los espacios entre strings
//Como no entendi bien como hacerla, tampoco entendí muy bien como quedó
// Ni porque funciona xd

lexical LiteralString = cadena: "\"" ParteString* "\""; 
// Si se que el lexical es para cuidar los espacios

syntax ParteString
  = texto: TextoString
  | interpVariable: "$" Id
  | interpExpresion: "${" Expresion "}";

lexical TextoString = CaracterString+ !>> ![\"$\\\n] !>> [\\];

lexical CaracterString = ![\"$\\\n] | "\\" [\"$\\n];



