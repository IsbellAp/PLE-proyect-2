// Error de ejecucion: metodo declarado sin cuerpo y llamado sin override.
// Salida esperada: mensaje claro "el metodo transform no tiene cuerpo".
object Transformer
Transformer.transform = method(n: Integer): Integer

method main {
  val t = new Transformer
  println(t.transform(1))
}
