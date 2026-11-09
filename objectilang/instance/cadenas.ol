// Strings con interpolacion: el AST debe separar texto, $nombre y ${expresion}.
// Incluye el ejemplo de la retroalimentacion del Proyecto 2.
method main {
  val nombre = "Ana"
  val edad = 20
  println("Hola ${nombre}, tienes ${edad + 1} años")
  println("Hola $nombre")
  println("Anidado: ${ "edad $edad" }")
  println("Escapes: \$5, \" y \\")
  println("")
}
