module Plugin

import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Syntax;
import Generador;
import Check;
import Message;

// OJO: el nombre del proyecto en |project://...| debe ser el de SU carpeta
// del proyecto Rascal (en minusculas, como pide el tutorial).
PathConfig pcfg = getProjectPathConfig(|project://objectilang|);

// Nombre del lenguaje, extension de archivo, modulo y funcion con los servicios.
Language objectilangLang = language(pcfg, "Objectilang", {"ol"}, "Plugin", "contribs");

// Comando del lens (tutorial, Listing 7). Guarda la ubicación del archivo .ol.
data Command = generarJava(loc archivo);

set[LanguageService] contribs() = {
  parsing(parser(#start[Programa], allowRecovery=true)),
  // Listing 18: el chequeador de TypePal muestra los errores de tipos y de existencia en el editor,
  // y Ctrl+Click lleva de un uso a su definición. (summarizer se llama analysis en esta versión.)
  analysis(resumen),
  // Listing 7: "lenses" y "executor" se llaman codeLens y execution en esta versión de rascal-lsp.
  codeLens(lrel[loc src, Command lens] (Tree p) {
    return [<p.src, generarJava(p.src.top, title="Generar Java y ejecutar")>];
  }),
  execution(exec)
};

// Como tdslSummarizer del Listing 18: arma el TModel y devuelve sus mensajes y relaciones uso-definición.
// Si el archivo tiene errores de sintaxis (el parser se recupera), no se revisan los tipos.
Summary resumen(loc l, Tree input) {
  if (start[Programa] pt := input) {
    try {
      tm = modeloDeArbol(pt);
      return summary(l, messages = {<m.at, m> | m <- getMessages(tm), !(m is info)}, definitions = getUseDef(tm));
    } catch _: return summary(l);
  }
  return summary(l);
}

// Genera el .java en instance/output, lo ejecuta y abre el .java y la salida del programa.
value exec(generarJava(loc archivo)) {
  ejecutar(archivo);
  edit(rutaJava(archivo));
  edit(rutaSalida(archivo));
  return ("result": true);
}

void main() {
  registerLanguage(objectilangLang);
}
