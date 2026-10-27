module Plugin

import ParseTree;
import util::Reflective;
import util::IDEServices;
import util::LanguageServer;
import Syntax;

// OJO: el nombre del proyecto en |project://...| debe ser el de SU carpeta
// del proyecto Rascal (en minusculas, como pide el tutorial).
PathConfig pcfg = getProjectPathConfig(|project://objectilang|);

// Nombre del lenguaje, extension de archivo, modulo y funcion con los servicios.
Language objectilangLang = language(pcfg, "Objectilang", {"ol"}, "Plugin", "contribs");

set[LanguageService] contribs() = {
  parsing(parser(#start[Programa], allowRecovery=true))
};

void main() {
  registerLanguage(objectilangLang);
}
