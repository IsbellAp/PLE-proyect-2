module Plugin

import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Syntax;
import Generador;

// OJO: el nombre del proyecto en |project://...| debe ser el de SU carpeta
// del proyecto Rascal (en minusculas, como pide el tutorial).
PathConfig pcfg = getProjectPathConfig(|project://objectilang|);

// Nombre del lenguaje, extension de archivo, modulo y funcion con los servicios.
Language objectilangLang = language(pcfg, "Objectilang", {"ol"}, "Plugin", "contribs");

// Comando del lens (tutorial, Listing 7). Guarda la ubicación del archivo .ol.
data Command = generarJava(loc archivo);

set[LanguageService] contribs() = {
  parsing(parser(#start[Programa], allowRecovery=true)),
  // Listing 7: "lenses" y "executor" se llaman codeLens y execution en esta versión de rascal-lsp.
  codeLens(lrel[loc src, Command lens] (Tree p) {
    return [<p.src, generarJava(p.src.top, title="Generar Java y ejecutar")>];
  }),
  execution(exec)
};

// Genera el .java en instance/output, lo ejecuta, muestra la salida en la consola y abre el archivo.
value exec(generarJava(loc archivo)) {
  ejecutar(archivo);
  edit(carpetaSalida + "<nombreClase(archivo)>.java");
  return ("result": true);
}

void main() {
  registerLanguage(objectilangLang);
}
